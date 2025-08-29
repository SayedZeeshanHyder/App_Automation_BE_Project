package com.flutomapp.app.httpmodels.BuildModels;
import lombok.Data;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Data
public class BuildStatus {
    private String buildId;
    private String statusMessage;
    private boolean isCompleted = false;
    private boolean isSuccess = false;
    private String errorMessage;
    private String apkFilePath;
    private final List<String> logs = new CopyOnWriteArrayList<>();
}
