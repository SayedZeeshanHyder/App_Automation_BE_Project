package com.flutomapp.app.httpmodels;

import com.flutomapp.app.dtomodel.Screen;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProjectScreenRequest {

    private String projectId;
    private String screenId;
    private Screen screen;

}
