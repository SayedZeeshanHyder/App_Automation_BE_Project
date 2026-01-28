package com.flutomapp.app.service;

import com.flutomapp.app.constants.GeminiPrompts;
import com.flutomapp.app.dtomodel.OrganisationDto;
import com.flutomapp.app.dtomodel.ProjectEntityDto;
import com.flutomapp.app.httpmodels.ProjectCreationMetaResponse;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.ProjectEntity;
import com.flutomapp.app.repository.OrganisationRepository;
import com.flutomapp.app.repository.ProjectRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class ProjectCreationService {

    public final GeminiAIService geminiAIService;
    private final ProjectRepository projectRepository;
    private final OrganisationRepository organisationRepository;

    @Value("${projects.base.dir:projects}")
    public String baseProjectsDir;

    public ProjectCreationService(GeminiAIService geminiAIService, ProjectRepository projectRepository, OrganisationRepository organisationRepository) {
        this.geminiAIService = geminiAIService;
        this.projectRepository = projectRepository;
        this.organisationRepository = organisationRepository;
    }

    public ProjectCreationMetaResponse createProjectMetaOnly(
            String projectName,
            String organisationName,
            String description,
            List<String> envKeys,
            List<String> envValues,
            boolean requireFirebase,
            MultipartFile googleServicesJson,
            List<String> androidPermissions,
            MultipartFile appIcon,
            OrganisationEntity organisation
    ) {
        long start = System.currentTimeMillis();
        String uniqueId = UUID.randomUUID().toString();
        Path projectRootPath = Paths.get(baseProjectsDir, uniqueId);

        boolean envConfigured = false;
        boolean permissionsConfigured = false;
        boolean firebaseConfigured = false;
        boolean appIconConfigured = false;

        try {
            Files.createDirectories(projectRootPath);
            runFlutterCreate(projectName, organisationName, description, projectRootPath);
            Path flutterProjectDir = projectRootPath.resolve(projectName);
            Files.createDirectories(flutterProjectDir.resolve("assets"));

            Map<String, String> envMap = buildEnvMap(envKeys, envValues);
            if (envMap != null && !envMap.isEmpty()) {
                try {
                    configureDotEnv(envMap, flutterProjectDir);
                    envConfigured = true;
                } catch (Exception e) {
                    System.err.println("Error configuring .env: " + e.getMessage());
                }
            }

            if (androidPermissions != null && !androidPermissions.isEmpty()) {
                try {
                    configureAndroidPermissions(androidPermissions, flutterProjectDir);
                    permissionsConfigured = true;
                } catch (Exception e) {
                    System.err.println("Error configuring Android permissions: " + e.getMessage());
                }
            }

            if (appIcon != null && !appIcon.isEmpty()) {
                try {
                    configureAppIcon(appIcon, flutterProjectDir);
                    appIconConfigured = true;
                } catch (Exception e) {
                    System.err.println("Error configuring app icon: " + e.getMessage());
                }
            }

            if (requireFirebase && googleServicesJson != null && !googleServicesJson.isEmpty()) {
                try {
                    if (checkProjectPackageMatchesGoogleServices(googleServicesJson, flutterProjectDir)) {
                        configureFirebase(googleServicesJson, flutterProjectDir);
                        firebaseConfigured = true;
                    } else {
                        System.err.println("Firebase setup skipped: Google Services JSON package name does not match project's applicationId.");
                    }
                } catch (Exception e) {
                    System.err.println("Error configuring Firebase: " + e.getMessage());
                }
            }

            long end = System.currentTimeMillis();
            ProjectEntity project = new ProjectEntity();
            project.setId(uniqueId);
            project.setOrganisation(organisation);
            project.setStatus("Created");
            project.setProjectName(projectName);

            // --- CORRECTED SECTION ---
            // This block now safely handles cases where envKeys is null or empty.
            if (envKeys != null && !envKeys.isEmpty()) {
                project.setEnvVariables(IntStream.range(0, envKeys.size())
                        .mapToObj(i -> Map.of(envKeys.get(i), envValues.get(i)))
                        .collect(Collectors.toList()));
            } else {
                project.setEnvVariables(new ArrayList<>()); // Assign an empty list if no keys are provided.
            }
            // --- END OF CORRECTION ---

            project.setFirebaseConfigured(firebaseConfigured);
            project.setAppIcon("");
            project.setAndroidPermissions(androidPermissions);
            ProjectEntity savedProject = projectRepository.save(project);
            List<ProjectEntity> projects = organisation.getProjects();
            projects.add(savedProject);
            organisation.setProjects(projects);
            organisationRepository.save(organisation);
            return new ProjectCreationMetaResponse(
                    new OrganisationDto(organisation),
                    new ProjectEntityDto(savedProject), end - start,
                    envConfigured, permissionsConfigured, firebaseConfigured, appIconConfigured
            );
        } catch (Exception ex) {
            throw new RuntimeException("Project creation failed: " + ex.getMessage(), ex);
        }
    }

    private String sanitizeGeminiResponse(String response) {
        if (response == null) return "";
        // 1. Remove markdown code fences (e.g., ```yaml ... ```)
        String sanitized = response.replaceAll("(?s)```[a-zA-Z]*\n(.*?)\n```", "$1").trim();
        // 2. Remove common leading keywords (case-insensitive) followed by a newline.
        // This is the key fix for the 'xml' and 'yaml' prefixes.
        sanitized = sanitized.replaceAll("^(?i)(xml|yaml|json|dart|groovy|kotlin|java|text)\\s*\\r?\\n", "").trim();
        return sanitized;
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

    private void runFlutterCreate(String projectName, String orgName, String description, Path rootPath) throws Exception {
        try {
            List<String> command = Arrays.asList(
                    "C:\\Users\\zhyde\\OneDrive\\Desktop\\Zeeshan\\fluttersdk\\flutter_windows_3.19.4-stable\\flutter\\bin\\flutter.bat", "create",
                    "--org", orgName,
                    "--project-name", projectName,
                    "--description", description,
                    projectName
            );
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(rootPath.toFile());
            pb.redirectErrorStream(true);
            Process process = pb.start();
            process.waitFor();
        }catch (Exception e){
            System.out.println("Error running flutter create: " + e.getMessage());
            System.err.println("Error running flutter create: " + e.getMessage());
        }
    }

    private void configureDotEnv(Map<String, String> env, Path projectPath) throws IOException {
        Path envFile = projectPath.resolve(".env");
        try (BufferedWriter writer = Files.newBufferedWriter(envFile, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING)) {
            for (Map.Entry<String, String> entry : env.entrySet()) {
                writer.write(entry.getKey() + "=" + entry.getValue());
                writer.newLine();
            }
        }
        Path pubspecPath = projectPath.resolve("pubspec.yaml");
        String yamlFile = new String(Files.readAllBytes(pubspecPath));
        String newYamlResponse = geminiAIService.generateContent(
                GeminiPrompts.DOTENV_PUBSPEC_PROMPT.replace("${yaml}", yamlFile));
        Files.write(pubspecPath, sanitizeGeminiResponse(newYamlResponse).getBytes());

        Path mainFile = projectPath.resolve("lib").resolve("main.dart");
        String mainContent = new String(Files.readAllBytes(mainFile));
        String newMainResponse = geminiAIService.generateContent(
                GeminiPrompts.MAIN_DOTENV_PROMPT.replace("${main}", mainContent));
        Files.write(mainFile, sanitizeGeminiResponse(newMainResponse).getBytes());
    }

    private void configureAndroidPermissions(List<String> permissions, Path projectPath) throws IOException {
        Path manifestPath = projectPath.resolve("android/app/src/main/AndroidManifest.xml");
        String originalManifest = new String(Files.readAllBytes(manifestPath));
        String newManifestResponse = geminiAIService.generateContent(
                GeminiPrompts.ANDROID_PERMISSIONS_PROMPT
                        .replace("${manifest}", originalManifest)
                        .replace("${permissions}", String.join("\n", permissions))
        );
        Files.write(manifestPath, sanitizeGeminiResponse(newManifestResponse).getBytes());

        Path pubspecPath = projectPath.resolve("pubspec.yaml");
        String yamlContent = new String(Files.readAllBytes(pubspecPath));
        String newYamlResponse = geminiAIService.generateContent(
                GeminiPrompts.PERM_HANDLER_PUBSPEC_PROMPT.replace("${yaml}", yamlContent));
        Files.write(pubspecPath, sanitizeGeminiResponse(newYamlResponse).getBytes());
    }

    private void configureAppIcon(MultipartFile appIcon, Path projectPath) throws Exception {
        String originalFileName = Objects.requireNonNull(appIcon.getOriginalFilename());
        // Ensure extension is preserved, default to .png if none
        String extension = originalFileName.contains(".") ?
                originalFileName.substring(originalFileName.lastIndexOf('.')) : ".png";
        String iconFileName = "app_icon" + extension;
        Path iconPath = projectPath.resolve("assets").resolve(iconFileName);

        // Ensure assets directory exists
        Files.createDirectories(projectPath.resolve("assets"));
        Files.copy(appIcon.getInputStream(), iconPath, StandardCopyOption.REPLACE_EXISTING);

        Path pubspecPath = projectPath.resolve("pubspec.yaml");
        String yamlContent = new String(Files.readAllBytes(pubspecPath));

        // Using the new, more robust prompt
        String newYamlResponse = geminiAIService.generateContent(
                GeminiPrompts.FLUTTER_LAUNCHER_ICON_PROMPT
                        .replace("${yaml}", yamlContent)
                        .replace("${iconPath}", "assets/" + iconFileName)); // Use relative path

        Files.write(pubspecPath, sanitizeGeminiResponse(newYamlResponse).getBytes());
        runFlutterLauncherIcons(projectPath);
    }

    private void runFlutterLauncherIcons(Path projectPath) throws Exception {
        List<String> cmd = Arrays.asList("C:\\Users\\zhyde\\OneDrive\\Desktop\\Zeeshan\\fluttersdk\\flutter_windows_3.19.4-stable\\flutter\\bin\\flutter.bat", "run", "flutter_launcher_icons");
        ProcessBuilder pb = new ProcessBuilder(cmd);
        pb.directory(projectPath.toFile());
        pb.redirectErrorStream(true);
        Process p = pb.start();
        p.waitFor();
    }

    private void configureFirebase(MultipartFile googleServices, Path projectPath) throws IOException {
        Path gsJsonPath = projectPath.resolve("android/app/google-services.json");
        Files.copy(googleServices.getInputStream(), gsJsonPath, StandardCopyOption.REPLACE_EXISTING);

        // --- DYNAMICALLY CONFIGURE GRADLE FILES ---

        // 1. Configure Root Gradle File
        Path rootGradlePath = findGradleFile(projectPath.resolve("android"), "build");
        if (rootGradlePath != null) {
            String rootGradleContent = new String(Files.readAllBytes(rootGradlePath));
            String prompt = rootGradlePath.toString().endsWith(".kts")
                    ? GeminiPrompts.FIREBASE_ROOT_GRADLE_KTS_PROMPT
                    : GeminiPrompts.FIREBASE_ROOT_GRADLE_PROMPT;

            String newRootGradleResponse = geminiAIService.generateContent(
                    prompt.replace("${gradle}", rootGradleContent));
            Files.write(rootGradlePath, sanitizeGeminiResponse(newRootGradleResponse).getBytes());
        } else {
            System.err.println("Warning: Root build.gradle or build.gradle.kts not found.");
        }

        // 2. Configure App-level Gradle File
        Path appGradlePath = findGradleFile(projectPath.resolve("android/app"), "build");
        if (appGradlePath != null) {
            String appGradleContent = new String(Files.readAllBytes(appGradlePath));
            String prompt = appGradlePath.toString().endsWith(".kts")
                    ? GeminiPrompts.FIREBASE_APP_GRADLE_KTS_PROMPT
                    : GeminiPrompts.FIREBASE_APP_GRADLE_PROMPT;

            String newAppGradleResponse = geminiAIService.generateContent(
                    prompt.replace("${gradle}", appGradleContent));
            Files.write(appGradlePath, sanitizeGeminiResponse(newAppGradleResponse).getBytes());
        } else {
            System.err.println("Warning: App-level build.gradle or build.gradle.kts not found.");
        }


        // --- Configure pubspec.yaml and main.dart (no changes here) ---
        Path pubspecPath = projectPath.resolve("pubspec.yaml");
        String yamlContent = new String(Files.readAllBytes(pubspecPath));
        String newYamlResponse = geminiAIService.generateContent(
                GeminiPrompts.FIREBASE_PUBSPEC_PROMPT.replace("${yaml}", yamlContent));
        Files.write(pubspecPath, sanitizeGeminiResponse(newYamlResponse).getBytes());

        Path mainFile = projectPath.resolve("lib").resolve("main.dart");
        String mainContent = new String(Files.readAllBytes(mainFile));
        String newMainResponse = geminiAIService.generateContent(
                GeminiPrompts.FIREBASE_MAIN_PROMPT.replace("${main}", mainContent));
        Files.write(mainFile, sanitizeGeminiResponse(newMainResponse).getBytes());
    }

    private Path findGradleFile(Path directory, String baseName) {
        Path groovyFile = directory.resolve(baseName + ".gradle");
        if (Files.exists(groovyFile)) {
            return groovyFile;
        }
        Path kotlinFile = directory.resolve(baseName + ".gradle.kts");
        if (Files.exists(kotlinFile)) {
            return kotlinFile;
        }
        return null; // Neither file found
    }

    private boolean checkProjectPackageMatchesGoogleServices(MultipartFile googleServices, Path projectPath) {
        try {
            // 1. Extract package name from google-services.json
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(googleServices.getInputStream());
            String googleJsonPackage = root.path("client").get(0)
                    .path("client_info")
                    .path("android_client_info")
                    .path("package_name").asText(null);

            if (googleJsonPackage == null) {
                System.err.println("Could not find 'package_name' in google-services.json");
                return false;
            }

            // 2. Extract applicationId from build.gradle or build.gradle.kts
            String gradlePackage = extractApplicationIdFromGradle(projectPath);

            if (gradlePackage == null) {
                System.err.println("Could not find 'applicationId' in app-level build.gradle file.");
                return false;
            }

            System.out.println("Comparing packages -> JSON: " + googleJsonPackage + ", Gradle: " + gradlePackage);
            return googleJsonPackage.equals(gradlePackage);

        } catch (IOException e) {
            System.err.println("Failed to read or parse files for package name validation: " + e.getMessage());
            return false;
        }
    }

    private String extractApplicationIdFromGradle(Path projectPath) throws IOException {
        Path gradlePath = projectPath.resolve("android/app/build.gradle");
        if (!Files.exists(gradlePath)) {
            gradlePath = projectPath.resolve("android/app/build.gradle.kts");
            if (!Files.exists(gradlePath)) return null;
        }

        String content = new String(Files.readAllBytes(gradlePath));
        // Regex to find 'applicationId "com.example.app"' or 'applicationId = "com.example.app"'
        Pattern pattern = Pattern.compile("applicationId\\s*[=]?\\s*[\"']([^\"']+)[\"']");
        Matcher matcher = pattern.matcher(content);

        if (matcher.find()) {
            return matcher.group(1);
        }
        return null;
    }

    public void zipFolder(Path sourceFolderPath, Path zipPath) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(zipPath.toFile());
             BufferedOutputStream bos = new BufferedOutputStream(fos);
             ZipOutputStream zos = new ZipOutputStream(bos)) {
            Files.walk(sourceFolderPath)
                    .filter(path -> !Files.isDirectory(path))
                    .forEach(path -> {
                        ZipEntry zipEntry = new ZipEntry(sourceFolderPath.relativize(path).toString().replace("\\", "/"));
                        try {
                            zos.putNextEntry(zipEntry);
                            Files.copy(path, zos);
                            zos.closeEntry();
                        } catch (IOException e) {
                            throw new UncheckedIOException(e);
                        }
                    });
        }
    }
}