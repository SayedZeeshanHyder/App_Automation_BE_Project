package com.flutomapp.app.httpmodels.BuildModels;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class BuildStartResponse {
    private String buildId;
    private String buildStatus;
}
