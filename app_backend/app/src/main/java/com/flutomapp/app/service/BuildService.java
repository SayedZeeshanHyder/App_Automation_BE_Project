package com.flutomapp.app.service;

import com.flutomapp.app.dtomodel.Screen;
import com.flutomapp.app.httpmodels.BuildModels.BuildRequest;
import com.flutomapp.app.httpmodels.BuildModels.BuildStatus;
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
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@Service
public class BuildService{

    private static final Logger log = LoggerFactory.getLogger(BuildService.class);
    private final GeminiAIService geminiAIService;
    private final ProjectRepository projectRepository;
    private final BuildRepository buildRepository;
    private static final String BASE_PROJECTS_FOLDER = "projects";
    private static final String FINAL_BUILDS_FOLDER = "builds";
    private final ConcurrentHashMap<String, BuildStatus> buildStatusMap = new ConcurrentHashMap<>();

    // Context window management
    private static final int MAX_CONTEXT_SCREENS = 3;
    private static final int SUMMARIZATION_THRESHOLD = 4;

    private final ExecutorService buildExecutor = Executors.newFixedThreadPool(5);

    public BuildService(GeminiAIService geminiAIService, ProjectRepository projectRepository, BuildRepository buildRepository) {
        this.geminiAIService = geminiAIService;
        this.projectRepository = projectRepository;
        this.buildRepository = buildRepository;
    }

    public String startBuildProcess(String projectId, BuildRequest buildRequest, UserEntity user) {
        String buildId = UUID.randomUUID().toString();

        // Fetch project and organisation
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

        // Initialize BuildStatus for real-time status tracking
        BuildStatus status = new BuildStatus();
        status.setBuildId(buildId);
        status.setStatusMessage("Build initiated. Queued for processing...");
        buildStatusMap.put(buildId, status);

        // Start async build process
        buildExecutor.submit(() -> runBuildAsync(buildId, projectId, buildRequest));
        return buildId;
    }

    public void runBuildAsync(String buildId, String projectId, BuildRequest request) {
        log.info("Starting build {} on thread: {}", buildId, Thread.currentThread().getName());
        BuildStatus status = buildStatusMap.get(buildId);
        BuildEntity buildEntity = buildRepository.findByBuildId(buildId).orElse(null);

        try {
            updateBuildProgress(buildId, "Fetching project details and screens...",
                    List.of("Fetching project data for project ID: " + projectId));

            ProjectEntity project = projectRepository.findById(projectId)
                    .orElseThrow(() -> new RuntimeException("Project not found with id: " + projectId));

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + projectId + "/" + project.getProjectName();
            Path libDirectory = Paths.get(flutterProjectRootPath, "lib");
            Files.createDirectories(libDirectory);

            updateBuildProgress(buildId, "Generating Dart files with AI (Smart Context Management)...",
                    status.getLogs());
            List<Screen> screens = project.getListOfScreens();
            status.getLogs().add("Starting context-aware AI code generation for " + screens.size() + " screens.");

            // Initialize build context
            BuildContext buildContext = new BuildContext();
            buildContext.initialize(project.getProjectName(), request.getInstructions(), screens.size());

            // Generate screens sequentially with smart context management
            for (int i = 0; i < screens.size(); i++) {
                Screen screen = screens.get(i);
                status.getLogs().add(String.format("Generating screen %d/%d: %s", i + 1, screens.size(), screen.getScreenName()));
                updateBuildProgress(buildId, "Generating screen " + (i + 1) + "/" + screens.size(), status.getLogs());

                // Get optimized context for this screen
                List<Map<String, String>> optimizedContext = buildContext.getOptimizedContextForScreen(i);

                String prompt = createContextualPromptForScreen(screen, i, screens.size());
                String generatedDartCode = geminiAIService.generateContentWithContext(prompt, optimizedContext);
                String cleanedDartCode = cleanGeneratedCode(generatedDartCode);

                if (cleanedDartCode.startsWith("Error:")) {
                    throw new RuntimeException("AI generation failed for screen '" + screen.getScreenName() + "': " + cleanedDartCode);
                }

                screen.setScreenCode(cleanedDartCode);
                String dartFileName = toSnakeCase(screen.getScreenName()) + ".dart";
                Files.write(libDirectory.resolve(dartFileName), cleanedDartCode.getBytes(StandardCharsets.UTF_8));
                status.getLogs().add("Successfully generated file: " + dartFileName);

                // Update build context with this screen
                buildContext.addGeneratedScreen(screen, dartFileName, cleanedDartCode);
            }

            updateBuildProgress(buildId, "Generating main.dart with AI...", status.getLogs());
            generateMainDartFileWithAI(libDirectory, screens, request.getInitialScreenIndex(), project.getProjectName(), buildContext);
            status.getLogs().add("Successfully generated main.dart.");

            updateBuildProgress(buildId, "Building APK with Flutter command...", status.getLogs());
            runFlutterBuild(flutterProjectRootPath, status);

            updateBuildProgress(buildId, "Finalizing build and storing APK...", status.getLogs());
            status.getLogs().add("Flutter build command completed. Locating APK...");
            Path generatedApkPath = findGeneratedApk(flutterProjectRootPath);
            Path finalApkPath = storeApk(generatedApkPath, buildId);
            status.getLogs().add("APK successfully stored at: " + finalApkPath);

            // Calculate build version
            String buildVersion = "v1.0." + System.currentTimeMillis();

            // Mark build as completed successfully
            completeBuild(buildId, true, null, finalApkPath.toString(), buildVersion);

            // Update project entity
            project.setListOfScreens(screens);
            project.setLastBuildAt(LocalDateTime.now());
            project.setLastBuildVersion(buildVersion);
            project.setLastBuildLocation(finalApkPath.toString());
            projectRepository.save(project);

        } catch (Exception e) {
            status.setStatusMessage("Build failed.");
            status.setErrorMessage(e.getMessage());
            status.setCompleted(true);
            status.setSuccess(false);
            status.getLogs().add("ERROR: " + e.getMessage());
            log.error("Build failed for buildId: {}", buildId, e);

            // Update BuildEntity with failure
            completeBuild(buildId, false, e.getMessage(), null, null);
        }
    }

