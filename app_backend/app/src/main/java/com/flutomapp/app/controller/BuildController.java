package com.flutomapp.app.controller;

import com.flutomapp.app.dtomodel.BuildDto;
import com.flutomapp.app.httpmodels.BuildModels.BuildRequest;
import com.flutomapp.app.httpmodels.BuildModels.BuildStartResponse;
import com.flutomapp.app.httpmodels.BuildModels.BuildStatus;
import com.flutomapp.app.model.BuildEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.service.BuildService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("build")
@RequiredArgsConstructor
public class BuildController {
    private final BuildService buildService;

    @PostMapping("/{projectId}")
    public ResponseEntity<BuildStartResponse> triggerBuild(
            @PathVariable String projectId,
            @RequestBody BuildRequest buildRequest,
            @AuthenticationPrincipal UserEntity user) {
        try {
            String buildId = buildService.startBuildProcess(projectId, buildRequest, user);
            BuildStartResponse response = new BuildStartResponse(buildId, "Build process started successfully.");
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
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    @GetMapping("/organisation")
    public ResponseEntity<List<BuildDto>> getBuildsByOrganisation(
            @AuthenticationPrincipal UserEntity user) {
        try {
            if (user.getOrganisation() == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
            }
            List<BuildEntity> builds = buildService.getBuildsByOrganisationId(user.getOrganisation().getId());
            List<BuildDto> buildDtos = builds.stream().map(build -> new BuildDto(build)).collect(Collectors.toList());
            return ResponseEntity.ok(buildDtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @GetMapping("/{buildId}")
    public ResponseEntity<BuildDto> getBuildById(@PathVariable String buildId) {
        try {
            BuildEntity build = buildService.getBuildByBuildId(buildId);
            return ResponseEntity.ok(new BuildDto(build));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        }
    }

    @GetMapping("/project/{projectId}")
    public ResponseEntity<List<BuildDto>> getBuildsByProject(@PathVariable String projectId) {
        try {
            List<BuildEntity> builds = buildService.getBuildsByProjectId(projectId);
            return ResponseEntity.ok(builds.stream().map(BuildDto::new).collect(Collectors.toList()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @DeleteMapping("/{buildId}")
    public ResponseEntity<Map<String, String>> deleteBuild(@PathVariable String buildId) {
        try {
            buildService.deleteBuild(buildId);
            return ResponseEntity.ok(Map.of("message", "Build deleted successfully"));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Build not found"));
        }
    }
}