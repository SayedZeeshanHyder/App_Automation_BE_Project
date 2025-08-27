package com.flutomapp.app.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
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

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@Service
public class GeminiAIService {

    private static final Logger logger = LoggerFactory.getLogger(GeminiAIService.class);

    @Value("${gemini.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private static final Pattern JSON_CODE_BLOCK_PATTERN = Pattern.compile("```json\\s*|```\\s*", Pattern.MULTILINE | Pattern.DOTALL);
    private static final Pattern MARKDOWN_CODE_PATTERN = Pattern.compile("```[a-zA-Z]*\\s*|```\\s*", Pattern.MULTILINE | Pattern.DOTALL);
    private static final Pattern LEADING_TRAILING_QUOTES = Pattern.compile("^[\"'`]+|[\"'`]+$");

    public GeminiAIService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public String generateContent(String prompt) {
        if (prompt == null || prompt.trim().isEmpty()) {
            logger.warn("Empty or null prompt provided");
            return "Error: Prompt cannot be empty";
        }

        if (apiKey == null || apiKey.trim().isEmpty()) {
            logger.error("Gemini API key is not configured");
            return "Error: API key not configured";
        }

        try {
            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + apiKey;
            Map<String, Object> requestBody = createRequestBody(prompt.trim());
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("User-Agent", "SpringBoot-GeminiClient/1.0");

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            ResponseEntity<String> response = makeApiCallWithRetry(url, entity, 3);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return parseAndCleanResponse(response.getBody());
            } else {
                logger.error("Unexpected response status: {}", response.getStatusCode());
                return "Error: Unexpected response from Gemini API";
            }

        } catch (Exception e) {
            logger.error("Error calling Gemini API: {}", e.getMessage(), e);
            return "Error: Failed to generate content - " + e.getMessage();
        }
    }

    private Map<String, Object> createRequestBody(String prompt) {
        Map<String, Object> requestBody = new HashMap<>();

        Map<String, Object> content = new HashMap<>();

        Map<String, String> part = new HashMap<>();
        part.put("text", prompt);

        content.put("parts", List.of(part));
        requestBody.put("contents", List.of(content));

        Map<String, Object> generationConfig = new HashMap<>();
        generationConfig.put("temperature", 0.7);
        generationConfig.put("topK", 40);
        generationConfig.put("topP", 0.95);
        generationConfig.put("maxOutputTokens", 8192);
        requestBody.put("generationConfig", generationConfig);

        Map<String, String> safetySettings = Map.of(
                "category", "HARM_CATEGORY_HARASSMENT",
                "threshold", "BLOCK_MEDIUM_AND_ABOVE"
        );
        requestBody.put("safetySettings", List.of(safetySettings));

        return requestBody;
    }

    private ResponseEntity<String> makeApiCallWithRetry(String url, HttpEntity<Map<String, Object>> entity, int maxRetries) {
        int attempts = 0;
        Exception lastException = null;

        while (attempts < maxRetries) {
            try {
                attempts++;
                logger.debug("API call attempt {} of {}", attempts, maxRetries);

                ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
                return response;

            } catch (HttpClientErrorException e) {
                lastException = e;
                if (e.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS && attempts < maxRetries) {
                    logger.warn("Rate limited, retrying in {} seconds", attempts * 2);
                    sleep(attempts * 2000);
                    continue;
                } else {
                    logger.error("Client error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
                    break;
                }
            } catch (HttpServerErrorException e) {
                lastException = e;
                if (attempts < maxRetries) {
                    logger.warn("Server error, retrying in {} seconds", attempts * 2);
                    sleep(attempts * 2000);
                    continue;
                } else {
                    logger.error("Server error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
                    break;
                }
            } catch (ResourceAccessException e) {
                lastException = e;
                if (attempts < maxRetries) {
                    logger.warn("Connection error, retrying in {} seconds", attempts * 2);
                    sleep(attempts * 2000);
                    continue;
                } else {
                    logger.error("Connection error: {}", e.getMessage());
                    break;
                }
            }
        }

        throw new RuntimeException("API call failed after " + maxRetries + " attempts", lastException);
    }

    private String parseAndCleanResponse(String responseBody) {
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
                        String rawText = textNode.asText();
                        return cleanResponseContent(rawText);
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

    private String cleanResponseContent(String content) {
        if (content == null || content.trim().isEmpty()) {
            return "Error: Empty response from Gemini API";
        }

        String cleaned = content;
        cleaned = JSON_CODE_BLOCK_PATTERN.matcher(cleaned).replaceAll("");
        cleaned = MARKDOWN_CODE_PATTERN.matcher(cleaned).replaceAll("");

        cleaned = LEADING_TRAILING_QUOTES.matcher(cleaned).replaceAll("");

        cleaned = cleaned.trim();

        cleaned = cleaned.replaceAll("\\n{3,}", "\n\n");

        cleaned = cleaned.replaceAll("\\*\\*(.*?)\\*\\*", "$1"); // Bold
        cleaned = cleaned.replaceAll("\\*(.*?)\\*", "$1"); // Italic
        cleaned = cleaned.replaceAll("`([^`]+)`", "$1"); // Inline code

        return cleaned.trim();
    }

    private void sleep(long milliseconds) {
        try {
            Thread.sleep(milliseconds);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.warn("Sleep interrupted");
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GeminiResponse {
        @JsonProperty("candidates")
        private List<Candidate> candidates;

        @JsonProperty("error")
        private ErrorInfo error;

        public List<Candidate> getCandidates() { return candidates; }
        public void setCandidates(List<Candidate> candidates) { this.candidates = candidates; }
        public ErrorInfo getError() { return error; }
        public void setError(ErrorInfo error) { this.error = error; }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Candidate {
        @JsonProperty("content")
        private Content content;

        public Content getContent() { return content; }
        public void setContent(Content content) { this.content = content; }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Content {
        @JsonProperty("parts")
        private List<Part> parts;

        public List<Part> getParts() { return parts; }
        public void setParts(List<Part> parts) { this.parts = parts; }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Part {
        @JsonProperty("text")
        private String text;

        public String getText() { return text; }
        public void setText(String text) { this.text = text; }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ErrorInfo {
        @JsonProperty("message")
        private String message;

        @JsonProperty("code")
        private Integer code;

        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public Integer getCode() { return code; }
        public void setCode(Integer code) { this.code = code; }
    }
}