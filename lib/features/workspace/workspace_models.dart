class WorkspaceSummary {
  const WorkspaceSummary({
    required this.id,
    required this.name,
    required this.createdAtMs,
    required this.createdByUserId,
  });

  final String id;
  final String name;
  final int createdAtMs;
  final String createdByUserId;
}

class WorkspaceMembershipSummary {
  const WorkspaceMembershipSummary({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.userEmail,
    required this.displayName,
    required this.role,
    required this.status,
    required this.createdAtMs,
    required this.createdByUserId,
  });

  final String id;
  final String workspaceId;
  final String userId;
  final String userEmail;
  final String? displayName;
  final String role;
  final String status;
  final int createdAtMs;
  final String createdByUserId;
}

class AthleteProfileSummary {
  const AthleteProfileSummary({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.dateOfBirth,
    required this.notes,
    required this.createdAtMs,
    required this.createdByUserId,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String? dateOfBirth;
  final String? notes;
  final int createdAtMs;
  final String createdByUserId;
}

class AthleteProfileAssignmentSummary {
  const AthleteProfileAssignmentSummary({
    required this.id,
    required this.workspaceId,
    required this.athleteProfileId,
    required this.userId,
    required this.canView,
    required this.canEdit,
    required this.createdAtMs,
    required this.createdByUserId,
  });

  final String id;
  final String workspaceId;
  final String athleteProfileId;
  final String userId;
  final bool canView;
  final bool canEdit;
  final int createdAtMs;
  final String createdByUserId;
}

class WorkspaceInviteSummary {
  const WorkspaceInviteSummary({
    required this.id,
    required this.workspaceId,
    required this.email,
    required this.role,
    required this.displayName,
    required this.expiresAtMs,
    required this.status,
    required this.assignedProfileIds,
    required this.createdAtMs,
    required this.createdByUserId,
  });

  final String id;
  final String workspaceId;
  final String email;
  final String role;
  final String? displayName;
  final int expiresAtMs;
  final String status;
  final List<String> assignedProfileIds;
  final int createdAtMs;
  final String createdByUserId;
}

class ActiveWorkspaceContext {
  const ActiveWorkspaceContext({
    required this.userId,
    required this.workspaceId,
    required this.profileId,
    required this.role,
    required this.needsCloudClaim,
    required this.workspaces,
    required this.memberships,
    required this.profiles,
    required this.assignments,
    required this.invites,
  });

  final String userId;
  final String workspaceId;
  final String profileId;
  final String role;
  final bool needsCloudClaim;
  final List<WorkspaceSummary> workspaces;
  final List<WorkspaceMembershipSummary> memberships;
  final List<AthleteProfileSummary> profiles;
  final List<AthleteProfileAssignmentSummary> assignments;
  final List<WorkspaceInviteSummary> invites;

  List<AthleteProfileSummary> get activeWorkspaceProfiles => profiles
      .where((profile) => profile.workspaceId == workspaceId)
      .where((profile) => assignments.any(
            (assignment) =>
                assignment.workspaceId == workspaceId &&
                assignment.athleteProfileId == profile.id &&
                assignment.userId == userId &&
                assignment.canView,
          ))
      .toList();
}

class InviteCreateRequest {
  const InviteCreateRequest({
    required this.workspaceId,
    required this.email,
    required this.role,
    this.displayName,
    this.assignedProfileIds = const <String>[],
  });

  final String workspaceId;
  final String email;
  final String role;
  final String? displayName;
  final List<String> assignedProfileIds;
}

class InviteCreateResult {
  const InviteCreateResult({
    required this.inviteId,
    required this.email,
    required this.role,
    required this.token,
    required this.expiresAtMs,
    required this.deepLink,
  });

  final String inviteId;
  final String email;
  final String role;
  final String token;
  final int expiresAtMs;
  final String deepLink;
}

class InviteAcceptResult {
  const InviteAcceptResult({
    required this.workspaceId,
    required this.role,
  });

  final String workspaceId;
  final String role;
}
