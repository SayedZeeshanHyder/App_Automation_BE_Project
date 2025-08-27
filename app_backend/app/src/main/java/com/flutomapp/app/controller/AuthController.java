package com.flutomapp.app.controller;

import com.flutomapp.app.dtomodel.UserDto;
import com.flutomapp.app.httpmodels.LoginRequest;
import com.flutomapp.app.httpmodels.RegisterRequest;
import com.flutomapp.app.jwt.JwtUtil;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.repository.OrganisationRepository;
import com.flutomapp.app.repository.UserRepository;
import com.flutomapp.app.service.EmailService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

@RestController
@RequestMapping("/auth")
public class AuthController {

    final private AuthenticationManager authManager;
    final private JwtUtil jwtUtil;
    final private UserRepository userRepo;
    final private PasswordEncoder passwordEncoder;
    final private EmailService emailService;

    AuthController(AuthenticationManager authManager, JwtUtil jwtUtil, UserRepository userRepo, PasswordEncoder passwordEncoder, EmailService emailService){
        this.authManager = authManager;
        this.jwtUtil = jwtUtil;
        this.userRepo = userRepo;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (userRepo.findByUserName(req.getUserName()).isPresent()) {
            return ResponseEntity.badRequest().body("User already exists");
        }
        UserEntity user = new UserEntity();
        user.setUserName(req.getUserName());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setEmail(req.getEmail());
        user.setRole(req.getRole());
        user.setDeviceToken(req.getDeviceToken());
        userRepo.save(user);
        Map<String,Object> response = new HashMap<>();
        response.put("success", true);
        response.put("user",new UserDto(user));
        response.put("token", jwtUtil.generateToken(user));
        String verificationCode = String.valueOf(new Random().nextInt(999999));
        System.out.println(verificationCode);
        response.put("verificationCode", verificationCode);
        emailService.sendVerificationEmail(user.getEmail(),verificationCode);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        try {
            Authentication auth = authManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.getUserName(), req.getPassword()));
            UserEntity user = (UserEntity) auth.getPrincipal();
            String token = jwtUtil.generateToken(user);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("user",new UserDto(user));
            response.put("token", token);
            return ResponseEntity.ok(response);
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
        }
    }
}
