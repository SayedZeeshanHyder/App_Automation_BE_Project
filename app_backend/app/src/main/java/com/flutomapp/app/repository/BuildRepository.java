package com.flutomapp.app.repository;

import com.flutomapp.app.model.BuildEntity;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BuildRepository extends MongoRepository<BuildEntity, String> {

    Optional<BuildEntity> findByBuildId(String buildId);

    List<BuildEntity> findByOrganisationId(String organisationId);

    List<BuildEntity> findByOrganisationIdOrderByCreatedAtDesc(String organisationId);

    List<BuildEntity> findByProjectId(String projectId);

    List<BuildEntity> findByCreatedById(String userId);
}