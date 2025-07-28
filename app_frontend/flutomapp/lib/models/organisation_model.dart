class Organization {
  final String id;
  final String organisationName;
  final String organisationLogo;
  final String organisationDescription;
  final int memberCount;

  Organization({
    required this.id,
    required this.organisationName,
    required this.organisationLogo,
    required this.organisationDescription,
    required this.memberCount,
  });
}

class CreateOrganizationData {
  String organisationName;
  String organisationLogo;
  String organisationDescription;

  CreateOrganizationData({
    this.organisationName = '',
    this.organisationLogo = '',
    this.organisationDescription = '',
  });
}