    /**
     * Smart Build Context Manager - maintains rolling summary + recent detailed context
     */
    private static class BuildContext {
        private final List<Map<String, String>> conversationHistory = new ArrayList<>();
        private final List<ScreenSummary> screenSummaries = new ArrayList<>();
        private String projectName;
        private String generalInstructions;
        private int totalScreens;

        public void initialize(String projectName, String instructions, int totalScreens) {
            this.projectName = projectName;
            this.generalInstructions = instructions;
            this.totalScreens = totalScreens;

            addToHistory("user",
                    "You are an expert Flutter/Dart developer working on project '" + projectName +
                            "'. You will generate " + totalScreens + " screens sequentially. " +
                            "Each screen must be consistent with previously generated screens. " +
                            "General Instructions: " + instructions);

            addToHistory("model",
                    "Understood. I will generate Flutter screens maintaining consistency with project '" +
                            projectName + "' and following your instructions.");
        }

        public void addGeneratedScreen(Screen screen, String fileName, String code) {
            ScreenSummary summary = new ScreenSummary(
                    screen.getScreenName(),
                    fileName,
                    extractImportantPatterns(code)
            );
            screenSummaries.add(summary);
        }

        public List<Map<String, String>> getOptimizedContextForScreen(int screenIndex) {
            List<Map<String, String>> optimizedContext = new ArrayList<>(conversationHistory);

            if (screenIndex >= SUMMARIZATION_THRESHOLD) {
                String consolidatedSummary = createConsolidatedSummary(screenIndex);
                Map<String, String> summaryMsg = new HashMap<>();
                summaryMsg.put("role", "user");
                summaryMsg.put("text", consolidatedSummary);
                optimizedContext.add(summaryMsg);

                Map<String, String> ackMsg = new HashMap<>();
                ackMsg.put("role", "model");
                ackMsg.put("text", "I understand the patterns from previous screens and will maintain consistency.");
                optimizedContext.add(ackMsg);
            }

            // Add detailed context for recent screens
            int detailStartIndex = Math.max(0, screenIndex - MAX_CONTEXT_SCREENS);
            for (int i = detailStartIndex; i < screenIndex; i++) {
                if (i < screenSummaries.size()) {
                    ScreenSummary summary = screenSummaries.get(i);
                    Map<String, String> detailMsg = new HashMap<>();
                    detailMsg.put("role", "user");
                    detailMsg.put("text", "Recent screen '" + summary.screenName + "' (" + summary.fileName + ") uses:\n" + summary.patterns);
                    optimizedContext.add(detailMsg);
                }
            }

            return optimizedContext;
        }

