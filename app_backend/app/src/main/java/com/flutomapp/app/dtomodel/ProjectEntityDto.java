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

    private OrganisationDto organisation;

    private List<Screen> listOfScreens = new ArrayList<>();

    public ProjectEntityDto(ProjectEntity project) {
        this.id = project.getId();
        this.projectName = project.getProjectName();
        this.status=project.getStatus();
        this.createdAt=project.getCreatedAt();
        this.lastBuildAt=project.getLastBuildAt();
        this.lastBuildVersion=project.getLastBuildVersion();
        this.organisation=new OrganisationDto(project.getOrganisation());
        listOfScreens=project.getListOfScreens();
    }
}
