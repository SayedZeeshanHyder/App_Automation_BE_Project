package com.flutomapp.app.repository;

import com.flutomapp.app.model.OrganisationEntity;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface OrganisationRepository extends MongoRepository<OrganisationEntity, String> {

}