        private String createConsolidatedSummary(int upToIndex) {
            StringBuilder summary = new StringBuilder();
            summary.append("**Summary of Previously Generated Screens (1-").append(upToIndex).append("):**\n\n");

            Map<String, Integer> navigationPatterns = new HashMap<>();

            int endIndex = Math.min(upToIndex, screenSummaries.size());
            int summaryEndIndex = Math.max(0, endIndex - MAX_CONTEXT_SCREENS);

            for (int i = 0; i < summaryEndIndex; i++) {
                ScreenSummary s = screenSummaries.get(i);
                summary.append(i + 1).append(". ").append(s.screenName)
                        .append(" (").append(s.fileName).append(")\n");

                if (s.patterns.contains("Navigator.push")) {
                    navigationPatterns.merge("push", 1, Integer::sum);
                }
                if (s.patterns.contains("Navigator.pop")) {
                    navigationPatterns.merge("pop", 1, Integer::sum);
                }
            }

            summary.append("\n**Common Patterns Found:**\n");
            summary.append("- Navigation: ").append(navigationPatterns.toString()).append("\n");
            summary.append("- Total screens summarized: ").append(summaryEndIndex).append("\n");
            summary.append("\n**Maintain these patterns in upcoming screens.**");

            return summary.toString();
        }

        private String extractImportantPatterns(String code) {
            StringBuilder patterns = new StringBuilder();

            if (code.contains("Navigator.push")) {
                patterns.append("- Uses Navigator.push for navigation\n");
            }
            if (code.contains("StatefulWidget")) {
                patterns.append("- StatefulWidget with state management\n");
            } else if (code.contains("StatelessWidget")) {
                patterns.append("- StatelessWidget (no state)\n");
            }
            if (code.contains("Scaffold")) {
                patterns.append("- Uses Scaffold structure\n");
            }
            if (code.contains("ThemeData") && code.contains("primaryColor")) {
                patterns.append("- Custom theme colors defined\n");
            }

            String[] lines = code.split("\n");
            for (String line : lines) {
                if (line.trim().startsWith("import ")) {
                    patterns.append(line.trim()).append("\n");
                }
            }

            return patterns.toString();
        }

        private void addToHistory(String role, String text) {
            Map<String, String> message = new HashMap<>();
            message.put("role", role);
            message.put("text", text);
            conversationHistory.add(message);
        }

        public List<Map<String, String>> getContextForMainDart() {
            List<Map<String, String>> mainContext = new ArrayList<>();

            if (!conversationHistory.isEmpty()) {
                mainContext.add(conversationHistory.get(0));
                if (conversationHistory.size() > 1) {
                    mainContext.add(conversationHistory.get(1));
                }
            }

            StringBuilder allScreensSummary = new StringBuilder();
            allScreensSummary.append("**All Generated Screens:**\n");
            for (ScreenSummary s : screenSummaries) {
                allScreensSummary.append("- ").append(s.screenName)
                        .append(" (").append(s.fileName).append(")\n");
            }

            Map<String, String> summaryMsg = new HashMap<>();
            summaryMsg.put("role", "user");
            summaryMsg.put("text", allScreensSummary.toString());
            mainContext.add(summaryMsg);

            return mainContext;
        }
    }

    private static class ScreenSummary {
        String screenName;
        String fileName;
        String patterns;

        ScreenSummary(String screenName, String fileName, String patterns) {
            this.screenName = screenName;
            this.fileName = fileName;
            this.patterns = patterns;
        }
    }

