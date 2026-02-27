package com.flutomapp.app.service;

import com.flutomapp.app.config.KafkaTopicConfig;
import com.flutomapp.app.dtomodel.Screen;
import com.flutomapp.app.httpmodels.BuildModels.BuildRequest;
import com.flutomapp.app.httpmodels.BuildModels.BuildStatus;
import com.flutomapp.app.kafka.BuildPipelineEvent;
import com.flutomapp.app.kafka.KafkaProducerService;
import com.flutomapp.app.model.BuildEntity;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.ProjectEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.repository.BuildRepository;
import com.flutomapp.app.repository.ProjectRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
public class BuildService {

    private static final Logger log = LoggerFactory.getLogger(BuildService.class);
    private final GeminiAIService geminiAIService;
    private final ProjectRepository projectRepository;
    private final BuildRepository buildRepository;
    private final KafkaProducerService kafkaProducerService;

    private static final String BASE_PROJECTS_FOLDER = "projects";
    private static final String FINAL_BUILDS_FOLDER = "builds";

    private final ConcurrentHashMap<String, BuildStatus> buildStatusMap = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, BuildContextManager> buildContextMap = new ConcurrentHashMap<>();

    public BuildService(GeminiAIService geminiAIService,
                        ProjectRepository projectRepository,
                        BuildRepository buildRepository,
                        KafkaProducerService kafkaProducerService) {
        this.geminiAIService = geminiAIService;
        this.projectRepository = projectRepository;
        this.buildRepository = buildRepository;
        this.kafkaProducerService = kafkaProducerService;
    }

    // ========================
    // PUBLIC API
    // ========================

    /**
     * Entry point: creates the build record and fires the first Kafka event.
     * Returns immediately with the buildId.
     */
    public String startBuildProcess(String projectId, BuildRequest buildRequest, UserEntity user) {
        String buildId = UUID.randomUUID().toString();

        ProjectEntity project = projectRepository.findById(projectId)
                .orElseThrow(() -> new RuntimeException("Project not found"));
        OrganisationEntity organisation = project.getOrganisation();

        // Create and save BuildEntity
        BuildEntity buildEntity = new BuildEntity();
        buildEntity.setBuildId(buildId);
        buildEntity.setProject(project);
        buildEntity.setOrganisation(organisation);
        buildEntity.setCreatedBy(user);
        buildEntity.setInstructions(buildRequest.getInstructions());
        buildEntity.setInitialScreenIndex(buildRequest.getInitialScreenIndex());
        buildEntity.setStatusMessage("Build initiated. Queued for processing...");
        buildEntity.setCompleted(false);
        buildEntity.setCreatedAt(LocalDateTime.now());
        buildRepository.save(buildEntity);

        // Initialize in-memory status for real-time polling
        BuildStatus status = new BuildStatus();
        status.setBuildId(buildId);
        status.setStatusMessage("Build initiated. Queued for processing...");
        buildStatusMap.put(buildId, status);

        log.info("Build {} created. Publishing INITIATED event to Kafka.", buildId);

        // Publish the first Kafka event to kick off the pipeline
        BuildPipelineEvent event = new BuildPipelineEvent(
                buildId, projectId, buildRequest.getInstructions(),
                buildRequest.getInitialScreenIndex(), "INITIATED"
        );
        kafkaProducerService.sendBuildEvent(KafkaTopicConfig.TOPIC_BUILD_INITIATED, event);

        return buildId;
    }

    // ========================
    // KAFKA PIPELINE HANDLERS
    // (Called by BuildPipelineConsumer)
    // ========================

