package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.ProjectEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProjectDtoWithoutOrganisation {

    private String id;
    private String projectName;
    private String status="";
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime lastBuildAt=LocalDateTime.now();
    private String lastBuildVersion="";
    private String lastBuildLocation="";
    private List<Screen> listOfScreens = new ArrayList<>();

    public ProjectDtoWithoutOrganisation(ProjectEntity project) {
        this.id = project.getId();
        this.createdAt=project.getCreatedAt();
        this.projectName=project.getProjectName();
        this.status=project.getStatus();
        this.lastBuildAt=project.getLastBuildAt();
        this.lastBuildVersion=project.getLastBuildVersion();
        this.lastBuildLocation=project.getLastBuildLocation();
        this.listOfScreens=project.getListOfScreens();
    }

}
