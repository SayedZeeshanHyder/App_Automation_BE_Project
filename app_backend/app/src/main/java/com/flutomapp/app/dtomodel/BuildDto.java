package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.BuildEntity;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.ProjectEntity;
import com.flutomapp.app.model.UserEntity;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class BuildDto {


    private String id;

    private String buildId;

    private String projectId;

    private String organisationId;

    private UserDtoWithoutNotification createdBy;

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
        BuildDto that = (BuildDto) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

    public BuildDto(BuildEntity buildEntity){
        this.id = buildEntity.getId();
        this.buildId = buildEntity.getBuildId();
        this.projectId = buildEntity.getProject().getId();
        this.organisationId = buildEntity.getOrganisation().getId();
        this.createdBy = new UserDtoWithoutNotification(buildEntity.getCreatedBy());
        this.instructions = buildEntity.getInstructions();
        this.initialScreenIndex = buildEntity.getInitialScreenIndex();
        this.statusMessage = buildEntity.getStatusMessage();
        this.completed = buildEntity.isCompleted();
        this.success = buildEntity.isSuccess();
        this.errorMessage = buildEntity.getErrorMessage();
        this.logs = buildEntity.getLogs();
        this.apkLocation = buildEntity.getApkLocation();
        this.buildVersion = buildEntity.getBuildVersion();
        this.createdAt = buildEntity.getCreatedAt();
        this.completedAt = buildEntity.getCompletedAt();
        this.buildDurationMs = buildEntity.getBuildDurationMs();
    }
}