    /**
     * Step 1: Initialize context and start generating the first screen.
     */
    public void handleBuildInitiated(BuildPipelineEvent event) {
        String buildId = event.getBuildId();
        log.info("Handling INITIATED for build {}", buildId);

        try {
            ProjectEntity project = projectRepository.findById(event.getProjectId())
                    .orElseThrow(() -> new RuntimeException("Project not found: " + event.getProjectId()));

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + event.getProjectId() + "/" + project.getProjectName();
            Path libDirectory = Paths.get(flutterProjectRootPath, "lib");
            Files.createDirectories(libDirectory);

            // Initialize the BuildContextManager
            BuildContextManager contextManager = new BuildContextManager();
            contextManager.initialize(project.getProjectName(), event.getInstructions(),
                    project.getListOfScreens().size(), project.getListOfScreens());
            buildContextMap.put(buildId, contextManager);

            addLog(buildId, "Build context initialized for " + project.getListOfScreens().size() + " screens.");
            updateBuildProgress(buildId, "Starting screen generation...");

            // Dispatch event to generate first screen (index 0)
            BuildPipelineEvent nextEvent = new BuildPipelineEvent(
                    buildId, event.getProjectId(), event.getInstructions(),
                    event.getInitialScreenIndex(), "SCREEN_GENERATE"
            );
            nextEvent.setCurrentScreenIndex(0);
            kafkaProducerService.sendBuildEvent(KafkaTopicConfig.TOPIC_BUILD_SCREEN_GENERATE, nextEvent);

        } catch (Exception e) {
            failBuild(buildId, e);
        }
    }

    /**
     * Step 2: Generate a single screen with full conversational context.
     */
    public void handleScreenGenerate(BuildPipelineEvent event) {
        String buildId = event.getBuildId();
        int screenIndex = event.getCurrentScreenIndex();
        log.info("Handling SCREEN_GENERATE for build {}, screen index {}", buildId, screenIndex);

        try {
            ProjectEntity project = projectRepository.findById(event.getProjectId())
                    .orElseThrow(() -> new RuntimeException("Project not found"));

            List<Screen> screens = project.getListOfScreens();
            if (screenIndex >= screens.size()) {
                // All screens generated — move to main.dart generation
                BuildPipelineEvent nextEvent = new BuildPipelineEvent(
                        buildId, event.getProjectId(), event.getInstructions(),
                        event.getInitialScreenIndex(), "MAIN_GENERATE"
                );
                kafkaProducerService.sendBuildEvent(KafkaTopicConfig.TOPIC_BUILD_MAIN_GENERATE, nextEvent);
                return;
            }

            Screen screen = screens.get(screenIndex);
            BuildContextManager contextManager = buildContextMap.get(buildId);
            if (contextManager == null) {
                throw new RuntimeException("Build context not found for buildId: " + buildId);
            }

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + event.getProjectId() + "/" + project.getProjectName();
            Path libDirectory = Paths.get(flutterProjectRootPath, "lib");

            addLog(buildId, String.format("Generating screen %d/%d: %s", screenIndex + 1, screens.size(), screen.getScreenName()));
            updateBuildProgress(buildId, "Generating screen " + (screenIndex + 1) + "/" + screens.size() + ": " + screen.getScreenName());

            // Get optimized context with full conversation history
            List<Map<String, String>> context = contextManager.getContextForScreen(screenIndex);

            // Build the prompt
            String prompt = createContextualPromptForScreen(screen, screenIndex, screens.size(), screens);
            String generatedCode = geminiAIService.generateContentWithContext(prompt, context);
            String cleanedCode = cleanGeneratedCode(generatedCode);

            if (cleanedCode.startsWith("Error:")) {
                throw new RuntimeException("AI generation failed for screen '" + screen.getScreenName() + "': " + cleanedCode);
            }

            // Write file
            String dartFileName = toSnakeCase(screen.getScreenName()) + ".dart";
            Files.write(libDirectory.resolve(dartFileName), cleanedCode.getBytes(StandardCharsets.UTF_8));
            addLog(buildId, "Successfully generated: " + dartFileName);

            // Update screen code in project
            screen.setScreenCode(cleanedCode);
            projectRepository.save(project);

            // Register in context manager
            contextManager.addGeneratedScreen(screen, dartFileName, cleanedCode);

            // Check if back-patching is needed
            List<BuildContextManager.BackpatchRequest> backpatchRequests = contextManager.detectBackpatchNeeds(screenIndex);

            if (!backpatchRequests.isEmpty()) {
                addLog(buildId, "Back-patch needed for " + backpatchRequests.size() + " previous screen(s).");

                // Process back-patches synchronously before moving to next screen
                for (BuildContextManager.BackpatchRequest bpr : backpatchRequests) {
                    handleBackpatch(buildId, event.getProjectId(), project, screenIndex, bpr, contextManager, libDirectory);
                }
            }

            // Proceed to next screen
            BuildPipelineEvent nextEvent = new BuildPipelineEvent(
                    buildId, event.getProjectId(), event.getInstructions(),
                    event.getInitialScreenIndex(), "SCREEN_GENERATE"
            );
            nextEvent.setCurrentScreenIndex(screenIndex + 1);
            kafkaProducerService.sendBuildEvent(KafkaTopicConfig.TOPIC_BUILD_SCREEN_GENERATE, nextEvent);

        } catch (Exception e) {
            failBuild(buildId, e);
        }
    }

