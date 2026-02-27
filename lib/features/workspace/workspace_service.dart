import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../db/app_db.dart';
import 'workspace_models.dart';

class WorkspaceService {
  WorkspaceService({
    required this.db,
    required this.client,
  });

  final AppDb db;
  final SupabaseClient client;

  Future<ActiveWorkspaceContext?> bootstrapAndGetContext() async {
    final user = client.auth.currentUser;
    if (user == null) {
      await db.clearAppContextState();
      return null;
    }

    final payloadRaw = await client.rpc('bootstrap_workspace_for_current_user');
    final payload = _asMap(payloadRaw);

    final workspaces = _parseWorkspaces(payload['workspaces']);
    final memberships = _parseMemberships(payload['memberships']);
    final profiles = _parseProfiles(payload['profiles']);
    final assignments = _parseAssignments(payload['assignments']);
    final invites = _parseInvites(payload['invites']);

    await db.replaceWorkspaceMetadata(
      workspaces: workspaces
          .map((w) => CloudWorkspace(
                id: w.id,
                name: w.name,
                createdAt: w.createdAtMs,
                createdByUserId: w.createdByUserId,
              ))
          .toList(),
      memberships: memberships
          .map((m) => CloudWorkspaceMembership(
                id: m.id,
                workspaceId: m.workspaceId,
                userId: m.userId,
                userEmail: m.userEmail,
                displayName: m.displayName,
                role: m.role,
                status: m.status,
                createdAt: m.createdAtMs,
                createdByUserId: m.createdByUserId,
              ))
          .toList(),
      profiles: profiles
          .map((p) => CloudAthleteProfile(
                id: p.id,
                workspaceId: p.workspaceId,
                name: p.name,
                dateOfBirth: p.dateOfBirth,
                notes: p.notes,
                createdAt: p.createdAtMs,
                createdByUserId: p.createdByUserId,
              ))
          .toList(),
      assignments: assignments
          .map((a) => CloudAthleteProfileAssignment(
                id: a.id,
                workspaceId: a.workspaceId,
                athleteProfileId: a.athleteProfileId,
                userId: a.userId,
                canView: a.canView,
                canEdit: a.canEdit,
                createdAt: a.createdAtMs,
                createdByUserId: a.createdByUserId,
              ))
          .toList(),
      invites: invites
          .map((i) => CloudWorkspaceInvite(
                id: i.id,
                workspaceId: i.workspaceId,
                email: i.email,
                role: i.role,
                displayName: i.displayName,
                expiresAt: i.expiresAtMs,
                status: i.status,
                assignedProfileIdsJson: jsonEncode(i.assignedProfileIds),
                createdAt: i.createdAtMs,
                createdByUserId: i.createdByUserId,
              ))
          .toList(),
    );

    final existing = await db.getAppContextStateRow();
    final workspaceIds = workspaces.map((w) => w.id).toSet();
    final defaultWorkspaceId = _requiredString(payload, 'active_workspace_id');
    final activeWorkspaceId = workspaceIds.contains(existing?.activeWorkspaceId)
        ? existing!.activeWorkspaceId!
        : defaultWorkspaceId;

    final profileIds = assignments
        .where((a) => a.workspaceId == activeWorkspaceId && a.userId == user.id)
        .where((a) => a.canView)
        .map((a) => a.athleteProfileId)
        .toSet();
    final defaultProfileId = _requiredString(payload, 'active_profile_id');
    final activeProfileId = profileIds.contains(existing?.activeProfileId)
        ? existing!.activeProfileId!
        : defaultProfileId;

    final role = memberships
            .where((m) =>
                m.workspaceId == activeWorkspaceId && m.userId == user.id)
            .map((m) => m.role)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null) ??
        (_asString(payload['active_role']) ?? 'athlete');
    final needsCloudClaim = _asBool(payload['needs_legacy_claim']) ?? false;

    await db.upsertAppContextState(
      activeWorkspaceId: activeWorkspaceId,
      activeProfileId: activeProfileId,
      activeRole: role,
      lastAuthUserId: user.id,
      needsCloudClaim: needsCloudClaim,
    );

