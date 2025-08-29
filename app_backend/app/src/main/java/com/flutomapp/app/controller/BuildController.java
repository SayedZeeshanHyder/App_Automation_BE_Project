package com.flutomapp.app.controller;

import com.flutomapp.app.httpmodels.BuildModels.BuildRequest;
import com.flutomapp.app.httpmodels.BuildModels.BuildStartResponse;
import com.flutomapp.app.httpmodels.BuildModels.BuildStatus;
import com.flutomapp.app.service.BuildService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("build")
@RequiredArgsConstructor
public class BuildController {
    private final BuildService buildService;

    @PostMapping("/{projectId}")
    public ResponseEntity<BuildStartResponse> triggerBuild(
            @PathVariable String projectId,
            @RequestBody BuildRequest buildRequest) {
        try {
            String buildId = buildService.startBuildProcess(projectId, buildRequest);
            BuildStartResponse response = new BuildStartResponse(buildId, "Build process started successfully.");
            // Return 202 ACCEPTED to indicate the request was accepted for processing
            return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new BuildStartResponse(null, "Failed to start build: " + e.getMessage()));
        }
    }

    @GetMapping("/status/{buildId}")
    public ResponseEntity<Map<String, Object>> getBuildStatus(@PathVariable String buildId) {
        BuildStatus status = buildService.getBuildStatus(buildId);
        if (status == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Build ID not found."));
        }

        Map<String, Object> response = new HashMap<>();
        response.put("buildId", status.getBuildId());
        response.put("buildStatus", status.getStatusMessage());
        response.put("completed", status.isCompleted());

        // This is the key change: include the live logs in the response
        response.put("logs", status.getLogs());

        if (status.isCompleted()) {
            response.put("success", status.isSuccess());
            if (!status.isSuccess()) {
                response.put("error", status.getErrorMessage());
            }
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{buildId}/download")
    public ResponseEntity<Resource> downloadApk(@PathVariable String buildId) {
        try {
            Resource resource = buildService.getApkResource(buildId);
            String contentType = "application/vnd.android.package-archive";
            String headerValue = "attachment; filename=\"" + buildId + ".apk\"";

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(HttpHeaders.CONTENT_DISPOSITION, headerValue)
                    .body(resource);
        } catch (RuntimeException e) {
            // Return a 404 Not Found with a clear message if the resource doesn't exist
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }
}