package com.flutomapp.app.kafka;

import java.io.Serializable;
import java.util.List;

public class ProjectCreationEventSample implements Serializable {

    private static final long serialVersionUID = 1L;

    private String uniqueId;
    private String projectName;
    private String organisationId;

    private List<String> envKeys;
    private List<String> envValues;

    private List<String> androidPermissions;

    private boolean requireFirebase;
    private String googleServicesJsonBase64;

    private String appIconBase64;
    private String appIconOriginalFilename;

    private boolean envConfigured;
    private boolean permissionsConfigured;
    private boolean appIconConfigured;
    private boolean firebaseConfigured;

    public ProjectCreationEventSample() {
    }

    public ProjectCreationEventSample(String uniqueId, String projectName, String organisationId,
                                      List<String> envKeys, List<String> envValues,
                                      List<String> androidPermissions, boolean requireFirebase,
                                      String googleServicesJsonBase64, String appIconBase64,
                                      String appIconOriginalFilename, boolean envConfigured,
                                      boolean permissionsConfigured, boolean appIconConfigured,
                                      boolean firebaseConfigured) {
        this.uniqueId = uniqueId;
        this.projectName = projectName;
        this.organisationId = organisationId;
        this.envKeys = envKeys;
        this.envValues = envValues;
        this.androidPermissions = androidPermissions;
        this.requireFirebase = requireFirebase;
        this.googleServicesJsonBase64 = googleServicesJsonBase64;
        this.appIconBase64 = appIconBase64;
        this.appIconOriginalFilename = appIconOriginalFilename;
        this.envConfigured = envConfigured;
        this.permissionsConfigured = permissionsConfigured;
        this.appIconConfigured = appIconConfigured;
        this.firebaseConfigured = firebaseConfigured;
    }

    public String getUniqueId() { return uniqueId; }
    public void setUniqueId(String uniqueId) { this.uniqueId = uniqueId; }

    public String getProjectName() { return projectName; }
    public void setProjectName(String projectName) { this.projectName = projectName; }

    public String getOrganisationId() { return organisationId; }
    public void setOrganisationId(String organisationId) { this.organisationId = organisationId; }

    public List<String> getEnvKeys() { return envKeys; }
    public void setEnvKeys(List<String> envKeys) { this.envKeys = envKeys; }

    public List<String> getEnvValues() { return envValues; }
    public void setEnvValues(List<String> envValues) { this.envValues = envValues; }

    public List<String> getAndroidPermissions() { return androidPermissions; }
    public void setAndroidPermissions(List<String> androidPermissions) { this.androidPermissions = androidPermissions; }

    public boolean isRequireFirebase() { return requireFirebase; }
    public void setRequireFirebase(boolean requireFirebase) { this.requireFirebase = requireFirebase; }

    public String getGoogleServicesJsonBase64() { return googleServicesJsonBase64; }
    public void setGoogleServicesJsonBase64(String googleServicesJsonBase64) { this.googleServicesJsonBase64 = googleServicesJsonBase64; }

    public String getAppIconBase64() { return appIconBase64; }
    public void setAppIconBase64(String appIconBase64) { this.appIconBase64 = appIconBase64; }

    public String getAppIconOriginalFilename() { return appIconOriginalFilename; }
    public void setAppIconOriginalFilename(String appIconOriginalFilename) { this.appIconOriginalFilename = appIconOriginalFilename; }

    public boolean isEnvConfigured() { return envConfigured; }
    public void setEnvConfigured(boolean envConfigured) { this.envConfigured = envConfigured; }

    public boolean isPermissionsConfigured() { return permissionsConfigured; }
    public void setPermissionsConfigured(boolean permissionsConfigured) { this.permissionsConfigured = permissionsConfigured; }

    public boolean isAppIconConfigured() { return appIconConfigured; }
    public void setAppIconConfigured(boolean appIconConfigured) { this.appIconConfigured = appIconConfigured; }

    public boolean isFirebaseConfigured() { return firebaseConfigured; }
    public void setFirebaseConfigured(boolean firebaseConfigured) { this.firebaseConfigured = firebaseConfigured; }
}
