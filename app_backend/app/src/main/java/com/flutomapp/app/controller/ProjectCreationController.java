package com.flutomapp.app.controller;

import com.flutomapp.app.httpmodels.ProjectCreationMetaResponse;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.repository.ProjectRepository;
import com.flutomapp.app.service.ProjectCreationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/project")
public class ProjectCreationController {

    private final ProjectCreationService projectCreationService;
    private final ProjectRepository projectRepository;

    public ProjectCreationController(ProjectCreationService projectCreationService, ProjectRepository projectRepository) {
        this.projectCreationService = projectCreationService;
        this.projectRepository = projectRepository;
    }

    @PostMapping(value = "/create", consumes = {"multipart/form-data"})
    public ResponseEntity<ProjectCreationMetaResponse> createProject(
            @RequestParam String projectName,
            @RequestParam String organisationName,
            @RequestParam String description,
            @RequestParam(required = false) List<String> envKeys,
            @RequestParam(required = false) List<String> envValues,
            @RequestParam boolean requireFirebase,
            @RequestParam(required = false) MultipartFile googleServicesJson,
            @RequestParam(required = false) List<String> androidPermissions,
            @RequestParam(required = false) MultipartFile appIcon,
            Authentication authentication
    ) {
        UserEntity user = (UserEntity) authentication.getPrincipal();
        ProjectCreationMetaResponse result = projectCreationService.createProjectMetaOnly(
                projectName,
                organisationName,
                description,
                envKeys,
                envValues,
                requireFirebase,
                googleServicesJson,
                androidPermissions,
                appIcon,user.getOrganisation()
        );
        return ResponseEntity.ok(result);
    }

    @GetMapping("/download/{uniqueId}")
    public ResponseEntity<Resource> downloadProjectZip(@PathVariable String uniqueId) {
        String baseDir = projectCreationService.baseProjectsDir;
        File zipFile = new File(baseDir + File.separator + uniqueId + ".zip");
        if (!zipFile.exists()) {
            return ResponseEntity.notFound().build();
        }
        InputStreamResource resource;
        try {
            resource = new InputStreamResource(new FileInputStream(zipFile));
        } catch (FileNotFoundException e) {
            return ResponseEntity.internalServerError().build();
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + zipFile.getName() + "\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .contentLength(zipFile.length())
                .body(resource);
    }

    @GetMapping("/status/{uniqueId}")
    public ResponseEntity<Map<String, String>> getProjectStatus(@PathVariable String uniqueId) {
        return projectRepository.findById(uniqueId)
                .map(project -> ResponseEntity.ok(Map.of(
                        "projectId", project.getId(),
                        "status", project.getStatus()
                )))
                .orElse(ResponseEntity.notFound().build());
    }
}
