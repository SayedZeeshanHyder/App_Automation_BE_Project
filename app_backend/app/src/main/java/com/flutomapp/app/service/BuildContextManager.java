package com.flutomapp.app.service;

import com.flutomapp.app.dtomodel.Screen;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class BuildContextManager {

    private final List<Map<String, String>> conversationHistory = new ArrayList<>();
    private final List<GeneratedScreenRecord> generatedScreens = new ArrayList<>();
    private String projectName;
    private String generalInstructions;
    private int totalScreens;

    // Thresholds for context window optimization
    private static final int MAX_FULL_CODE_SCREENS = 3;
    private static final int SUMMARIZATION_THRESHOLD = 4;

    public void initialize(String projectName, String instructions, int totalScreens, List<Screen> allScreens) {
        this.projectName = projectName;
        this.generalInstructions = instructions;
        this.totalScreens = totalScreens;

        StringBuilder screenOverview = new StringBuilder();
        screenOverview.append("You are an expert Flutter/Dart developer. You are building the project '")
                .append(projectName).append("' which has ").append(totalScreens).append(" screens.\n\n");
        screenOverview.append("General Instructions: ").append(instructions).append("\n\n");
        screenOverview.append("**Complete Screen Manifest (all screens that will be generated):**\n");
        for (int i = 0; i < allScreens.size(); i++) {
            Screen s = allScreens.get(i);
            screenOverview.append(String.format("  %d. %s — %s\n", i + 1, s.getScreenName(),
                    (s.getScreenPrompt() != null && !s.getScreenPrompt().isBlank()) ? s.getScreenPrompt() : "No description"));
        }
        screenOverview.append("\nYou will generate these screens one by one. Each screen MUST be consistent with all previously generated screens. ");
        screenOverview.append("If you reference another screen's class, use the exact class name from the manifest. ");
        screenOverview.append("Always use `@override` (lowercase 'o'). Always produce production-ready Dart with no markdown fences.");

        addToHistory("user", screenOverview.toString());
        addToHistory("model",
                "Understood. I will generate each screen for project '" + projectName +
                        "' maintaining full consistency across all screens. I will use exact class names from the manifest, " +
                        "lowercase @override, and produce clean Dart code without markdown fences.");
    }

    /**
     * Builds the optimized context to send to the AI for generating the screen at the given index.
     *
     * Strategy:
     *   - Always include the initialization messages (system prompt).
     *   - For screens beyond SUMMARIZATION_THRESHOLD, include a consolidated summary of older screens
     *     plus the full code of the most recent MAX_FULL_CODE_SCREENS screens.
     *   - For screens within the threshold, include full code of all prior screens.
     */
    public List<Map<String, String>> getContextForScreen(int screenIndex) {
        List<Map<String, String>> context = new ArrayList<>();

        // Always include initialization (first two messages)
        if (conversationHistory.size() >= 2) {
            context.add(conversationHistory.get(0));
            context.add(conversationHistory.get(1));
        }

        if (screenIndex < SUMMARIZATION_THRESHOLD) {
            // Small number of screens — include full code for all prior screens
            for (GeneratedScreenRecord record : generatedScreens) {
                context.add(createMessage("user",
                        "Here is the complete generated code for screen '" + record.screenName +
                                "' (file: " + record.fileName + "):\n\n" + record.code));
                context.add(createMessage("model",
                        "Noted. I have recorded the code for '" + record.screenName + "' and will maintain consistency."));
            }
        } else {
            // Many screens — summarize older ones, include full code for recent ones
            int recentStart = Math.max(0, generatedScreens.size() - MAX_FULL_CODE_SCREENS);

            // Consolidated summary for older screens
            if (recentStart > 0) {
                String summary = createConsolidatedSummary(recentStart);
                context.add(createMessage("user", summary));
                context.add(createMessage("model",
                        "Understood. I have the summary of all older screens and will maintain consistency with their patterns, " +
                                "navigation routes, shared widgets, and theming."));
            }

            // Full code for recent screens
            for (int i = recentStart; i < generatedScreens.size(); i++) {
                GeneratedScreenRecord record = generatedScreens.get(i);
                context.add(createMessage("user",
                        "Here is the complete generated code for recent screen '" + record.screenName +
                                "' (file: " + record.fileName + "):\n\n" + record.code));
                context.add(createMessage("model",
                        "Noted. I have the full code for '" + record.screenName + "'."));
            }
        }

        return context;
    }

    /**
     * After a screen is generated, register it in the context manager.
     */
    public void addGeneratedScreen(Screen screen, String fileName, String code) {
        GeneratedScreenRecord record = new GeneratedScreenRecord(
                screen.getScreenName(),
                fileName,
                code,
                extractExports(code),
                extractImports(code),
                extractNavigationTargets(code)
        );
        generatedScreens.add(record);
    }

    /**
     * Updates a previously generated screen's code (after back-patching).
     */
    public void updateGeneratedScreen(int index, String newCode) {
        if (index >= 0 && index < generatedScreens.size()) {
            GeneratedScreenRecord old = generatedScreens.get(index);
            generatedScreens.set(index, new GeneratedScreenRecord(
                    old.screenName, old.fileName, newCode,
                    extractExports(newCode), extractImports(newCode), extractNavigationTargets(newCode)
            ));
        }
    }

    /**
     * Detects which previously generated screens need back-patching based on the
     * newly generated screen's code. Returns a list of indices into generatedScreens.
     *
     * Back-patch triggers:
     *   1. The new screen exports a class/function that a previous screen tried to import but couldn't.
     *   2. The new screen navigates TO a previous screen using a class name that doesn't match.
     *   3. A previous screen navigates to the new screen but used a wrong/placeholder import.
     *   4. The new screen defines a shared model/widget that previous screens should use.
     */
    public List<BackpatchRequest> detectBackpatchNeeds(int newScreenIndex) {
        List<BackpatchRequest> requests = new ArrayList<>();
        if (newScreenIndex >= generatedScreens.size()) return requests;

        GeneratedScreenRecord newScreen = generatedScreens.get(newScreenIndex);

        for (int i = 0; i < newScreenIndex; i++) {
            GeneratedScreenRecord prevScreen = generatedScreens.get(i);
            List<String> reasons = new ArrayList<>();

            // Check if any previous screen navigates to the new screen by class name
            // but doesn't import the new screen's file
            if (prevScreen.navigationTargets.contains(newScreen.screenName)) {
                String expectedImport = "import '" + newScreen.fileName + "'";
                boolean hasImport = prevScreen.code.contains(newScreen.fileName);
                if (!hasImport) {
                    reasons.add("Screen '" + prevScreen.screenName + "' navigates to '" +
                            newScreen.screenName + "' but is missing import for '" + newScreen.fileName + "'.");
                }
            }

            // Check if previous screen references the new screen's class name anywhere
            // (e.g., in a route map, a button callback, etc.) without the import
            if (prevScreen.code.contains(newScreen.screenName) && !prevScreen.code.contains(newScreen.fileName)) {
                reasons.add("Screen '" + prevScreen.screenName + "' references class '" +
                        newScreen.screenName + "' but doesn't import '" + newScreen.fileName + "'.");
            }

            // Check if new screen introduces a shared widget/model that previous screens could benefit from
            // This is detected by looking for TODO or placeholder comments referencing the new screen
            if (prevScreen.code.contains("// TODO") && prevScreen.code.contains(newScreen.screenName)) {
                reasons.add("Screen '" + prevScreen.screenName + "' has TODO comments referencing '" +
                        newScreen.screenName + "'.");
            }

            if (!reasons.isEmpty()) {
                requests.add(new BackpatchRequest(i, prevScreen.screenName, prevScreen.fileName, reasons));
            }
        }

        return requests;
    }

    /**
     * Builds the AI prompt context for back-patching a specific screen.
     */
    public List<Map<String, String>> getContextForBackpatch(int screenToFixIndex, int triggeringScreenIndex, List<String> reasons) {
        List<Map<String, String>> context = new ArrayList<>();

        // Include initialization
        if (conversationHistory.size() >= 2) {
            context.add(conversationHistory.get(0));
            context.add(conversationHistory.get(1));
        }

        GeneratedScreenRecord screenToFix = generatedScreens.get(screenToFixIndex);
        GeneratedScreenRecord triggeringScreen = generatedScreens.get(triggeringScreenIndex);

        // Provide the triggering screen's code
        context.add(createMessage("user",
                "I just generated a new screen '" + triggeringScreen.screenName +
                        "' (file: " + triggeringScreen.fileName + ") with this code:\n\n" + triggeringScreen.code));
        context.add(createMessage("model", "Noted."));

        // Provide the screen that needs fixing
        context.add(createMessage("user",
                "Now I need to update a previously generated screen '" + screenToFix.screenName +
                        "' (file: " + screenToFix.fileName + ") because of these issues:\n" +
                        String.join("\n", reasons) +
                        "\n\nHere is the current code for '" + screenToFix.screenName + "':\n\n" + screenToFix.code));

        return context;
    }

    /**
     * Builds the context for generating main.dart.
     */
    public List<Map<String, String>> getContextForMainDart() {
        List<Map<String, String>> context = new ArrayList<>();

        if (conversationHistory.size() >= 2) {
            context.add(conversationHistory.get(0));
            context.add(conversationHistory.get(1));
        }

        StringBuilder allScreens = new StringBuilder();
        allScreens.append("**All Generated Screens (with file names and key exports):**\n\n");
        for (GeneratedScreenRecord record : generatedScreens) {
            allScreens.append("- ").append(record.screenName)
                    .append(" (").append(record.fileName).append(")")
                    .append(" — exports: ").append(record.exports)
                    .append("\n");
        }

        context.add(createMessage("user", allScreens.toString()));
        context.add(createMessage("model", "I have the complete list of all screens and their files."));

        return context;
    }

    // ===== Helper Methods =====

    private void addToHistory(String role, String text) {
        conversationHistory.add(createMessage(role, text));
    }

    private Map<String, String> createMessage(String role, String text) {
        Map<String, String> msg = new HashMap<>();
        msg.put("role", role);
        msg.put("text", text);
        return msg;
    }

    private String createConsolidatedSummary(int upToIndex) {
        StringBuilder summary = new StringBuilder();
        summary.append("**Consolidated Summary of Screens 1 through ").append(upToIndex).append(":**\n\n");

        for (int i = 0; i < upToIndex; i++) {
            GeneratedScreenRecord r = generatedScreens.get(i);
            summary.append(String.format("%d. **%s** (%s)\n", i + 1, r.screenName, r.fileName));
            summary.append("   Exports: ").append(r.exports).append("\n");
            summary.append("   Imports: ").append(r.imports).append("\n");
            summary.append("   Navigates to: ").append(r.navigationTargets).append("\n");
            // Include a compact code signature (first 20 lines)
            String[] lines = r.code.split("\n");
            summary.append("   Code signature (imports + class declaration):\n");
            int lineCount = 0;
            for (String line : lines) {
                if (line.trim().startsWith("import ") || line.trim().startsWith("class ") ||
                        line.trim().startsWith("enum ") || line.trim().isEmpty()) {
                    summary.append("     ").append(line.trim()).append("\n");
                    lineCount++;
                }
                if (lineCount > 15) break;
            }
            summary.append("\n");
        }

        return summary.toString();
    }

    private List<String> extractExports(String code) {
        List<String> exports = new ArrayList<>();
        Pattern classPattern = Pattern.compile("class\\s+(\\w+)");
        Matcher matcher = classPattern.matcher(code);
        while (matcher.find()) {
            exports.add(matcher.group(1));
        }
        Pattern enumPattern = Pattern.compile("enum\\s+(\\w+)");
        matcher = enumPattern.matcher(code);
        while (matcher.find()) {
            exports.add(matcher.group(1));
        }
        return exports;
    }

    private List<String> extractImports(String code) {
        List<String> imports = new ArrayList<>();
        String[] lines = code.split("\n");
        for (String line : lines) {
            if (line.trim().startsWith("import ")) {
                imports.add(line.trim());
            }
        }
        return imports;
    }

    private List<String> extractNavigationTargets(String code) {
        List<String> targets = new ArrayList<>();
        // Match Navigator.push patterns with class constructors like MyScreen()
        Pattern navPattern = Pattern.compile("Navigator\\.[a-zA-Z]+\\([^)]*?\\b(\\w+)\\s*\\(");
        Matcher matcher = navPattern.matcher(code);
        while (matcher.find()) {
            String target = matcher.group(1);
            if (!target.equals("MaterialPageRoute") && !target.equals("CupertinoPageRoute") && !target.equals("context")) {
                targets.add(target);
            }
        }
        return targets;
    }

    // ===== Inner Classes =====

    public static class GeneratedScreenRecord {
        public final String screenName;
        public final String fileName;
        public final String code;
        public final List<String> exports;
        public final List<String> imports;
        public final List<String> navigationTargets;

        public GeneratedScreenRecord(String screenName, String fileName, String code,
                                     List<String> exports, List<String> imports, List<String> navigationTargets) {
            this.screenName = screenName;
            this.fileName = fileName;
            this.code = code;
            this.exports = exports;
            this.imports = imports;
            this.navigationTargets = navigationTargets;
        }
    }

    public static class BackpatchRequest {
        public final int screenIndex;
        public final String screenName;
        public final String fileName;
        public final List<String> reasons;

        public BackpatchRequest(int screenIndex, String screenName, String fileName, List<String> reasons) {
            this.screenIndex = screenIndex;
            this.screenName = screenName;
            this.fileName = fileName;
            this.reasons = reasons;
        }
    }
}
