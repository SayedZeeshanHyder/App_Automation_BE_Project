package com.flutomapp.app.model;

import com.flutomapp.app.dtomodel.Screen;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Document(collection = "app_projects")
public class ProjectEntity {

    @Id
    private String id;
    private String projectName;
    private String status="";
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime lastBuildAt=LocalDateTime.now();
    private String lastBuildVersion="";
    private String lastBuildLocation="";

    @DBRef
    private OrganisationEntity organisation;

    private List<Screen> listOfScreens = new ArrayList<>();

}
