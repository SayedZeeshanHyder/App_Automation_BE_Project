package com.flutomapp.app.service;

import com.flutomapp.app.dtomodel.ProjectEntityDto;
import com.flutomapp.app.dtomodel.Screen;
import com.flutomapp.app.httpmodels.ProjectScreenRequest;
import com.flutomapp.app.model.ProjectEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.repository.ProjectRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;

    public ProjectService(ProjectRepository projectRepository) {
        this.projectRepository = projectRepository;
    }

    public Map<String,Object> createScreen(Screen screen, String projectId){
        Map<String,Object> map = new HashMap<>();
        ProjectEntity project =  projectRepository.findById(projectId).orElse(null);
        if(project == null){
            map.put("projectId",projectId);
            map.put("success",false);
            map.put("error","Project with Id "+projectId+" not found");
            return map;
        }
        List<Screen> listOfScreens = project.getListOfScreens();
        listOfScreens.add(screen);
        project.setListOfScreens(listOfScreens);
        projectRepository.save(project);
        map.put("success",true);
        map.put("message",screen.getScreenName()+"Screen added Successfully");
        return map;
    }

    public Map<String, Object> updateScreen(ProjectScreenRequest projectScreenRequest) {
        Map<String, Object> map = new HashMap<>();

        ProjectEntity project = projectRepository.findById(projectScreenRequest.getProjectId()).orElse(null);
        if (project == null) {
            map.put("projectId", projectScreenRequest.getProjectId());
            map.put("success", false);
            map.put("error", "Project with Id " + projectScreenRequest.getProjectId() + " not found");
            return map;
        }

        List<Screen> screens = project.getListOfScreens();

        UUID screenIdToUpdate = UUID.fromString(projectScreenRequest.getScreenId());
        boolean updated = false;

        for (int i = 0; i < screens.size(); i++) {
            Screen existingScreen = screens.get(i);
            if (existingScreen.getScreenId().equals(screenIdToUpdate)) {
                Screen updatedScreen = projectScreenRequest.getScreen();
                updatedScreen.setScreenId(existingScreen.getScreenId());
                screens.set(i, updatedScreen);
                updated = true;
                break;
            }
        }

        if (!updated) {
            map.put("screenId", projectScreenRequest.getScreenId());
            map.put("success", false);
            map.put("error", "Screen with Id " + projectScreenRequest.getScreenId() + " not found in project");
            return map;
        }

        project.setListOfScreens(screens);
        projectRepository.save(project);

        map.put("success", true);
        map.put("projectId", project.getId());
        map.put("message","Updated Screen Successfully with screen Id "+screenIdToUpdate);
        return map;
    }

    public Map<String,Object> deleteProject(String projectId){
        ProjectEntity project = projectRepository.findById(projectId).orElse(null);
        Map<String,Object> map = new HashMap<>();
        if(project == null){
            map.put("success",false);
            map.put("error","Project with Id "+projectId+" not found");
            return map;
        }
        projectRepository.deleteById(projectId);
        map.put("success",true);
        map.put("message",project.getProjectName()+"Project deleted Successfully");
        return  map;
    }

    public List<ProjectEntityDto> getAllProjects(Authentication authentication){
        UserEntity user = (UserEntity) authentication.getPrincipal();
        return user.getOrganisation().getProjects().stream().map(ProjectEntityDto::new).collect(Collectors.toList());
    }
}
