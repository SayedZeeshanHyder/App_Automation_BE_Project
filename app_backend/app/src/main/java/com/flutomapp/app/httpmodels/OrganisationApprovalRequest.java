package com.flutomapp.app.httpmodels;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrganisationApprovalRequest {

    private String organisationId;
    private String userId;

}
