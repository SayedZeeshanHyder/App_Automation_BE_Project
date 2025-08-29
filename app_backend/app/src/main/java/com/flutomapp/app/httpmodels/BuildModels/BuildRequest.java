package com.flutomapp.app.httpmodels.BuildModels;

import lombok.Data;

@Data
public class BuildRequest {
    private String instructions;
    private int initialScreenIndex;
}
