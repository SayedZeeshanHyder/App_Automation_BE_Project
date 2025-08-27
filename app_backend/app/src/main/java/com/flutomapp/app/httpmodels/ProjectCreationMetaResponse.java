package com.flutomapp.app.httpmodels;


import com.flutomapp.app.dtomodel.OrganisationDto;
import com.flutomapp.app.dtomodel.ProjectEntityDto;
import com.flutomapp.app.model.ProjectEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProjectCreationMetaResponse {
    private OrganisationDto organisation;
    private ProjectEntityDto projectEntity;
    private long timeTakenMs;
    private boolean env;
    private boolean permissions;
    private boolean firebase;
    private boolean appIcon;
}