    return ActiveWorkspaceContext(
      userId: user.id,
      workspaceId: activeWorkspaceId,
      profileId: activeProfileId,
      role: role,
      needsCloudClaim: needsCloudClaim,
      workspaces: workspaces,
      memberships: memberships,
      profiles: profiles,
      assignments: assignments,
      invites: invites,
    );
  }

  Future<ActiveWorkspaceContext?> getCachedContext() async {
    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }
    final state = await db.getAppContextStateRow();
    if (state?.activeWorkspaceId == null || state?.activeProfileId == null) {
      return null;
    }

    final workspaces = (await db.select(db.cloudWorkspaces).get())
        .map(
          (w) => WorkspaceSummary(
            id: w.id,
            name: w.name,
            createdAtMs: w.createdAt,
            createdByUserId: w.createdByUserId,
          ),
        )
        .toList();
    final memberships = (await db.select(db.cloudWorkspaceMemberships).get())
        .map(
          (m) => WorkspaceMembershipSummary(
            id: m.id,
            workspaceId: m.workspaceId,
            userId: m.userId,
            userEmail: m.userEmail,
            displayName: m.displayName,
            role: m.role,
            status: m.status,
            createdAtMs: m.createdAt,
            createdByUserId: m.createdByUserId,
          ),
        )
        .toList();
    final profiles = (await db.select(db.cloudAthleteProfiles).get())
        .map(
          (p) => AthleteProfileSummary(
            id: p.id,
            workspaceId: p.workspaceId,
            name: p.name,
            dateOfBirth: p.dateOfBirth,
            notes: p.notes,
            createdAtMs: p.createdAt,
            createdByUserId: p.createdByUserId,
          ),
        )
        .toList();
    final assignments =
        (await db.select(db.cloudAthleteProfileAssignments).get())
            .map(
              (a) => AthleteProfileAssignmentSummary(
                id: a.id,
                workspaceId: a.workspaceId,
                athleteProfileId: a.athleteProfileId,
                userId: a.userId,
                canView: a.canView,
                canEdit: a.canEdit,
                createdAtMs: a.createdAt,
                createdByUserId: a.createdByUserId,
              ),
            )
            .toList();
    final invites = (await db.select(db.cloudWorkspaceInvites).get())
        .map(
          (i) => WorkspaceInviteSummary(
            id: i.id,
            workspaceId: i.workspaceId,
            email: i.email,
            role: i.role,
            displayName: i.displayName,
            expiresAtMs: i.expiresAt,
            status: i.status,
            assignedProfileIds:
                _asStringList(jsonDecode(i.assignedProfileIdsJson)),
            createdAtMs: i.createdAt,
            createdByUserId: i.createdByUserId,
          ),
        )
        .toList();

    final role = state!.activeRole ??
        memberships
            .where(
              (m) =>
                  m.workspaceId == state.activeWorkspaceId &&
                  m.userId == user.id,
            )
            .map((m) => m.role)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null) ??
        'athlete';

    return ActiveWorkspaceContext(
      userId: user.id,
      workspaceId: state.activeWorkspaceId!,
      profileId: state.activeProfileId!,
      role: role,
      needsCloudClaim: state.needsCloudClaim,
      workspaces: workspaces,
      memberships: memberships,
      profiles: profiles,
      assignments: assignments,
      invites: invites,
    );
  }

  Future<ActiveWorkspaceContext> requireContext() async {
    final context = await getCachedContext() ?? await bootstrapAndGetContext();
    if (context == null) {
      throw StateError('No active workspace context. Sign in first.');
    }
    return context;
  }

  Future<void> switchActiveProfile({
    required String workspaceId,
    required String profileId,
    bool clearLocalData = true,
  }) async {
    final context = await requireContext();
    final allowedProfileIds = context.assignments
        .where(
            (a) => a.workspaceId == workspaceId && a.userId == context.userId)
        .where((a) => a.canView)
        .map((a) => a.athleteProfileId)
        .toSet();
    if (!allowedProfileIds.contains(profileId)) {
      throw StateError('User does not have access to selected profile.');
    }
    final role = context.memberships
            .where((m) =>
                m.workspaceId == workspaceId && m.userId == context.userId)
            .map((m) => m.role)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null) ??
        context.role;

    await db.upsertAppContextState(
      activeWorkspaceId: workspaceId,
      activeProfileId: profileId,
      activeRole: role,
      lastAuthUserId: context.userId,
      needsCloudClaim: context.needsCloudClaim,
    );
    if (clearLocalData) {
      await db.clearLocalDomainData();
    }
  }

  Future<InviteCreateResult> createInviteLink(
      InviteCreateRequest request) async {
    final responseRaw = await client.rpc(
      'create_workspace_invite',
      params: {
        'p_workspace_id': request.workspaceId,
        'p_email': request.email.trim().toLowerCase(),
        'p_role': request.role,
        'p_display_name': request.displayName,
        'p_assigned_profile_ids': request.assignedProfileIds,
      },
    );
    final response = _asMap(responseRaw);
    final token = _requiredString(response, 'token');
    final deepLink = _asString(response['deep_link']) ??
        'adaptiveathlete://join?token=${Uri.encodeComponent(token)}';
    return InviteCreateResult(
      inviteId: _requiredString(response, 'invite_id'),
      email: _requiredString(response, 'email'),
      role: _requiredString(response, 'role'),
      token: token,
      expiresAtMs: _toUnixMs(response['expires_at']),
      deepLink: deepLink,
    );
  }

  Future<InviteAcceptResult> acceptInviteToken(String token) async {
    final responseRaw = await client.rpc(
      'accept_workspace_invite',
      params: {'p_token': token},
    );
    final response = _asMap(responseRaw);
    await db.setPendingInviteToken(null);
    await bootstrapAndGetContext();
    return InviteAcceptResult(
      workspaceId: _requiredString(response, 'workspace_id'),
      role: _requiredString(response, 'role'),
    );
  }

  Future<void> claimLegacyRowsForActiveProfile({
    required ActiveWorkspaceContext context,
  }) async {
    await client.rpc(
      'claim_legacy_rows_into_profile',
      params: {
        'p_workspace_id': context.workspaceId,
        'p_athlete_profile_id': context.profileId,
      },
    );
    await db.upsertAppContextState(
      activeWorkspaceId: context.workspaceId,
      activeProfileId: context.profileId,
      activeRole: context.role,
      lastAuthUserId: context.userId,
      needsCloudClaim: false,
    );
  }

  Future<String?> getPendingInviteToken() async {
    final state = await db.getAppContextStateRow();
    return state?.pendingInviteToken;
  }

  Future<void> setPendingInviteToken(String? token) {
    return db.setPendingInviteToken(token);
  }

  List<WorkspaceSummary> _parseWorkspaces(dynamic value) {
    return _asMapList(value)
        .map(
          (row) => WorkspaceSummary(
            id: _requiredString(row, 'id'),
            name: _requiredString(row, 'name'),
            createdAtMs: _toUnixMs(row['created_at']),
            createdByUserId: _requiredString(row, 'created_by_user_id'),
          ),
        )
        .toList();
  }

  List<WorkspaceMembershipSummary> _parseMemberships(dynamic value) {
    return _asMapList(value)
        .map(
          (row) => WorkspaceMembershipSummary(
            id: _requiredString(row, 'id'),
            workspaceId: _requiredString(row, 'workspace_id'),
            userId: _requiredString(row, 'user_id'),
            userEmail: _requiredString(row, 'user_email'),
            displayName: _asString(row['display_name']),
            role: _requiredString(row, 'role'),
            status: _requiredString(row, 'status'),
            createdAtMs: _toUnixMs(row['created_at']),
            createdByUserId: _requiredString(row, 'created_by_user_id'),
          ),
        )
        .toList();
  }

  List<AthleteProfileSummary> _parseProfiles(dynamic value) {
    return _asMapList(value)
        .map(
          (row) => AthleteProfileSummary(
            id: _requiredString(row, 'id'),
            workspaceId: _requiredString(row, 'workspace_id'),
            name: _requiredString(row, 'name'),
            dateOfBirth: _asString(row['date_of_birth']),
            notes: _asString(row['notes']),
            createdAtMs: _toUnixMs(row['created_at']),
            createdByUserId: _requiredString(row, 'created_by_user_id'),
          ),
        )
        .toList();
  }

  List<AthleteProfileAssignmentSummary> _parseAssignments(dynamic value) {
    return _asMapList(value)
        .map(
          (row) => AthleteProfileAssignmentSummary(
            id: _requiredString(row, 'id'),
            workspaceId: _requiredString(row, 'workspace_id'),
            athleteProfileId: _requiredString(row, 'athlete_profile_id'),
            userId: _requiredString(row, 'user_id'),
            canView: _asBool(row['can_view']) ?? true,
            canEdit: _asBool(row['can_edit']) ?? true,
            createdAtMs: _toUnixMs(row['created_at']),
            createdByUserId: _requiredString(row, 'created_by_user_id'),
          ),
        )
        .toList();
  }

  List<WorkspaceInviteSummary> _parseInvites(dynamic value) {
    return _asMapList(value)
        .map(
          (row) => WorkspaceInviteSummary(
            id: _requiredString(row, 'id'),
            workspaceId: _requiredString(row, 'workspace_id'),
            email: _requiredString(row, 'email'),
            role: _requiredString(row, 'role'),
            displayName: _asString(row['display_name']),
            expiresAtMs: _toUnixMs(row['expires_at']),
            status: _requiredString(row, 'status'),
            assignedProfileIds: _asStringList(row['assigned_profile_ids']),
            createdAtMs: _toUnixMs(row['created_at']),
            createdByUserId: _requiredString(row, 'created_by_user_id'),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    throw StateError('Expected JSON object response, got: $value');
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value == null) {
      return const <Map<String, dynamic>>[];
    }
    if (value is List) {
      return value.map(_asMap).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _requiredString(Map<String, dynamic> row, String key) {
    final value = _asString(row[key]);
    if (value == null || value.isEmpty) {
      throw StateError('Missing required string "$key".');
    }
    return value;
  }

  String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool? _asBool(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true' || normalized == 't' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == 'f' || normalized == '0') {
      return false;
    }
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const <String>[];
  }

  int _toUnixMs(dynamic value) {
    if (value == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    if (value is int) {
      return value < 100000000000 ? value * 1000 : value;
    }
    if (value is num) {
      final n = value.toInt();
      return n < 100000000000 ? n * 1000 : n;
    }
    final parsedInt = int.tryParse(value.toString());
    if (parsedInt != null) {
      return parsedInt < 100000000000 ? parsedInt * 1000 : parsedInt;
    }
    final parsedDate = DateTime.tryParse(value.toString());
    if (parsedDate != null) {
      return parsedDate.millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }
}