    /**
     * Handles back-patching a single previously generated screen.
     */
    private void handleBackpatch(String buildId, String projectId, ProjectEntity project,
                                 int triggeringScreenIndex,
                                 BuildContextManager.BackpatchRequest request,
                                 BuildContextManager contextManager,
                                 Path libDirectory) throws IOException {

        log.info("Back-patching screen '{}' (index {}) triggered by screen index {}",
                request.screenName, request.screenIndex, triggeringScreenIndex);

        addLog(buildId, "Back-patching screen '" + request.screenName + "' — reasons: " + String.join("; ", request.reasons));
        updateBuildProgress(buildId, "Back-patching: " + request.screenName);

        List<Map<String, String>> context = contextManager.getContextForBackpatch(
                request.screenIndex, triggeringScreenIndex, request.reasons);

        String prompt = createBackpatchPrompt(request);
        String updatedCode = geminiAIService.generateContentWithContext(prompt, context);
        String cleanedCode = cleanGeneratedCode(updatedCode);

        if (cleanedCode.startsWith("Error:")) {
            addLog(buildId, "WARNING: Back-patch failed for '" + request.screenName + "': " + cleanedCode);
            return; // Non-fatal — we continue the build
        }

        // Write updated file
        Files.write(libDirectory.resolve(request.fileName), cleanedCode.getBytes(StandardCharsets.UTF_8));
        addLog(buildId, "Successfully back-patched: " + request.fileName);

        // Update context manager
        contextManager.updateGeneratedScreen(request.screenIndex, cleanedCode);

        // Update project entity
        List<Screen> screens = project.getListOfScreens();
        if (request.screenIndex < screens.size()) {
            screens.get(request.screenIndex).setScreenCode(cleanedCode);
            projectRepository.save(project);
        }
    }

    /**
     * Step 3: Generate main.dart.
     */
    public void handleMainGenerate(BuildPipelineEvent event) {
        String buildId = event.getBuildId();
        log.info("Handling MAIN_GENERATE for build {}", buildId);

        try {
            ProjectEntity project = projectRepository.findById(event.getProjectId())
                    .orElseThrow(() -> new RuntimeException("Project not found"));

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + event.getProjectId() + "/" + project.getProjectName();
            Path libDirectory = Paths.get(flutterProjectRootPath, "lib");

            BuildContextManager contextManager = buildContextMap.get(buildId);
            if (contextManager == null) {
                throw new RuntimeException("Build context not found for buildId: " + buildId);
            }

            addLog(buildId, "Generating main.dart...");
            updateBuildProgress(buildId, "Generating main.dart with AI...");

            generateMainDartFileWithAI(libDirectory, project.getListOfScreens(),
                    event.getInitialScreenIndex(), project.getProjectName(), contextManager);

            addLog(buildId, "Successfully generated main.dart.");

            // Proceed to Flutter compile
            BuildPipelineEvent nextEvent = new BuildPipelineEvent(
                    buildId, event.getProjectId(), event.getInstructions(),
                    event.getInitialScreenIndex(), "FLUTTER_COMPILE"
            );
            kafkaProducerService.sendBuildEvent(KafkaTopicConfig.TOPIC_BUILD_FLUTTER_COMPILE, nextEvent);

        } catch (Exception e) {
            failBuild(buildId, e);
        }
    }

