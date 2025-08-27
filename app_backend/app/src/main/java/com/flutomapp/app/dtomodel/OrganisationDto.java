package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.ProjectEntity;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class OrganisationDto {
    private String id;
    private String organisationName;
    private LocalDateTime createdAt = LocalDateTime.now();
    private String organisationLogo;
    private String organisationDescription;
    private UserDtoWithoutNotification owner;
    private List<UserDtoWithoutNotification> members;
    private List<ProjectDtoWithoutOrganisation> listOfProjects = new ArrayList<>();

    public OrganisationDto(OrganisationEntity organisationEntity){
        this.id = organisationEntity.getId();
        this.organisationName = organisationEntity.getOrganisationName();
        this.createdAt = organisationEntity.getCreatedAt();
        this.organisationLogo = organisationEntity.getOrganisationLogo();
        this.organisationDescription = organisationEntity.getOrganisationDescription();
        this.owner = new UserDtoWithoutNotification(organisationEntity.getOwner());
        this.members = organisationEntity.getMembers().stream()
                .map(UserDtoWithoutNotification::new)
                .toList();
        this.listOfProjects = organisationEntity.getProjects().stream().map(ProjectDtoWithoutOrganisation::new).toList();
    }
}
