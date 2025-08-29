package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.NotificationEntity;
import com.flutomapp.app.model.UserEntity;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserDtoWithoutNotification {

    private String id;
    private String userName;
    private String email;
    private String role;
    private String deviceToken;
    private String organisationId;

    public UserDtoWithoutNotification(UserEntity user) {
        this.id = user.getId();
        this.userName = user.getUsername();
        this.email = user.getEmail();
        this.role = user.getRole();
        this.deviceToken = user.getDeviceToken();
        if(user.getOrganisation() != null){
            this.organisationId = user.getOrganisation().getId();
        }else{
            this.organisationId = null;
        }
    }

}