    /**
     * Step 4: Run `flutter build apk`.
     */
    public void handleFlutterCompile(BuildPipelineEvent event) {
        String buildId = event.getBuildId();
        log.info("Handling FLUTTER_COMPILE for build {}", buildId);

        try {
            ProjectEntity project = projectRepository.findById(event.getProjectId())
                    .orElseThrow(() -> new RuntimeException("Project not found"));

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + event.getProjectId() + "/" + project.getProjectName();

            addLog(buildId, "Starting Flutter APK build...");
            updateBuildProgress(buildId, "Building APK with Flutter...");

            BuildStatus status = buildStatusMap.get(buildId);
            runFlutterBuild(flutterProjectRootPath, status, buildId);

            addLog(buildId, "Flutter build completed successfully.");

            // Proceed to finalize
            BuildPipelineEvent nextEvent = new BuildPipelineEvent(
                    buildId, event.getProjectId(), event.getInstructions(),
                    event.getInitialScreenIndex(), "FINALIZE"
            );
            kafkaProducerService.sendBuildEvent(KafkaTopicConfig.TOPIC_BUILD_FINALIZE, nextEvent);

        } catch (Exception e) {
            failBuild(buildId, e);
        }
    }

    /**
     * Step 5: Store the APK and mark build as complete.
     */
    public void handleBuildFinalize(BuildPipelineEvent event) {
        String buildId = event.getBuildId();
        log.info("Handling FINALIZE for build {}", buildId);

        try {
            ProjectEntity project = projectRepository.findById(event.getProjectId())
                    .orElseThrow(() -> new RuntimeException("Project not found"));

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + event.getProjectId() + "/" + project.getProjectName();

            addLog(buildId, "Locating generated APK...");
            updateBuildProgress(buildId, "Finalizing build and storing APK...");

            Path generatedApkPath = findGeneratedApk(flutterProjectRootPath);
            Path finalApkPath = storeApk(generatedApkPath, buildId);
            addLog(buildId, "APK stored at: " + finalApkPath);

            String buildVersion = "v1.0." + System.currentTimeMillis();

            // Mark build as completed
            completeBuild(buildId, true, null, finalApkPath.toString(), buildVersion);

            // Update project
            project.setLastBuildAt(LocalDateTime.now());
            project.setLastBuildVersion(buildVersion);
            project.setLastBuildLocation(finalApkPath.toString());
            projectRepository.save(project);

            // Clean up context manager
            buildContextMap.remove(buildId);

            log.info("Build {} completed successfully.", buildId);

        } catch (Exception e) {
            failBuild(buildId, e);
        }
    }

    // ========================
    // PROMPT BUILDERS
    // ========================

    private String createContextualPromptForScreen(Screen screen, int currentIndex, int totalScreens, List<Screen> allScreens) {
        StringBuilder prompt = new StringBuilder();

        prompt.append(String.format("**Generate Screen %d of %d: %s**\n\n", currentIndex + 1, totalScreens, screen.getScreenName()));

        if (currentIndex == 0) {
            prompt.append("This is the FIRST screen in the project. Establish the foundational patterns (theming, navigation style, state management approach) that all subsequent screens will follow.\n\n");
        } else {
            prompt.append("This screen MUST be fully consistent with all previously generated screens. Use the same navigation patterns, theming, state management, and import conventions.\n\n");
        }

        // Show upcoming screens so the AI can anticipate navigation needs
        if (currentIndex < totalScreens - 1) {
            prompt.append("**Upcoming screens (for navigation planning):**\n");
            for (int i = currentIndex + 1; i < totalScreens; i++) {
                Screen upcoming = allScreens.get(i);
                String upcomingFile = toSnakeCase(upcoming.getScreenName()) + ".dart";
                prompt.append(String.format("  - %s (file: %s)\n", upcoming.getScreenName(), upcomingFile));
            }
            prompt.append("If this screen needs to navigate to any upcoming screen, use the exact class name and import the corresponding file.\n\n");
        }

        prompt.append("**CRITICAL REQUIREMENTS**:\n");
        prompt.append("1. The main widget class MUST be named EXACTLY: `").append(screen.getScreenName()).append("`\n");
        prompt.append("2. ALWAYS use lowercase `@override` annotation (NEVER `@Override`)\n");
        prompt.append("3. Use consistent navigation patterns with all previous screens\n");
        prompt.append("4. Use consistent theming and styling approaches\n");
        prompt.append("5. Import other screen files correctly when navigating to them\n");
        prompt.append("6. Use consistent state management patterns\n\n");

        if (screen.getScreenPrompt() != null && !screen.getScreenPrompt().trim().isEmpty()) {
            prompt.append("**SCREEN SPECIFIC REQUIREMENTS**:\n");
            prompt.append(screen.getScreenPrompt()).append("\n\n");
        }

        if (screen.getScreenCode() != null && !screen.getScreenCode().trim().isEmpty()) {
            prompt.append("**BASE CODE TO MODIFY/ENHANCE**:\n```dart\n");
            prompt.append(screen.getScreenCode());
            prompt.append("\n```\n\n");
        }

        prompt.append("**OUTPUT FORMAT**:\n");
        prompt.append("Respond with ONLY the complete, production-ready Dart code. ");
        prompt.append("Do NOT include explanations, markdown code blocks (```dart or ```), or any other text. ");
        prompt.append("Your response must start directly with 'import' or 'class'.");

        return prompt.toString();
    }

