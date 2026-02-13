package com.flutomapp.app.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.flutomapp.app.config.KafkaTopicConfig;
import com.flutomapp.app.model.ProjectEntity;
import com.flutomapp.app.repository.ProjectRepository;
import com.flutomapp.app.service.ProjectCreationService;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;

@Component
public class ProjectPipelineConsumer {

    private final ProjectCreationService projectCreationService;
    private final KafkaProducerService kafkaProducerService;
    private final ProjectRepository projectRepository;
    private final ObjectMapper objectMapper;

    public ProjectPipelineConsumer(ProjectCreationService projectCreationService,
                                   KafkaProducerService kafkaProducerService,
                                   ProjectRepository projectRepository,
                                   ObjectMapper objectMapper) {
        this.projectCreationService = projectCreationService;
        this.kafkaProducerService = kafkaProducerService;
        this.projectRepository = projectRepository;
        this.objectMapper = objectMapper;
    }

    // ─── STEP 1: ENV CONFIG ───
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_ENV_CONFIG, groupId = "flutomapp-group")
    public void handleEnvConfig(String message) {
        try {
            ProjectCreationEventSample event = objectMapper.readValue(message, ProjectCreationEventSample.class);
            updateProjectStatus(event.getUniqueId(), "CONFIGURING_ENV");

            Path flutterProjectDir = resolveProjectDir(event);

            if (event.getEnvKeys() != null && !event.getEnvKeys().isEmpty()) {
                try {
                    Map<String, String> envMap = buildEnvMap(event.getEnvKeys(), event.getEnvValues());
                    if (envMap != null && !envMap.isEmpty()) {
                        projectCreationService.configureDotEnv(envMap, flutterProjectDir);
                        event.setEnvConfigured(true);
                    }
                } catch (Exception e) {
                    System.err.println("[KAFKA] ENV config failed for " + event.getUniqueId() + ": " + e.getMessage());
                }
            }

            kafkaProducerService.send(KafkaTopicConfig.TOPIC_PERMISSIONS_CONFIG, event);
        } catch (Exception e) {
            System.err.println("[KAFKA] Error in ENV step: " + e.getMessage());
        }
    }

    // ─── STEP 2: ANDROID PERMISSIONS ───
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_PERMISSIONS_CONFIG, groupId = "flutomapp-group")
    public void handlePermissionsConfig(String message) {
        try {
            ProjectCreationEventSample event = objectMapper.readValue(message, ProjectCreationEventSample.class);
            updateProjectStatus(event.getUniqueId(), "CONFIGURING_PERMISSIONS");

            Path flutterProjectDir = resolveProjectDir(event);

            if (event.getAndroidPermissions() != null && !event.getAndroidPermissions().isEmpty()) {
                try {
                    projectCreationService.configureAndroidPermissions(event.getAndroidPermissions(), flutterProjectDir);
                    event.setPermissionsConfigured(true);
                } catch (Exception e) {
                    System.err.println("[KAFKA] Permissions config failed for " + event.getUniqueId() + ": " + e.getMessage());
                }
            }

            kafkaProducerService.send(KafkaTopicConfig.TOPIC_APPICON_CONFIG, event);
        } catch (Exception e) {
            System.err.println("[KAFKA] Error in PERMISSIONS step: " + e.getMessage());
        }
    }

    // ─── STEP 3: APP ICON ───
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_APPICON_CONFIG, groupId = "flutomapp-group")
    public void handleAppIconConfig(String message) {
        try {
            ProjectCreationEventSample event = objectMapper.readValue(message, ProjectCreationEventSample.class);
            updateProjectStatus(event.getUniqueId(), "CONFIGURING_APP_ICON");

            Path flutterProjectDir = resolveProjectDir(event);

            if (event.getAppIconBase64() != null && !event.getAppIconBase64().isEmpty()) {
                try {
                    projectCreationService.configureAppIconFromBase64(
                            event.getAppIconBase64(),
                            event.getAppIconOriginalFilename(),
                            flutterProjectDir
                    );
                    event.setAppIconConfigured(true);
                } catch (Exception e) {
                    System.err.println("[KAFKA] App icon config failed for " + event.getUniqueId() + ": " + e.getMessage());
                }
            }

            kafkaProducerService.send(KafkaTopicConfig.TOPIC_FIREBASE_CONFIG, event);
        } catch (Exception e) {
            System.err.println("[KAFKA] Error in APP_ICON step: " + e.getMessage());
        }
    }

    // ─── STEP 4: FIREBASE ───
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_FIREBASE_CONFIG, groupId = "flutomapp-group")
    public void handleFirebaseConfig(String message) {
        try {
            ProjectCreationEventSample event = objectMapper.readValue(message, ProjectCreationEventSample.class);
            updateProjectStatus(event.getUniqueId(), "CONFIGURING_FIREBASE");

            Path flutterProjectDir = resolveProjectDir(event);

            if (event.isRequireFirebase() && event.getGoogleServicesJsonBase64() != null
                    && !event.getGoogleServicesJsonBase64().isEmpty()) {
                try {
                    byte[] googleServicesBytes = Base64.getDecoder().decode(event.getGoogleServicesJsonBase64());
                    if (projectCreationService.checkProjectPackageMatchesGoogleServicesBytes(googleServicesBytes, flutterProjectDir)) {
                        projectCreationService.configureFirebaseFromBytes(googleServicesBytes, flutterProjectDir);
                        event.setFirebaseConfigured(true);
                    } else {
                        System.err.println("[KAFKA] Firebase skipped: package name mismatch for " + event.getUniqueId());
                    }
                } catch (Exception e) {
                    System.err.println("[KAFKA] Firebase config failed for " + event.getUniqueId() + ": " + e.getMessage());
                }
            }

            kafkaProducerService.send(KafkaTopicConfig.TOPIC_FINALIZE, event);
        } catch (Exception e) {
            System.err.println("[KAFKA] Error in FIREBASE step: " + e.getMessage());
        }
    }

    // ─── STEP 5: FINALIZE (zip + update DB) ───
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_FINALIZE, groupId = "flutomapp-group")
    public void handleFinalize(String message) {
        try {
            ProjectCreationEventSample event = objectMapper.readValue(message, ProjectCreationEventSample.class);
            updateProjectStatus(event.getUniqueId(), "FINALIZING");

            Path projectRootPath = Paths.get(projectCreationService.baseProjectsDir, event.getUniqueId());
            Path zipPath = Paths.get(projectCreationService.baseProjectsDir, event.getUniqueId() + ".zip");

            projectCreationService.zipFolder(projectRootPath, zipPath);

            Optional<ProjectEntity> optProject = projectRepository.findById(event.getUniqueId());
            if (optProject.isPresent()) {
                ProjectEntity project = optProject.get();
                project.setStatus("COMPLETED");
                project.setFirebaseConfigured(event.isFirebaseConfigured());
                project.setLastBuildLocation(zipPath.toString());
                projectRepository.save(project);
            }

            System.out.println("[KAFKA] Project " + event.getUniqueId() + " COMPLETED successfully.");
        } catch (Exception e) {
            System.err.println("[KAFKA] Error in FINALIZE step: " + e.getMessage());
            updateProjectStatus(e.getMessage(), "FAILED");
        }
    }


    private Path resolveProjectDir(ProjectCreationEventSample event) {
        return Paths.get(projectCreationService.baseProjectsDir, event.getUniqueId(), event.getProjectName());
    }

    private void updateProjectStatus(String projectId, String status) {
        projectRepository.findById(projectId).ifPresent(project -> {
            project.setStatus(status);
            projectRepository.save(project);
        });
    }

    private Map<String, String> buildEnvMap(List<String> keys, List<String> values) {
        if (keys == null || values == null || keys.size() != values.size()) return null;
        Map<String, String> map = new LinkedHashMap<>();
        for (int i = 0; i < keys.size(); i++) {
            if (keys.get(i) != null && !keys.get(i).trim().isEmpty()) {
                map.put(keys.get(i), values.get(i));
            }
        }
        return map;
    }
}
