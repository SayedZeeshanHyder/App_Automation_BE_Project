package com.flutomapp.app.dtomodel;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Screen{
    private UUID screenId =  UUID.randomUUID();
    private String screenName;
    private String screenPrompt;
    private Map<String,Object> screenUI = new HashMap<>();
    private String screenCode;


    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        Screen screen = (Screen) o;
        return Objects.equals(screenId, screen.screenId);
    }

}
