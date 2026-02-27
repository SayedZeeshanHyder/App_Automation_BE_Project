package com.flutomapp.app.kafka;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class BuildPipelineEvent {

    private String buildId;
    private String projectId;
    private String instructions;
    private int initialScreenIndex;

    private int currentScreenIndex = -1;

    private String phase;

    public BuildPipelineEvent(String buildId, String projectId, String instructions, int initialScreenIndex, String phase) {
        this.buildId = buildId;
        this.projectId = projectId;
        this.instructions = instructions;
        this.initialScreenIndex = initialScreenIndex;
        this.currentScreenIndex = -1;
        this.phase = phase;
    }
}
