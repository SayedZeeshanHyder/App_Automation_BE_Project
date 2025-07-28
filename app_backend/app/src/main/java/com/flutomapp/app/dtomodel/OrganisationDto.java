package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.OrganisationEntity;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class OrganisationDto {
    private String id;
    private String organisationName;
    private LocalDateTime createdAt = LocalDateTime.now();
    private String organisationLogo;
    private String organisationDescription;
    private UserDto owner;
    private List<UserDto> members;

    public OrganisationDto(OrganisationEntity organisationEntity){
        this.id = organisationEntity.getId();
        this.organisationName = organisationEntity.getOrganisationName();
        this.createdAt = organisationEntity.getCreatedAt();
        this.organisationLogo = organisationEntity.getOrganisationLogo();
        this.organisationDescription = organisationEntity.getOrganisationDescription();
        this.owner = new UserDto(organisationEntity.getOwner());
        this.members = organisationEntity.getMembers().stream()
                .map(UserDto::new)
                .toList();
    }
}
