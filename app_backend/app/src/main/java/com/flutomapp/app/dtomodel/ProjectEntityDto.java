package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.ProjectEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.mongodb.core.mapping.DBRef;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProjectEntityDto {

    private String id;
    private String projectName;
    private String status="";
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime lastBuildAt=LocalDateTime.now();
    private String lastBuildVersion="";
    private String lastBuildLocation="";

    private String organisationId;

    private List<Screen> listOfScreens = new ArrayList<>();
    private List<Map<String,String>> envVariables = new ArrayList<>();
    private boolean isFirebaseConfigured = false;
    private String appIcon;
    private List<String> androidPermissions = new ArrayList<>();

    public ProjectEntityDto(ProjectEntity project) {
        this.id = project.getId();
        this.projectName = project.getProjectName();
        this.status=project.getStatus();
        this.createdAt=project.getCreatedAt();
        this.lastBuildAt=project.getLastBuildAt();
        this.lastBuildVersion=project.getLastBuildVersion();
        this.organisationId=project.getOrganisation().getId();
        listOfScreens=project.getListOfScreens();
        this.androidPermissions = project.getAndroidPermissions();
        this.envVariables = project.getEnvVariables();
        this.appIcon = project.getAppIcon();
        this.isFirebaseConfigured=project.isFirebaseConfigured();
    }
}
