import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch.dart';
import '../network/api_client.dart';

abstract class BranchRepository {
  Future<List<Branch>> getBranches();
  Future<List<Branch>> getAdminBranches(String adminUserId);
  Future<Branch> createBranch(Map<String, dynamic> data);
  Future<Branch> updateBranch(int id, Map<String, dynamic> data);
  Future<void> assignAdmin(int branchId, String adminUserId);
  Future<void> removeAdmin(int branchId, String adminUserId);
}

class ApiBranchRepository implements BranchRepository {
  final ApiClient _apiClient;

  ApiBranchRepository(this._apiClient);

  @override
  Future<List<Branch>> getBranches() async {
    final response = await _apiClient.get<List<dynamic>>('');
    return (response.data ?? [])
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Branch>> getAdminBranches(String adminUserId) async {
    final response = await _apiClient.get<List<dynamic>>('admin/$adminUserId');
    return (response.data ?? [])
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Branch> createBranch(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>('', data: data);
    return Branch.fromJson(response.data!);
  }

  @override
  Future<Branch> updateBranch(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put<Map<String, dynamic>>('$id', data: data);
    return Branch.fromJson(response.data!);
  }

  @override
  Future<void> assignAdmin(int branchId, String adminUserId) async {
    await _apiClient.post('$branchId/admins', data: {'adminUserId': adminUserId});
  }

  @override
  Future<void> removeAdmin(int branchId, String adminUserId) async {
    await _apiClient.delete('$branchId/admins/$adminUserId');
  }
}

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  final apiClient = ref.read(branchesApiProvider);
  return ApiBranchRepository(apiClient);
});
