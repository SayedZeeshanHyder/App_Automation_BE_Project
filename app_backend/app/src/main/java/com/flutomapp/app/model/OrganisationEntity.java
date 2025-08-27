package com.flutomapp.app.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Document(collection = "app_organisations")
public class OrganisationEntity {

    @Id
    private String id;
    private String organisationName;

    @DBRef
    private List<UserEntity> members = new ArrayList<>();

    @DBRef
    private UserEntity owner;
    private LocalDateTime createdAt = LocalDateTime.now();
    private String organisationLogo;
    private String organisationDescription;

    @DBRef
    private List<ProjectEntity> projects = new ArrayList<>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof OrganisationEntity)) return false;
        OrganisationEntity that = (OrganisationEntity) o;
        return id != null && id.equals(that.id);
    }

}
