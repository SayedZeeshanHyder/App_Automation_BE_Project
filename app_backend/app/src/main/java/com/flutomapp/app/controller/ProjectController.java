package com.flutomapp.app.controller;

import com.flutomapp.app.dtomodel.Screen;
import com.flutomapp.app.httpmodels.ProjectScreenRequest;
import com.flutomapp.app.service.ProjectService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/project")
public class ProjectController {

    private final ProjectService projectService;

    public ProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @PostMapping("{projectId}")
    public ResponseEntity<Map<String,Object>> createScreen(@RequestBody Screen screen,@PathVariable String projectId){
        Map<String,Object> map = projectService.createScreen(screen,projectId);
        if((boolean) map.get("success")){
            return ResponseEntity.ok(map);
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("{projectId}")
    public ResponseEntity<Map<String,Object>> deleteProject(@PathVariable String projectId){
        Map<String,Object> map = projectService.deleteProject(projectId);
        if((boolean) map.get("success")){
            return ResponseEntity.ok(map);
        }
        return ResponseEntity.notFound().build();
    }

    @PutMapping("{projectId}")
    public ResponseEntity<Map<String,Object>> updateScreen(@RequestBody ProjectScreenRequest projectScreenRequest){

    }

}
