package com.flutomapp.app.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    // Existing project creation topics
    public static final String TOPIC_ENV_CONFIG = "project.step.env-config";
    public static final String TOPIC_PERMISSIONS_CONFIG = "project.step.permissions-config";
    public static final String TOPIC_APPICON_CONFIG = "project.step.appicon-config";
    public static final String TOPIC_FIREBASE_CONFIG = "project.step.firebase-config";
    public static final String TOPIC_FINALIZE = "project.step.finalize";

    // Build pipeline topics
    public static final String TOPIC_BUILD_INITIATED = "build.step.initiated";
    public static final String TOPIC_BUILD_SCREEN_GENERATE = "build.step.screen-generate";
    public static final String TOPIC_BUILD_SCREEN_BACKPATCH = "build.step.screen-backpatch";
    public static final String TOPIC_BUILD_MAIN_GENERATE = "build.step.main-generate";
    public static final String TOPIC_BUILD_FLUTTER_COMPILE = "build.step.flutter-compile";
    public static final String TOPIC_BUILD_FINALIZE = "build.step.finalize";

    @Bean
    public NewTopic envConfigTopic() {
        return TopicBuilder.name(TOPIC_ENV_CONFIG).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic permissionsConfigTopic() {
        return TopicBuilder.name(TOPIC_PERMISSIONS_CONFIG).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic appIconConfigTopic() {
        return TopicBuilder.name(TOPIC_APPICON_CONFIG).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic firebaseConfigTopic() {
        return TopicBuilder.name(TOPIC_FIREBASE_CONFIG).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic finalizeTopic() {
        return TopicBuilder.name(TOPIC_FINALIZE).partitions(3).replicas(1).build();
    }

    // Build pipeline topic beans
    @Bean
    public NewTopic buildInitiatedTopic() {
        return TopicBuilder.name(TOPIC_BUILD_INITIATED).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic buildScreenGenerateTopic() {
        return TopicBuilder.name(TOPIC_BUILD_SCREEN_GENERATE).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic buildScreenBackpatchTopic() {
        return TopicBuilder.name(TOPIC_BUILD_SCREEN_BACKPATCH).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic buildMainGenerateTopic() {
        return TopicBuilder.name(TOPIC_BUILD_MAIN_GENERATE).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic buildFlutterCompileTopic() {
        return TopicBuilder.name(TOPIC_BUILD_FLUTTER_COMPILE).partitions(3).replicas(1).build();
    }

    @Bean
    public NewTopic buildFinalizeTopic() {
        return TopicBuilder.name(TOPIC_BUILD_FINALIZE).partitions(3).replicas(1).build();
    }
}
