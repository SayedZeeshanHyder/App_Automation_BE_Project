package com.flutomapp.app.httpmodels.BuildModels;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class BuildStatus {
    private String buildId;
    private String statusMessage;
    private boolean completed = false;
    private boolean success = false;
    private String errorMessage;
    private List<String> logs = new ArrayList<>();
    private String apkFilePath;
}
