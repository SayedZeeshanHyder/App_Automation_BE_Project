package com.flutomapp.app.httpmodels;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProjectCreationRequest {
    private String projectName;
    private String organisationName;
    private String description;
    private List<Map<String, String>> env;
    private boolean requireFirebase;
    private MultipartFile googleServicesJson;
    private List<String> androidPermissions;
    private MultipartFile appIcon;
}


