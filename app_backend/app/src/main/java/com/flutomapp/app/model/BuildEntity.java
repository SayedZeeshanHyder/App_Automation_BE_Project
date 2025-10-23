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
@Document(collection = "app_builds")
public class BuildEntity {

    @Id
    private String id;

    private String buildId;

    @DBRef
    private ProjectEntity project;

    @DBRef
    private OrganisationEntity organisation;

    @DBRef
    private UserEntity createdBy;

    private String instructions;

    private int initialScreenIndex;

    private String statusMessage;

    private boolean completed = false;

    private boolean success = false;

    private String errorMessage;

    private List<String> logs = new ArrayList<>();

    private String apkLocation;

    private String buildVersion;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime completedAt;

    private Long buildDurationMs;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof BuildEntity)) return false;
        BuildEntity that = (BuildEntity) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}