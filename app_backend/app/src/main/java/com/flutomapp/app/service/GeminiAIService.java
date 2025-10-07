package com.flutomapp.app.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class GeminiAIService {

    private static final Logger logger = LoggerFactory.getLogger(GeminiAIService.class);

    @Value("${gemini.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public GeminiAIService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Simple content generation without conversation history
     * Used by ProjectCreationService for single-prompt operations
     */
    public String generateContent(String prompt) {
        return generateContentWithContext(prompt, null);
    }

    /**
     * Generate content with conversation history for contextual generation
     * Used by BuildService for sequential screen generation with context
     */
    public String generateContentWithContext(String prompt, List<Map<String, String>> conversationHistory) {
        if (prompt == null || prompt.trim().isEmpty()) {
            logger.warn("Empty or null prompt provided");
            return "Error: Prompt cannot be empty";
        }

        if (apiKey == null || apiKey.trim().isEmpty()) {
            logger.error("Gemini API key is not configured");
            return "Error: API key not configured";
        }

        try {
            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

            Map<String, Object> requestBody = createRequestBodyWithHistory(prompt.trim(), conversationHistory);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("x-goog-api-key", apiKey);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            ResponseEntity<String> response = makeApiCallWithRetry(url, entity, 3);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return parseResponse(response.getBody());
            } else {
                logger.error("Unexpected response status: {}", response.getStatusCode());
                return "Error: Unexpected response from Gemini API";
            }

        } catch (Exception e) {
            logger.error("Error calling Gemini API: {}", e.getMessage(), e);
            return "Error: Failed to generate content - " + e.getMessage();
        }
    }

    private Map<String, Object> createRequestBodyWithHistory(String prompt, List<Map<String, String>> conversationHistory) {
        Map<String, Object> requestBody = new HashMap<>();

        List<Map<String, Object>> contents = new ArrayList<>();

        // Add conversation history if provided
        if (conversationHistory != null && !conversationHistory.isEmpty()) {
            for (Map<String, String> message : conversationHistory) {
                Map<String, Object> content = new HashMap<>();
                content.put("role", message.get("role")); // "user" or "model"

                Map<String, String> part = new HashMap<>();
                part.put("text", message.get("text"));
                content.put("parts", List.of(part));

                contents.add(content);
            }
        }

        // Add current prompt
        Map<String, Object> currentContent = new HashMap<>();
        currentContent.put("role", "user");
        Map<String, String> part = new HashMap<>();
        part.put("text", prompt);
        currentContent.put("parts", List.of(part));
        contents.add(currentContent);

        requestBody.put("contents", contents);

        // Generation config
        Map<String, Object> generationConfig = new HashMap<>();
        generationConfig.put("temperature", 0.7);
        generationConfig.put("topK", 40);
        generationConfig.put("topP", 0.95);
        generationConfig.put("maxOutputTokens", 8192);
        requestBody.put("generationConfig", generationConfig);

        return requestBody;
    }

    private ResponseEntity<String> makeApiCallWithRetry(String url, HttpEntity<Map<String, Object>> entity, int maxRetries) {
        int attempts = 0;
        Exception lastException = null;

        while (attempts < maxRetries) {
            try {
                attempts++;
                logger.debug("API call attempt {} of {}", attempts, maxRetries);
                return restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

            } catch (HttpClientErrorException e) {
                lastException = e;
                if (e.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS && attempts < maxRetries) {
                    logger.warn("Rate limited, retrying in {} seconds", attempts * 2);
                    sleep(attempts * 2000);
                } else {
                    logger.error("Client error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
                    break;
                }
            } catch (HttpServerErrorException e) {
                lastException = e;
                if (attempts < maxRetries) {
                    logger.warn("Server error, retrying in {} seconds", attempts * 2);
                    sleep(attempts * 2000);
                } else {
                    logger.error("Server error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
                    break;
                }
            } catch (ResourceAccessException e) {
                lastException = e;
                if (attempts < maxRetries) {
                    logger.warn("Connection error, retrying in {} seconds", attempts * 2);
                    sleep(attempts * 2000);
                } else {
                    logger.error("Connection error: {}", e.getMessage());
                    break;
                }
            }
        }

        throw new RuntimeException("API call failed after " + maxRetries + " attempts", lastException);
    }

    private String parseResponse(String responseBody) {
        try {
            JsonNode rootNode = objectMapper.readTree(responseBody);
            JsonNode candidatesNode = rootNode.path("candidates");

            if (candidatesNode.isArray() && candidatesNode.size() > 0) {
                JsonNode firstCandidate = candidatesNode.get(0);
                JsonNode contentNode = firstCandidate.path("content");
                JsonNode partsNode = contentNode.path("parts");

                if (partsNode.isArray() && partsNode.size() > 0) {
                    JsonNode firstPart = partsNode.get(0);
                    JsonNode textNode = firstPart.path("text");

                    if (!textNode.isMissingNode() && !textNode.isNull()) {
                        return textNode.asText().trim();
                    }
                }
            }

            JsonNode errorNode = rootNode.path("error");
            if (!errorNode.isMissingNode()) {
                String errorMessage = errorNode.path("message").asText("Unknown error");
                logger.error("Gemini API error: {}", errorMessage);
                return "Error: " + errorMessage;
            }

            logger.warn("Could not parse response structure: {}", responseBody);
            return "Error: Unable to parse response from Gemini API";

        } catch (Exception e) {
            logger.error("Error parsing JSON response: {}", e.getMessage(), e);
            return "Error: Failed to parse response - " + e.getMessage();
        }
    }

    private void sleep(long milliseconds) {
        try {
            Thread.sleep(milliseconds);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.warn("Sleep interrupted");
        }
    }
}