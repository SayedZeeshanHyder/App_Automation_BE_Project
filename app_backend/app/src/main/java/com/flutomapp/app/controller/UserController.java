package com.flutomapp.app.controller;

import com.flutomapp.app.dtomodel.UserDto;
import com.flutomapp.app.dtomodel.UserDtoWithoutNotification;
import com.flutomapp.app.model.NotificationEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RequestMapping("user")
@RestController
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<?> getUserById(Authentication authentication) {
        UserEntity user = (UserEntity) authentication.getPrincipal();
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("user", new UserDto(user));
        return ResponseEntity.ok(response);
    }

    @GetMapping("all")
    public ResponseEntity<?> getAllUsers() {
        List<UserEntity> users = userRepository.findAll();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("user_count", users.size());
        response.put("users", users.stream().map(UserDtoWithoutNotification::new).toList());
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{userId}")
    public ResponseEntity<?> deleteUserById(@PathVariable String userId) {
        if (!userRepository.existsById(userId)) {
            return ResponseEntity.notFound().build();
        }
        userRepository.deleteById(userId);
        Map<String,Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "User deleted successfully");
        response.put("userId", userId);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("notifications")
    public ResponseEntity<?> deleteAllNotifications(Authentication authentication) {
        UserEntity user = (UserEntity) authentication.getPrincipal();
        List<NotificationEntity> notifications = user.getNotifications();
        notifications.clear();
        user.setNotifications(notifications);
        userRepository.save(user);
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "All notifications deleted successfully");
        return ResponseEntity.ok(response);
    }
}
