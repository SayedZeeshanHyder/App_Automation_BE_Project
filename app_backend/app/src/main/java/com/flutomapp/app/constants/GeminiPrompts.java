package com.flutomapp.app.constants;

public class GeminiPrompts {

    public static final String DOTENV_PUBSPEC_PROMPT =
            "Task: Update the provided pubspec.yaml content.\n"
                    + "Instructions:\n"
                    + "1. Add 'flutter_dotenv: ^5.1.0' under the 'dependencies' section. If it already exists, ensure it is present.\n"
                    + "2. Add the '.env' file to the 'assets' section under 'flutter'. If the assets section doesn't exist, create it.\n"
                    + "3. Maintain perfect YAML indentation and structure.\n"
                    + "Your response MUST be ONLY the complete, updated pubspec.yaml file content. Do not include any explanations, comments, or markdown code fences (```).\n\n"
                    + "${yaml}";

    public static final String MAIN_DOTENV_PROMPT =
            "Task: Modify the provided main.dart file to initialize flutter_dotenv.\n"
                    + "Instructions:\n"
                    + "1. Add the import statement: `import 'package:flutter_dotenv/flutter_dotenv.dart';`.\n"
                    + "2. Convert `void main()` to `Future<void> main() async`.\n"
                    + "3. Add `await dotenv.load(fileName: \".env\");` inside `main()` before `runApp()`.\n"
                    + "Your response MUST be ONLY the complete, modified main.dart source code. Do not output any other text, comments, or markdown formatting.\n\n"
                    + "${main}";

    public static final String ANDROID_PERMISSIONS_PROMPT =
            "Task: Add Android permissions to the AndroidManifest.xml file.\n"
                    + "Instructions:\n"
                    + "1. Add each of the following permissions as a `<uses-permission android:name=\"...\" />` tag inside the `<manifest>` tag, but before the `<application>` tag.\n"
                    + "2. Do not add permissions that already exist.\n"
                    + "3. The XML must remain well-formed.\n"
                    + "Permissions to add:\n${permissions}\n"
                    + "Your response MUST be ONLY the full, updated AndroidManifest.xml content. Do not include any explanations or markdown.\n\n"
                    + "${manifest}";

    public static final String PERM_HANDLER_PUBSPEC_PROMPT =
            "Task: Update the pubspec.yaml to include the permission_handler package.\n"
                    + "Instructions:\n"
                    + "1. Add 'permission_handler: ^11.0.1' under the 'dependencies' section.\n"
                    + "2. Do not add it if it already exists.\n"
                    + "3. Preserve all existing content and maintain correct YAML formatting.\n"
                    + "Your response MUST be ONLY the complete, updated pubspec.yaml content. No explanations, no markdown.\n\n"
                    + "${yaml}";

    public static final String FIREBASE_PUBSPEC_PROMPT =
            "Task: Add the firebase_core dependency to pubspec.yaml.\n"
                    + "Instructions:\n"
                    + "1. Add 'firebase_core: ^3.0.0' under the 'dependencies' section.\n"
                    + "2. Do not add if it already exists.\n"
                    + "3. Preserve all existing content and maintain correct YAML formatting.\n"
                    + "Your response MUST be ONLY the complete, updated pubspec.yaml content. No extra text allowed.\n\n"
                    + "${yaml}";

    public static final String FIREBASE_MAIN_PROMPT =
            "Task: Modify the main.dart file to initialize Firebase.\n"
                    + "Instructions:\n"
                    + "1. Add the import: `import 'package:firebase_core/firebase_core.dart';`.\n"
                    + "2. Convert `void main()` to `Future<void> main() async`.\n"
                    + "3. At the beginning of `main`, add `WidgetsFlutterBinding.ensureInitialized();`.\n"
                    + "4. After that, add `await Firebase.initializeApp();`.\n"
                    + "Your response MUST be ONLY the complete, modified main.dart source code. Do not output anything else.\n\n"
                    + "${main}";

    public static final String FIREBASE_ROOT_GRADLE_KTS_PROMPT =
            "Task: Update the Android project-level build.gradle.kts file for Firebase.\n"
                    + "Instructions:\n"
                    + "1. In the `plugins { ... }` block, add the Google Services plugin: `alias(libs.plugins.google.gms.google.services) apply false`.\n"
                    + "2. Do not add it if it's already present. Do not modify other plugins.\n"
                    + "Your response MUST be ONLY the complete, updated build.gradle.kts file content. No explanations, no comments, no markdown.\n\n"
                    + "${gradle}";

    public static final String FIREBASE_APP_GRADLE_KTS_PROMPT =
            "Task: Update the Android app-level build.gradle.kts file for Firebase.\n"
                    + "Instructions:\n"
                    + "1. In the `plugins { ... }` block at the top, add the Google Services plugin alias: `alias(libs.plugins.google.gms.google.services)`.\n"
                    + "2. In the `dependencies { ... }` block, add the Firebase Bill of Materials (BoM): `implementation(platform(libs.firebase.bom))`.\n"
                    + "3. Also in dependencies, add the dependency for Firebase Analytics: `implementation(libs.firebase.analytics)`.\n"
                    + "Your response MUST be ONLY the complete, updated build.gradle.kts file content. No explanations, no comments, no markdown.\n\n"
                    + "${gradle}";


    public static final String FIREBASE_ROOT_GRADLE_PROMPT =
            "Task: Update the Android project-level build.gradle file for Firebase.\n"
                    + "Instructions:\n"
                    + "1. In the 'buildscript { dependencies { ... } }' block, add the Google Services classpath: `classpath 'com.google.gms:google-services:4.4.1'`.\n"
                    + "2. Do not add it if it's already present. Do not modify other classpaths.\n"
                    + "Your response MUST be ONLY the complete, updated build.gradle file content. No explanations, no comments, no markdown.\n\n"
                    + "${gradle}";

    public static final String FIREBASE_APP_GRADLE_PROMPT =
            "Task: Update the Android app-level build.gradle file for Firebase.\n"
                    + "Instructions:\n"
                    + "1. Apply the Google Services plugin at the very top: `apply plugin: 'com.google.gms.google-services'`.\n"
                    + "2. In the 'dependencies { ... }' block, add the Firebase Bill of Materials (BoM): `implementation platform('com.google.firebase:firebase-bom:33.1.2')`.\n"
                    + "3. Add the dependency for Firebase Analytics: `implementation 'com.google.firebase:firebase-analytics'`.\n"
                    + "Your response MUST be ONLY the complete, updated build.gradle file content. No explanations, no comments, no markdown.\n\n"
                    + "${gradle}";

    public static final String FLUTTER_LAUNCHER_ICON_PROMPT =
            "Task: Fully configure an app icon in pubspec.yaml.\n"
                    + "Instructions:\n"
                    + "1. In 'dev_dependencies', ensure 'flutter_launcher_icons: ^0.13.1' is present. Add it if it's missing.\n"
                    + "2. Under the main 'flutter' key, ensure the 'assets' list contains the directory entry '- assets/'. You MUST add this entry to the list. Do NOT remove any existing asset entries like '.env'. If the 'assets' section doesn't exist, create it.\n"
                    + "3. Add or update the root-level 'flutter_launcher_icons' configuration block. Set its 'image_path' to '${iconPath}'.\n"
                    + "Your final output MUST BE ONLY the complete, valid, and clean pubspec.yaml content. DO NOT include the word 'yaml', markdown fences (```), or any other explanatory text.\n\n"
                    + "Original pubspec.yaml:\n${yaml}";
}