    private String createContextualPromptForScreen(Screen screen, int currentIndex, int totalScreens) {
        StringBuilder prompt = new StringBuilder();

        prompt.append(String.format("**Screen %d of %d: %s**\n\n", currentIndex + 1, totalScreens, screen.getScreenName()));

        if (currentIndex == 0) {
            prompt.append("This is the FIRST screen in the project. ");
        } else {
            prompt.append("This screen should be CONSISTENT with all previously generated screens. ");
        }

        prompt.append("\n**CRITICAL REQUIREMENTS**:\n");
        prompt.append("1. The main widget class MUST be named EXACTLY: `").append(screen.getScreenName()).append("`\n");
        prompt.append("2. ALWAYS use lowercase `@override` annotation (NEVER `@Override`)\n");
        prompt.append("3. Maintain consistency with previously generated screens in terms of:\n");
        prompt.append("   - Navigation patterns and routing\n");
        prompt.append("   - Shared widgets or components\n");
        prompt.append("   - Theming and styling approaches\n");
        prompt.append("   - State management patterns\n");
        prompt.append("   - Import statements and dependencies\n\n");

        if (screen.getScreenPrompt() != null && !screen.getScreenPrompt().trim().isEmpty()) {
            prompt.append("**SCREEN SPECIFIC REQUIREMENTS**:\n");
            prompt.append(screen.getScreenPrompt()).append("\n\n");
        }

        if (screen.getScreenCode() != null && !screen.getScreenCode().trim().isEmpty()) {
            prompt.append("**BASE CODE TO MODIFY**:\n```dart\n");
            prompt.append(screen.getScreenCode());
            prompt.append("\n```\n\n");
        }

        prompt.append("**OUTPUT FORMAT**:\n");
        prompt.append("Respond with ONLY the complete, production-ready Dart code. ");
        prompt.append("Do NOT include explanations, markdown code blocks (```dart or ```), or any other text. ");
        prompt.append("Your response must start directly with 'import' or 'class'.");

        return prompt.toString();
    }

    private String cleanGeneratedCode(String rawCode) {
        if (rawCode == null || rawCode.trim().isEmpty()) {
            return "";
        }

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

    private void runFlutterBuild(String projectPath, BuildStatus status) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder();
        String flutterExecutablePath = "C:\\Users\\zhyde\\OneDrive\\Desktop\\Zeeshan\\fluttersdk\\flutter_windows_3.29.3-stable\\flutter\\bin\\flutter.bat";
        processBuilder.command(flutterExecutablePath, "build", "apk", "--release");
        processBuilder.directory(new java.io.File(projectPath));
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                status.getLogs().add(line);
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

    private void generateMainDartFileWithAI(Path libDirectory, List<Screen> screens, int initialScreenIndex, String projectName, BuildContext buildContext) throws IOException {
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
                    i + 1,
                    screen.getScreenName(),
                    fileName,
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
                projectName,
                screenInfo.toString(),
                initialScreen.getScreenName(),
                toSnakeCase(initialScreen.getScreenName()) + ".dart",
                projectName
        );

        List<Map<String, String>> mainContext = buildContext.getContextForMainDart();
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

    // Helper method to update both BuildEntity and BuildStatus during build progress
    private void updateBuildProgress(String buildId, String statusMessage, List<String> logs) {
        // Update BuildEntity in database
        BuildEntity build = buildRepository.findByBuildId(buildId).orElse(null);
        if (build != null) {
            build.setStatusMessage(statusMessage);
            build.setLogs(new ArrayList<>(logs)); // Create new list to avoid reference issues
            buildRepository.save(build);
        }

        // Update BuildStatus in-memory map for real-time status
        BuildStatus status = buildStatusMap.get(buildId);
        if (status != null) {
            status.setStatusMessage(statusMessage);
        }
    }

    // Helper method to mark build as completed
    private void completeBuild(String buildId, boolean success, String errorMessage, String apkLocation, String buildVersion) {
        // Update BuildEntity
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

        // Update BuildStatus map
        BuildStatus status = buildStatusMap.get(buildId);
        if (status != null) {
            status.setCompleted(true);
            status.setSuccess(success);
            status.setErrorMessage(errorMessage);
            status.setStatusMessage(success ? "Build completed successfully." : "Build failed.");
            status.setApkFilePath(apkLocation);
        }
    }

    public BuildStatus getBuildStatus(String buildId) {
        return buildStatusMap.get(buildId);
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

        // Delete APK file if it exists
        if (build.getApkLocation() != null) {
            try {
                Path apkPath = Paths.get(build.getApkLocation());
                Files.deleteIfExists(apkPath);
                log.info("Deleted APK file: {}", build.getApkLocation());
            } catch (IOException e) {
                log.warn("Failed to delete APK file: {}", build.getApkLocation(), e);
            }
        }

        // Remove from in-memory map
        buildStatusMap.remove(buildId);

        // Delete from database
        buildRepository.delete(build);
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