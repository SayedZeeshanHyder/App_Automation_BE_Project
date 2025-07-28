package com.flutomapp.app.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class NotificationEntity {

    private String id = UUID.randomUUID().toString();
    private String message;
    private LocalDateTime createdAt = LocalDateTime.now();
    private String category;
    private Map<String,Object> data = new HashMap<>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof NotificationEntity that)) return false;
        return id.equals(that.id);
    }
}
