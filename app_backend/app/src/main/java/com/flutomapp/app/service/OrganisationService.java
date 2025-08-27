package com.flutomapp.app.service;

import com.flutomapp.app.dtomodel.OrganisationDto;
import com.flutomapp.app.httpmodels.OrganisationApprovalRequest;
import com.flutomapp.app.model.NotificationEntity;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.model.UserEntity;
import com.flutomapp.app.repository.OrganisationRepository;
import com.flutomapp.app.repository.UserRepository;
import com.flutomapp.app.templates.EmailTemplates;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class OrganisationService {

    private final EmailService emailService;
    private final OrganisationRepository organisationRepository;
    private final UserRepository userRepository;

    public OrganisationService(EmailService emailService, OrganisationRepository organisationRepository, UserRepository userRepository) {
        this.emailService = emailService;
        this.organisationRepository = organisationRepository;
        this.userRepository = userRepository;
    }

    public Map<String,Object> createOrganisation(Authentication authentication, OrganisationEntity organisation){
        UserEntity user = (UserEntity) authentication.getPrincipal();
        organisation.setOwner(user);
        List<UserEntity> members = organisation.getMembers();
        members.add(user);
        organisation.setMembers(members);
        OrganisationEntity savedOrganisation = organisationRepository.save(organisation);
        user.setOrganisation(savedOrganisation);
        userRepository.save(user);
        Map<String,Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Organisation created successfully");
        response.put("organisation", new OrganisationDto(savedOrganisation));
        return response;
    }

    public Map<String, Object> joinOrganisaition(Authentication authentication, String organisationId) {
        OrganisationEntity organisation = organisationRepository.findById(organisationId)
                .orElseThrow(() -> new RuntimeException("Organisation not found"));

        UserEntity user = (UserEntity) authentication.getPrincipal(); // Requester
        UserEntity owner = organisation.getOwner();

        Map<String, Object> notificationData = new HashMap<>();
        notificationData.put("userId", user.getId());
        notificationData.put("userName", user.getUsername());
        notificationData.put("role", user.getRole());
        notificationData.put("organisationId", organisation.getId());

        NotificationEntity notification = new NotificationEntity();
        notification.setMessage(user.getUsername() + " has requested to join your organisation.");
        notification.setCategory("join_request");
        notification.setData(notificationData);

        List<NotificationEntity> notifications = owner.getNotifications();
        notifications.add(notification);
        owner.setNotifications(notifications);
        userRepository.save(owner);

        String subject = "New Join Request for Your Organisation: " + organisation.getOrganisationName();

        String body = EmailTemplates.joinRequestTemplate(
                organisation.getOrganisationName(),
                user.getUsername(),
                user.getRole(),
                user.getEmail()
        );
        emailService.sendCustomEmail(owner.getEmail(), subject, body);

        // Final Response
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Join request sent to organisation owner and email notification dispatched.");
        return response;
    }

    public OrganisationDto getOrganisation(String organisationId) {
        OrganisationEntity organisation = organisationRepository.findById(organisationId)
                .orElseThrow(() -> new RuntimeException("Organisation not found"));
        return new OrganisationDto(organisation);
    }

    public Map<String, Object> approveJoinRequest(Authentication authentication, NotificationEntity notification) {
        Map<String, Object> response = new HashMap<>();

        String userId = (String) notification.getData().get("userId");
        String organisationId = (String) notification.getData().get("organisationId");

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        OrganisationEntity organisation = organisationRepository.findById(organisationId)
                .orElseThrow(() -> new RuntimeException("Organisation not found"));

        List<UserEntity> members = organisation.getMembers();
        if (!members.contains(user)) {
            UserEntity owner = organisation.getOwner();
            NotificationEntity newNotification = new NotificationEntity();
            newNotification.setCategory("unactionable");
            newNotification.setMessage("User "+user.getUsername()+" Aprroved to Organisation.");
            newNotification.setCreatedAt(LocalDateTime.now());
            List<NotificationEntity> notifications = owner.getNotifications();
            notifications.remove(notification);
            notifications.add(newNotification);
            owner.setNotifications(notifications);
            userRepository.save(owner);

            members.add(user);
            organisation.setMembers(members);
            organisationRepository.save(organisation);

            String subject = "You’ve been added to " + organisation.getOrganisationName();
            String htmlBody = EmailTemplates.joinRequestApprovedTemplate(organisation.getOrganisationName(), user.getUsername(), owner.getUsername());
            emailService.sendCustomEmail(user.getEmail(), subject, htmlBody);

            response.put("success", true);
            response.put("message", "Successfully added user with userId " + userId + " to organisation with Id " + organisationId);
            return response;
        }

        response.put("success", false);
        response.put("message", "User with userId " + userId + " is already a member of organisation with Id " + organisationId);
        return response;
    }

    public Map<String,Object> removeMember(Authentication authentication, OrganisationApprovalRequest request) {
        Map<String,Object> response = new HashMap<>();
        String userId = request.getUserId();
        String organisationId = request.getOrganisationId();
        UserEntity user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found"));
        OrganisationEntity organisation = organisationRepository.findById(organisationId)
                .orElseThrow(() -> new RuntimeException("Organisation not found"));
        List<UserEntity> members = organisation.getMembers();
        if (members.contains(user)) {
            members.remove(user);
            organisation.setMembers(members);
            organisationRepository.save(organisation);
            response.put("success", true);
            response.put("message", "Successfully removed user with user Id "+userId+" from organisation with Id "+organisationId);
            return response;
        }
        response.put("success", false);
        response.put("message", "user with user Id "+userId+" is not a member of organisation with Id "+organisationId);
        return response;
    }

    public List<OrganisationDto> getAllOrganisations() {
        List<OrganisationEntity> organisations = organisationRepository.findAll();
        return organisations.stream().map(OrganisationDto::new).toList();
    }
}
