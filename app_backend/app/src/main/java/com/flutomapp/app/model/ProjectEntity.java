package com.flutomapp.app.model;

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
@Document(collection = "projects")
public class ProjectEntity {

    @Id
    private String id;
    private String status;
    private List<String> listOfScreens = new ArrayList<>();
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime lastBuildAt;
    private String lastBuildVersion;
    private String lastBuildLocation;

    @DBRef
    private OrganisationEntity organisation;

}
