package com.flutomapp.app.config;


import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    public static final String TOPIC_ENV_CONFIG = "project.step.env-config";
    public static final String TOPIC_PERMISSIONS_CONFIG = "project.step.permissions-config";
    public static final String TOPIC_APPICON_CONFIG = "project.step.appicon-config";
    public static final String TOPIC_FIREBASE_CONFIG = "project.step.firebase-config";
    public static final String TOPIC_FINALIZE = "project.step.finalize";

    @Bean
    public NewTopic envConfigTopic() {
        return TopicBuilder.name(TOPIC_ENV_CONFIG)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic permissionsConfigTopic() {
        return TopicBuilder.name(TOPIC_PERMISSIONS_CONFIG)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic appIconConfigTopic() {
        return TopicBuilder.name(TOPIC_APPICON_CONFIG)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic firebaseConfigTopic() {
        return TopicBuilder.name(TOPIC_FIREBASE_CONFIG)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic finalizeTopic() {
        return TopicBuilder.name(TOPIC_FINALIZE)
                .partitions(3)
                .replicas(1)
                .build();
    }
}
