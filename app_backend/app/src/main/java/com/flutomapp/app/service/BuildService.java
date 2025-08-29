package com.flutomapp.app.service;

import com.flutomapp.app.dtomodel.Screen;
import com.flutomapp.app.httpmodels.BuildModels.BuildRequest;
import com.flutomapp.app.httpmodels.BuildModels.BuildStatus;
import com.flutomapp.app.model.ProjectEntity;
import com.flutomapp.app.repository.ProjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.scheduling.annotation.Async;
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
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class BuildService {

    private final GeminiAIService geminiAIService;
    private final ProjectRepository projectRepository;
    private static final String BASE_PROJECTS_FOLDER = "projects";
    private static final String FINAL_BUILDS_FOLDER = "builds";
    private final ConcurrentHashMap<String, BuildStatus> buildStatusMap = new ConcurrentHashMap<>();

    public String startBuildProcess(String projectId, BuildRequest request) {
        String buildId = UUID.randomUUID().toString();
        BuildStatus status = new BuildStatus();
        status.setBuildId(buildId);
        status.setStatusMessage("Build initiated. Queued for processing...");
        buildStatusMap.put(buildId, status);

        runBuildAsync(buildId, projectId, request);
        return buildId;
    }

    @Async
    public void runBuildAsync(String buildId, String projectId, BuildRequest request) {
        BuildStatus status = buildStatusMap.get(buildId);
        try {
            status.setStatusMessage("Fetching project details and screens...");
            status.getLogs().add("Fetching project data for project ID: " + projectId);
            ProjectEntity project = projectRepository.findById(projectId)
                    .orElseThrow(() -> new RuntimeException("Project not found with id: " + projectId));

            String flutterProjectRootPath = BASE_PROJECTS_FOLDER + "/" + projectId + "/" + project.getProjectName();
            Path libDirectory = Paths.get(flutterProjectRootPath, "lib");
            Files.createDirectories(libDirectory);

            status.setStatusMessage("Generating Dart files with AI...");
            status.getLogs().add("Starting AI code generation for " + project.getListOfScreens().size() + " screens.");
            List<Screen> screens = project.getListOfScreens();
            for (Screen screen : screens) {
                String prompt = createPromptForScreen(screen.getScreenCode(), request.getInstructions(), screen.getScreenName());
                String generatedDartCode = geminiAIService.generateContent(prompt);

                // *** MODIFIED: Clean the AI's response before using it ***
                String cleanedDartCode = cleanGeneratedCode(generatedDartCode);

                if (cleanedDartCode.startsWith("Error:")) {
                    throw new RuntimeException("AI generation failed for screen '" + screen.getScreenName() + "': " + cleanedDartCode);
                }

                screen.setScreenCode(cleanedDartCode);
                String dartFileName = toSnakeCase(screen.getScreenName()) + ".dart";
                Files.write(libDirectory.resolve(dartFileName), cleanedDartCode.getBytes(StandardCharsets.UTF_8));
                status.getLogs().add("Successfully generated file: " + dartFileName);
            }

            generateMainDartFile(libDirectory, screens, request.getInitialScreenIndex(), project.getProjectName());
            status.getLogs().add("Successfully generated main.dart.");

            status.setStatusMessage("Building APK with Flutter command...");
            runFlutterBuild(flutterProjectRootPath, status);

            status.setStatusMessage("Finalizing build and storing APK...");
            status.getLogs().add("Flutter build command completed. Locating APK...");
            Path generatedApkPath = findGeneratedApk(flutterProjectRootPath);
            Path finalApkPath = storeApk(generatedApkPath, buildId);
            status.getLogs().add("APK successfully stored at: " + finalApkPath);

            status.setStatusMessage("Build completed successfully.");
            status.setCompleted(true);
            status.setSuccess(true);
            status.setApkFilePath(finalApkPath.toString());

            project.setListOfScreens(screens);
            project.setLastBuildAt(LocalDateTime.now());
            project.setLastBuildVersion(buildId);
            project.setLastBuildLocation(finalApkPath.toString());
            projectRepository.save(project);

        } catch (Exception e) {
            status.setStatusMessage("Build failed.");
            status.setErrorMessage(e.getMessage());
            status.setCompleted(true);
            status.setSuccess(false);
            status.getLogs().add("ERROR: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // *** ADDED: Helper method to clean AI output ***
    private String cleanGeneratedCode(String rawCode) {
        if (rawCode == null) {
            return "";
        }
        // First, trim any leading/trailing whitespace.
        String cleanedCode = rawCode.trim();

        // Remove the starting markdown fence if it exists.
        if (cleanedCode.startsWith("```dart")) {
            cleanedCode = cleanedCode.substring(7).trim();
        } else if (cleanedCode.startsWith("dart")) {
            // Also handle the case where it just outputs "dart"
            cleanedCode = cleanedCode.substring(4).trim();
        }

        // Remove the closing markdown fence if it exists.
        if (cleanedCode.endsWith("```")) {
            cleanedCode = cleanedCode.substring(0, cleanedCode.length() - 3).trim();
        }

        return cleanedCode;
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
                status.setStatusMessage("Build in progress: " + line);
            }
        }

        boolean finished = process.waitFor(10, TimeUnit.MINUTES);
        if (!finished) {
            process.destroy();
            throw new RuntimeException("Flutter build timed out after 10 minutes.");
        }
        int exitCode = process.exitValue();
        if (exitCode != 0) {
            throw new RuntimeException("Flutter build command failed with exit code " + exitCode + ". Check logs for details.");
        }
    }

    private String createPromptForScreen(String originalCode, String instructions, String screenName) {
        // *** MODIFIED: Enhanced prompt to prevent formatting issues ***
        return String.format(
                "You are an expert Flutter/Dart developer. Your task is to take a piece of code and a set of instructions and generate a single, complete, production-ready Dart file.\n\n" +
                        "**INSTRUCTIONS**:\n%s\n\n" +
                        "**MODIFICATIONS REQUIRED**:\n" +
                        "1. Rename the main widget class in the base code to **exactly** match the screen name: `%s`.\n" +
                        "2. Ensure that the Dart annotation `@override` is always used with a lowercase 'o'. Do **not** use `@Override` (uppercase 'O') under any circumstance.\n\n" +
                        "**BASE CODE**:\n```dart\n%s\n```\n\n" +
                        "**CRITICAL**: Your entire response will be saved directly into a `.dart` file. It must be ONLY raw Dart code. Do not include any explanation, introductory text, or markdown code blocks like ```dart or ``` in your response. Your response must start directly with 'import' or 'class'.",
                instructions,
                screenName,
                originalCode
        );
    }

    private void generateMainDartFile(Path libDirectory, List<Screen> screens, int initialScreenIndex, String projectName) throws IOException {
        if (initialScreenIndex < 0 || initialScreenIndex >= screens.size()) {
            throw new IllegalArgumentException("Initial screen index is out of bounds.");
        }

        Screen initialScreen = screens.get(initialScreenIndex);
        String initialScreenFileName = toSnakeCase(initialScreen.getScreenName()) + ".dart";
        String initialScreenClassName = toPascalCase(initialScreen.getScreenName());

        String mainDartContent = String.format(
                "import 'package:flutter/material.dart';\n" +
                        "import '%s'; // Importing the initial screen\n\n" +
                        "void main() {\n" +
                        "  runApp(const MyApp());\n" +
                        "}\n\n" +
                        "class MyApp extends StatelessWidget {\n" +
                        "  const MyApp({super.key});\n\n" +
                        "  @override\n" +
                        "  Widget build(BuildContext context) {\n" +
                        "    return MaterialApp(\n" +
                        "      title: '%s',\n" +
                        "      theme: ThemeData(\n" +
                        "        primarySwatch: Colors.blue,\n" +
                        "        visualDensity: VisualDensity.adaptivePlatformDensity,\n" +
                        "      ),\n" +
                        "      home: const %s(), // Setting the initial screen class\n" +
                        "    );\n" +
                        "  }\n" +
                        "}",
                initialScreenFileName,
                projectName,
                initialScreenClassName
        );

        Path mainDartPath = libDirectory.resolve("main.dart");
        Files.write(mainDartPath, mainDartContent.getBytes(StandardCharsets.UTF_8));
    }

    private String toSnakeCase(String input) {
        if (input == null) return "";
        return input.replaceAll("([a-z])([A-Z]+)", "$1_$2").replaceAll("\\s+", "_").toLowerCase();
    }

    private String toPascalCase(String input) {
        if (input == null || input.isEmpty()) return "";
        StringBuilder pascalCase = new StringBuilder();
        for (String part : input.replaceAll("_", " ").split("\\s+")) {
            if (!part.isEmpty()) {
                pascalCase.append(Character.toUpperCase(part.charAt(0))).append(part.substring(1).toLowerCase());
            }
        }
        return pascalCase.toString();
    }

    private Path findGeneratedApk(String projectPath) {
        Path apkPath = Paths.get(projectPath, "build", "app", "outputs", "flutter-apk", "app-release.apk");
        if (!Files.exists(apkPath)) {
            throw new RuntimeException("Could not find the generated APK file at expected location: " + apkPath);
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
                throw new RuntimeException("Could not read the APK file from path: " + filePath);
            }
        } catch (MalformedURLException e) {
            throw new RuntimeException("Error creating resource for the APK file: " + e.getMessage(), e);
        }
    }
}