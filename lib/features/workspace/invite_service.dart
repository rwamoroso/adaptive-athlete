import 'workspace_models.dart';
import 'workspace_service.dart';

class InviteService {
  const InviteService({required this.workspaceService});

  final WorkspaceService workspaceService;

  Future<InviteCreateResult> createInvite(InviteCreateRequest request) {
    return workspaceService.createInviteLink(request);
  }

  Future<InviteAcceptResult> acceptInvite(String token) {
    return workspaceService.acceptInviteToken(token);
  }
}
