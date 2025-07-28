package com.flutomapp.app.dtomodel;

import com.flutomapp.app.model.NotificationEntity;
import com.flutomapp.app.model.UserEntity;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class UserDto {

    private String id;
    private String userName;
    private String email;
    private String role;
    private String deviceToken;
    private List<NotificationEntity> notifications = new ArrayList<>();

    public UserDto(UserEntity user) {
        this.id = user.getId();
        this.userName = user.getUsername();
        this.email = user.getEmail();
        this.role = user.getRole();
        this.deviceToken = user.getDeviceToken();
        this.notifications = user.getNotifications() != null ? user.getNotifications() : new ArrayList<>();
    }

}