    private String createBackpatchPrompt(BuildContextManager.BackpatchRequest request) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("**UPDATE REQUIRED for screen '").append(request.screenName).append("' (").append(request.fileName).append(")**\n\n");
        prompt.append("The following issues need to be fixed in this screen:\n");
        for (String reason : request.reasons) {
            prompt.append("- ").append(reason).append("\n");
        }
        prompt.append("\n**REQUIREMENTS**:\n");
        prompt.append("1. Fix ALL the issues listed above\n");
        prompt.append("2. Keep all existing functionality intact\n");
        prompt.append("3. Add any missing imports\n");
        prompt.append("4. Maintain the same class name and structure\n");
        prompt.append("5. Ensure navigation works correctly with the new screen\n\n");
        prompt.append("**OUTPUT FORMAT**:\n");
        prompt.append("Respond with ONLY the complete updated Dart code for this file. ");
        prompt.append("Do NOT include explanations, markdown code blocks, or any other text. ");
        prompt.append("Your response must start directly with 'import' or 'class'.");
        return prompt.toString();
    }

    // ========================
    // UTILITY METHODS
    // ========================

    private String cleanGeneratedCode(String rawCode) {
        if (rawCode == null || rawCode.trim().isEmpty()) return "";
        String cleaned = rawCode.trim();
        if (cleaned.startsWith("```dart")) {
            cleaned = cleaned.substring(7).trim();
        } else if (cleaned.startsWith("```")) {
            cleaned = cleaned.substring(3).trim();
        }
        if (cleaned.endsWith("```")) {
            cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
        }
        return cleaned;
    }

    private void runFlutterBuild(String projectPath, BuildStatus status, String buildId) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder();
        String flutterExecutablePath = "C:\\flutter\\flutter\\bin\\flutter.bat";
        processBuilder.command(flutterExecutablePath, "build", "apk", "--release");
        processBuilder.directory(new java.io.File(projectPath));
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (status != null) {
                    status.getLogs().add(line);
                }
                addLog(buildId, line);
            }
        }

        boolean finished = process.waitFor(10, TimeUnit.MINUTES);
        if (!finished) {
            process.destroy();
            throw new RuntimeException("Flutter build timed out after 10 minutes.");
        }

        int exitCode = process.exitValue();
        if (exitCode != 0) {
            throw new RuntimeException("Flutter build command failed with exit code " + exitCode);
        }
    }

    private void generateMainDartFileWithAI(Path libDirectory, List<Screen> screens, int initialScreenIndex,
                                            String projectName, BuildContextManager contextManager) throws IOException {
        if (initialScreenIndex < 0 || initialScreenIndex >= screens.size()) {
            throw new IllegalArgumentException("Initial screen index is out of bounds.");
        }

        Screen initialScreen = screens.get(initialScreenIndex);

        StringBuilder screenInfo = new StringBuilder();
        screenInfo.append("**Available Screens in the Project:**\n");
        for (int i = 0; i < screens.size(); i++) {
            Screen screen = screens.get(i);
            String fileName = toSnakeCase(screen.getScreenName()) + ".dart";
            screenInfo.append(String.format("%d. Class: %s, File: %s%s\n",
                    i + 1, screen.getScreenName(), fileName,
                    i == initialScreenIndex ? " (INITIAL SCREEN)" : ""));
        }

        String mainDartPrompt = String.format(
                "Generate the main.dart file for the Flutter application '%s'.\n\n" +
                        "%s\n" +
                        "**REQUIREMENTS**:\n" +
                        "1. Import the initial screen: %s (from file: %s)\n" +
                        "2. Set up MaterialApp with the initial screen as home\n" +
                        "3. Configure basic theme with proper theming\n" +
                        "4. Use proper Flutter best practices\n" +
                        "5. Include const constructors where appropriate\n" +
                        "6. Set the app title to: '%s'\n" +
                        "7. Use @override with lowercase 'o'\n\n" +
                        "**OUTPUT FORMAT**:\n" +
                        "Respond with ONLY the complete main.dart code. " +
                        "Do NOT include explanations, markdown code blocks, or any other text. " +
                        "Your response must start directly with 'import'.",
                projectName, screenInfo, initialScreen.getScreenName(),
                toSnakeCase(initialScreen.getScreenName()) + ".dart", projectName
        );

        List<Map<String, String>> mainContext = contextManager.getContextForMainDart();
        String generatedMainDart = geminiAIService.generateContentWithContext(mainDartPrompt, mainContext);
        String cleanedMainDart = cleanGeneratedCode(generatedMainDart);

        if (cleanedMainDart.startsWith("Error:")) {
            throw new RuntimeException("AI generation failed for main.dart: " + cleanedMainDart);
        }

        Files.write(libDirectory.resolve("main.dart"), cleanedMainDart.getBytes(StandardCharsets.UTF_8));
    }

    private String toSnakeCase(String input) {
        if (input == null || input.isEmpty()) return "";
        return input.replaceAll("([a-z])([A-Z]+)", "$1_$2")
                .replaceAll("\\s+", "_")
                .toLowerCase();
    }

    private Path findGeneratedApk(String projectPath) {
        Path apkPath = Paths.get(projectPath, "build", "app", "outputs", "flutter-apk", "app-release.apk");
        if (!Files.exists(apkPath)) {
            throw new RuntimeException("APK not found at: " + apkPath);
        }
        return apkPath;
    }

    private Path storeApk(Path sourceApkPath, String buildId) throws IOException {
        Path finalBuildsDir = Paths.get(FINAL_BUILDS_FOLDER);
        Files.createDirectories(finalBuildsDir);
        Path destinationApkPath = finalBuildsDir.resolve(buildId + ".apk");
        Files.move(sourceApkPath, destinationApkPath, StandardCopyOption.REPLACE_EXISTING);
        return destinationApkPath;
    }

    // ========================
    // STATUS MANAGEMENT
    // ========================

    private void addLog(String buildId, String logMessage) {
        BuildStatus status = buildStatusMap.get(buildId);
        if (status != null) {
            status.getLogs().add(logMessage);
        }

        // Persist to DB periodically (every log for now; can be batched for performance)
        BuildEntity build = buildRepository.findByBuildId(buildId).orElse(null);
        if (build != null) {
            build.getLogs().add(logMessage);
            buildRepository.save(build);
        }
    }

    private void updateBuildProgress(String buildId, String statusMessage) {
        BuildStatus status = buildStatusMap.get(buildId);
        if (status != null) {
            status.setStatusMessage(statusMessage);
        }

        BuildEntity build = buildRepository.findByBuildId(buildId).orElse(null);
        if (build != null) {
            build.setStatusMessage(statusMessage);
            buildRepository.save(build);
        }
    }

    private void completeBuild(String buildId, boolean success, String errorMessage, String apkLocation, String buildVersion) {
        BuildEntity build = buildRepository.findByBuildId(buildId).orElse(null);
        if (build != null) {
            build.setCompleted(true);
            build.setSuccess(success);
            build.setErrorMessage(errorMessage);
            build.setApkLocation(apkLocation);
            build.setBuildVersion(buildVersion);
            build.setCompletedAt(LocalDateTime.now());
            build.setBuildDurationMs(
                    java.time.Duration.between(build.getCreatedAt(), LocalDateTime.now()).toMillis()
            );
            build.setStatusMessage(success ? "Build completed successfully." : "Build failed.");
            buildRepository.save(build);
        }

        BuildStatus status = buildStatusMap.get(buildId);
        if (status != null) {
            status.setCompleted(true);
            status.setSuccess(success);
            status.setErrorMessage(errorMessage);
            status.setStatusMessage(success ? "Build completed successfully." : "Build failed.");
            status.setApkFilePath(apkLocation);
        }
    }

    private void failBuild(String buildId, Exception e) {
        log.error("Build failed for buildId: {}", buildId, e);
        addLog(buildId, "ERROR: " + e.getMessage());
        completeBuild(buildId, false, e.getMessage(), null, null);
        buildContextMap.remove(buildId);
    }

    // ========================
    // QUERY METHODS
    // ========================

    public BuildStatus getBuildStatus(String buildId) {
        // Try in-memory first for real-time data
        BuildStatus status = buildStatusMap.get(buildId);
        if (status != null) {
            return status;
        }

        // Fallback to database (for builds that completed and were evicted from memory)
        BuildEntity build = buildRepository.findByBuildId(buildId).orElse(null);
        if (build != null) {
            BuildStatus dbStatus = new BuildStatus();
            dbStatus.setBuildId(build.getBuildId());
            dbStatus.setStatusMessage(build.getStatusMessage());
            dbStatus.setCompleted(build.isCompleted());
            dbStatus.setSuccess(build.isSuccess());
            dbStatus.setErrorMessage(build.getErrorMessage());
            dbStatus.setApkFilePath(build.getApkLocation());
            //dbStatus.setLogs(build.getLogs() != null ? build.getLogs() : new ArrayList<>());
            return dbStatus;
        }

        return null;
    }

    public Resource getApkResource(String buildId) {
        BuildStatus status = getBuildStatus(buildId);
        if (status == null || !status.isSuccess() || status.getApkFilePath() == null) {
            throw new RuntimeException("Build not found, not successful, or APK path is missing.");
        }
        try {
            Path filePath = Paths.get(status.getApkFilePath());
            Resource resource = new UrlResource(filePath.toUri());
            if (resource.exists() && resource.isReadable()) {
                return resource;
            } else {
                throw new RuntimeException("Could not read APK file: " + filePath);
            }
        } catch (MalformedURLException e) {
            throw new RuntimeException("Error creating resource for APK: " + e.getMessage(), e);
        }
    }

    public List<BuildEntity> getBuildsByOrganisationId(String organisationId) {
        return buildRepository.findByOrganisationIdOrderByCreatedAtDesc(organisationId);
    }

    public BuildEntity getBuildByBuildId(String buildId) {
        return buildRepository.findByBuildId(buildId)
                .orElseThrow(() -> new RuntimeException("Build not found with buildId: " + buildId));
    }

    public List<BuildEntity> getBuildsByProjectId(String projectId) {
        return buildRepository.findByProjectId(projectId);
    }

    public List<BuildEntity> getBuildsByUserId(String userId) {
        return buildRepository.findByCreatedById(userId);
    }

    public void deleteBuild(String buildId) {
        BuildEntity build = buildRepository.findByBuildId(buildId)
                .orElseThrow(() -> new RuntimeException("Build not found with buildId: " + buildId));

        if (build.getApkLocation() != null) {
            try {
                Path apkPath = Paths.get(build.getApkLocation());
                Files.deleteIfExists(apkPath);
                log.info("Deleted APK file: {}", build.getApkLocation());
            } catch (IOException e) {
                log.warn("Failed to delete APK file: {}", build.getApkLocation(), e);
            }
        }

        buildStatusMap.remove(buildId);
        buildContextMap.remove(buildId);
        buildRepository.delete(build);
    }

    public void deleteBuildsByOrganisationId(String organisationId) {
        // Optional: check if builds exist first
        List<BuildEntity> builds = buildRepository.findByOrganisationId(organisationId);
        if (!builds.isEmpty()) {
            buildRepository.deleteByOrganisationId(organisationId);
        }
    }

    // Delete all builds of a specific project
    public void deleteBuildsByProjectId(String projectId) {
        List<BuildEntity> builds = buildRepository.findByProjectId(projectId);
        if (!builds.isEmpty()) {
            buildRepository.deleteByProjectId(projectId);
        }
    }

    public BuildEntity saveBuild(BuildEntity build) {
        return buildRepository.save(build);
    }

    public BuildEntity updateBuild(BuildEntity build) {
        if (build.getId() == null) {
            throw new IllegalArgumentException("Cannot update build without an ID");
        }
        return buildRepository.save(build);
    }
}
