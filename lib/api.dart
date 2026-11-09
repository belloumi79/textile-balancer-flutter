/// Client HTTP pour l'API Textile Line Balancer (Render + Supabase).
/// Backend: https://tlb-api.onrender.com (FastAPI v0.5.0)
/// Auth: Supabase GoTrue via Supabase Flutter SDK (handles anon key correctly for web/native)
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  // Supabase
  static const _supabaseUrl = 'https://lkdlqijhlszyfkmunzyt.supabase.co';
  static const _supabaseAnonKey = 'sb_publishable_MFaWSChslfBhcg37fi_RuA_ZEKrzNX1';

  // Render API
  static const _renderBase = 'https://tlb-api.onrender.com';

  String? _accessToken;
  User? _currentUser;

  String? get accessToken => _accessToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;

  /// Initialize Supabase client (call once at app startup)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
  }

  /// Auth via Supabase GoTrue (using Supabase Flutter SDK - handles web/native correctly)
  Future<bool> login(String email, String password) async {
    try {
      final auth = Supabase.instance.client.auth;
      final response = await auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        _accessToken = response.session!.accessToken;
        _currentUser = User.fromApi(response.user!.toJson());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current user info (orgs, subscription) from Render API
  Future<User?> getCurrentUser() async {
    if (_accessToken == null) return null;
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/me'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      _currentUser = User.fromApi(jsonDecode(resp.body));
      return _currentUser;
    }
    return null;
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ── Organizations ──────────────────────────────────────────────────
  Future<List<Organization>> getOrganizations() async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => Organization.fromApi(e))
          .toList();
    }
    return [];
  }

  // ── Production Lines ───────────────────────────────────────────────
  Future<List<ProductionLine>> getProductionLines(String orgId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/lines'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => ProductionLine.fromApi(e))
          .toList();
    }
    return [];
  }

  Future<ProductionLine> createProductionLine(String orgId, ProductionLine line) async {
    final resp = await http.post(
      Uri.parse('$_renderBase/v1/orgs/$orgId/lines'),
      headers: _authHeaders,
      body: jsonEncode(line.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return ProductionLine.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to create line: ${resp.body}');
  }

  Future<void> deleteProductionLine(String orgId, String lineId) async {
    final resp = await http.delete(
      Uri.parse('$_renderBase/v1/orgs/$orgId/lines/$lineId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete line: ${resp.body}');
    }
  }

  // ── Runs / Calculations ────────────────────────────────────────────
  Future<List<RunSummary>> getRuns(String orgId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/runs'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => RunSummary.fromApi(e))
          .toList();
    }
    return [];
  }

  Future<RunDetail> getRunDetail(String orgId, String runId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/runs/$runId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return RunDetail.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to get run: ${resp.body}');
  }

  // ── Balance / Min-Cycle (async jobs) ───────────────────────────────
  Future<JobResponse> startBalance(String orgId, BalanceRequest request) async {
    final resp = await http.post(
      Uri.parse('$_renderBase/v1/orgs/$orgId/runs'),
      headers: _authHeaders,
      body: jsonEncode({
        'kind': 'balance',
        ...request.toJson(),
      }),
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return JobResponse.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to start balance: ${resp.body}');
  }

  Future<JobResponse> startMinCycle(String orgId, MinCycleRequest request) async {
    final resp = await http.post(
      Uri.parse('$_renderBase/v1/orgs/$orgId/runs'),
      headers: _authHeaders,
      body: jsonEncode({
        'kind': 'min_cycle',
        ...request.toJson(),
      }),
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return JobResponse.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to start min-cycle: ${resp.body}');
  }

  Future<JobStatus> getJobStatus(String orgId, String jobId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/jobs/$jobId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return JobStatus.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to get job status: ${resp.body}');
  }

  // ── Problems ────────────────────────────────────────────────────────
  Future<List<ProblemSummary>> getProblems(String orgId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/problems'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => ProblemSummary.fromApi(e))
          .toList();
    }
    return [];
  }

  Future<ProblemDetail> createProblem(String orgId, ProblemRequest request) async {
    final resp = await http.post(
      Uri.parse('$_renderBase/v1/orgs/$orgId/problems'),
      headers: _authHeaders,
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return ProblemDetail.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to create problem: ${resp.body}');
  }

  // ── Workshop / Digital Twin ────────────────────────────────────────
  Future<List<WorkshopPlan>> getWorkshopPlans(String orgId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/workshop-plans'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => WorkshopPlan.fromApi(e))
          .toList();
    }
    return [];
  }

  Future<WorkshopPlan> getWorkshopPlan(String orgId, String planId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/workshop-plans/$planId'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return WorkshopPlan.fromApi(jsonDecode(resp.body));
    }
    throw Exception('Failed to get workshop plan: ${resp.body}');
  }

  // ── Production Sessions ────────────────────────────────────────────
  Future<List<ProductionSession>> getProductionSessions(String orgId) async {
    final resp = await http.get(
      Uri.parse('$_renderBase/v1/orgs/$orgId/production/sessions'),
      headers: _authHeaders,
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return (jsonDecode(resp.body) as List)
          .map((e) => ProductionSession.fromApi(e))
          .toList();
    }
    return [];
  }

  void logout() async {
    await Supabase.instance.client.auth.signOut();
    _accessToken = null;
    _currentUser = null;
  }
}