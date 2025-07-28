package com.flutomapp.app.httpmodels;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RegisterRequest {

    private String userName;
    private String password;
    private String email;
    private String role;
    private LocalDateTime createdAt = LocalDateTime.now();
    private String deviceToken;

}
