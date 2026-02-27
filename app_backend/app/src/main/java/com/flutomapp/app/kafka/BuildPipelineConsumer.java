package com.flutomapp.app.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flutomapp.app.config.KafkaTopicConfig;
import com.flutomapp.app.service.BuildService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class BuildPipelineConsumer {

    private static final Logger log = LoggerFactory.getLogger(BuildPipelineConsumer.class);
    private final BuildService buildService;
    private final ObjectMapper objectMapper;

    public BuildPipelineConsumer(BuildService buildService, ObjectMapper objectMapper) {
        this.buildService = buildService;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(topics = KafkaTopicConfig.TOPIC_BUILD_INITIATED, groupId = "build-pipeline-group")
    public void onBuildInitiated(String message) {
        try {
            BuildPipelineEvent event = objectMapper.readValue(message, BuildPipelineEvent.class);
            log.info("Received BUILD_INITIATED event for buildId: {}", event.getBuildId());
            buildService.handleBuildInitiated(event);
        } catch (Exception e) {
            log.error("Failed to process BUILD_INITIATED event", e);
        }
    }

    @KafkaListener(topics = KafkaTopicConfig.TOPIC_BUILD_SCREEN_GENERATE, groupId = "build-pipeline-group")
    public void onScreenGenerate(String message) {
        try {
            BuildPipelineEvent event = objectMapper.readValue(message, BuildPipelineEvent.class);
            log.info("Received SCREEN_GENERATE event for buildId: {}, screenIndex: {}",
                    event.getBuildId(), event.getCurrentScreenIndex());
            buildService.handleScreenGenerate(event);
        } catch (Exception e) {
            log.error("Failed to process SCREEN_GENERATE event", e);
        }
    }

    @KafkaListener(topics = KafkaTopicConfig.TOPIC_BUILD_MAIN_GENERATE, groupId = "build-pipeline-group")
    public void onMainGenerate(String message) {
        try {
            BuildPipelineEvent event = objectMapper.readValue(message, BuildPipelineEvent.class);
            log.info("Received MAIN_GENERATE event for buildId: {}", event.getBuildId());
            buildService.handleMainGenerate(event);
        } catch (Exception e) {
            log.error("Failed to process MAIN_GENERATE event", e);
        }
    }

    @KafkaListener(topics = KafkaTopicConfig.TOPIC_BUILD_FLUTTER_COMPILE, groupId = "build-pipeline-group")
    public void onFlutterCompile(String message) {
        try {
            BuildPipelineEvent event = objectMapper.readValue(message, BuildPipelineEvent.class);
            log.info("Received FLUTTER_COMPILE event for buildId: {}", event.getBuildId());
            buildService.handleFlutterCompile(event);
        } catch (Exception e) {
            log.error("Failed to process FLUTTER_COMPILE event", e);
        }
    }

    @KafkaListener(topics = KafkaTopicConfig.TOPIC_BUILD_FINALIZE, groupId = "build-pipeline-group")
    public void onBuildFinalize(String message) {
        try {
            BuildPipelineEvent event = objectMapper.readValue(message, BuildPipelineEvent.class);
            log.info("Received FINALIZE event for buildId: {}", event.getBuildId());
            buildService.handleBuildFinalize(event);
        } catch (Exception e) {
            log.error("Failed to process FINALIZE event", e);
        }
    }
}
