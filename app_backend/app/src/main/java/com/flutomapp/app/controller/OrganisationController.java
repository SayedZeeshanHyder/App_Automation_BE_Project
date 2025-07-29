package com.flutomapp.app.controller;

import com.flutomapp.app.httpmodels.OrganisationApprovalRequest;
import com.flutomapp.app.model.NotificationEntity;
import com.flutomapp.app.model.OrganisationEntity;
import com.flutomapp.app.service.OrganisationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/organisation")
public class OrganisationController {

    private final OrganisationService organisationService;

    public OrganisationController(OrganisationService organisationService) {
        this.organisationService = organisationService;
    }

    @PostMapping("create")
    public ResponseEntity<?> createOrganisation(Authentication authentication, @RequestBody OrganisationEntity organisation) {
        return ResponseEntity.ok(organisationService.createOrganisation(authentication, organisation));
    }

    @PostMapping("join/{organisationId}")
    public ResponseEntity<?> joinOrganisation(Authentication authentication, @PathVariable String organisationId) {
        return ResponseEntity.ok(organisationService.joinOrganisaition(authentication, organisationId));
    }

    @GetMapping("{organisationId}")
    public ResponseEntity<?> getOrganisation(@PathVariable String organisationId) {
        return ResponseEntity.ok(organisationService.getOrganisation(organisationId));
    }

    @PostMapping("approve")
    public ResponseEntity<?> approveJoinRequest(Authentication authentication,@RequestBody NotificationEntity notification) {
        return ResponseEntity.ok(organisationService.approveJoinRequest(authentication,notification));
    }

    @PostMapping("remove")
    public ResponseEntity<?> removeMember(Authentication authentication, @RequestBody OrganisationApprovalRequest request) {
        return ResponseEntity.ok(organisationService.removeMember(authentication, request));
    }

    @GetMapping
    public ResponseEntity<?> getAllOrganisations() {
        return ResponseEntity.ok(organisationService.getAllOrganisations());
    }
}
