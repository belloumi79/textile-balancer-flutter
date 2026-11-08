/// Client HTTP pour l'API Textile Line Balancer (Render + Supabase).
/// Backend: https://tlb-api.onrender.com (FastAPI v0.5.0)
/// Auth: Supabase GoTrue via secret key (from env SUPABASE_SECRET)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Supabase
  static const _supabaseUrl = 'https://lkdlqijhlszyfkmunzyt.supabase.co';
  static String get _supabaseSecret => Platform.environment['SUPABASE_SECRET'] ?? '';

  // Render API
  static const _renderBase = 'https://tlb-api.onrender.com';

  String? _accessToken;
  User? _currentUser;

  String? get accessToken => _accessToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;

  /// Auth via Supabase GoTrue (secret key)
  Future<bool> login(String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': _supabaseSecret,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _accessToken = data['access_token'] as String?;
        _currentUser = User.fromApi(data['user'] ?? {});
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current user info (orgs, subscription)
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

  void logout() {
    _accessToken = null;
    _currentUser = null;
  }
}

// ── Models ────────────────────────────────────────────────────────────
class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final List<Organization> orgs;
  final Subscription? subscription;

  User({
    required this.id,
    required this.email,
    this.name = '',
    this.role = 'user',
    this.orgs = const [],
    this.subscription,
  });

  factory User.fromApi(Map<String, dynamic> json) => User(
        id: json['user_id'] ?? json['id'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'user',
        orgs: (json['orgs'] as List?)?.map((e) => Organization.fromApi(e)).toList() ?? [],
        subscription: json['subscription'] != null ? Subscription.fromApi(json['subscription']) : null,
      );
}

class Subscription {
  final String status;
  final String planCode;
  final String? trialEndsAt;
  Subscription({required this.status, required this.planCode, this.trialEndsAt});
  factory Subscription.fromApi(Map<String, dynamic> json) => Subscription(
        status: json['status'] ?? '',
        planCode: json['plan_code'] ?? '',
        trialEndsAt: json['trial_ends_at'] as String?,
      );
}

class Organization {
  final String id;
  final String name;
  final String country;
  final DateTime createdAt;
  final Subscription? subscription;

  Organization({
    required this.id,
    required this.name,
    required this.country,
    required this.createdAt,
    this.subscription,
  });

  factory Organization.fromApi(Map<String, dynamic> json) => Organization(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        country: json['country'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        subscription: json['subscription'] != null ? Subscription.fromApi(json['subscription']) : null,
      );
}

class ProductionLine {
  final String id;
  final String orgId;
  final String name;
  final String product;
  final double targetCycleTime;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductionLine({
    required this.id,
    required this.orgId,
    required this.name,
    required this.product,
    required this.targetCycleTime,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductionLine.fromApi(Map<String, dynamic> json) => ProductionLine(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        name: json['name'] ?? '',
        product: json['product'] ?? '',
        targetCycleTime: (json['target_cycle_time'] as num?)?.toDouble() ?? 0,
        createdBy: json['created_by'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'product': product,
        'target_cycle_time': targetCycleTime,
      };
}

class RunSummary {
  final String id;
  final String orgId;
  final String? problemId;
  final String kind; // 'balance' | 'min_cycle'
  final String solver;
  final String status;
  final bool success;
  final bool compliant;
  final int? stationsUsed;
  final double? actualCycleTime;
  final double? efficiency;
  final double? minCycleTime;
  final String error;
  final DateTime createdAt;
  final DateTime? finishedAt;

  RunSummary({
    required this.id,
    required this.orgId,
    this.problemId,
    required this.kind,
    required this.solver,
    required this.status,
    required this.success,
    required this.compliant,
    this.stationsUsed,
    this.actualCycleTime,
    this.efficiency,
    this.minCycleTime,
    required this.error,
    required this.createdAt,
    this.finishedAt,
  });

  factory RunSummary.fromApi(Map<String, dynamic> json) => RunSummary(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        problemId: json['problem_id'] as String?,
        kind: json['kind'] ?? '',
        solver: json['solver'] ?? '',
        status: json['status'] ?? '',
        success: json['success'] ?? false,
        compliant: json['compliant'] ?? false,
        stationsUsed: json['stations_used'] as int?,
        actualCycleTime: (json['actual_cycle_time'] as num?)?.toDouble(),
        efficiency: (json['efficiency'] as num?)?.toDouble(),
        minCycleTime: (json['min_cycle_time'] as num?)?.toDouble(),
        error: json['error'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        finishedAt: json['finished_at'] != null ? DateTime.tryParse(json['finished_at']!) : null,
      );

  String get statusLabel {
    if (status == 'done') return compliant ? 'Conforme' : 'Non conforme';
    if (status == 'running') return 'En cours';
    if (status == 'failed') return 'Échec';
    return status;
  }

  Color get statusColor {
    if (!compliant) return const Color(0xFFF79009); // orange
    if (success) return const Color(0xFF039855); // green
    return const Color(0xFFF04438); // red
  }
}

class RunDetail extends RunSummary {
  final Map<String, dynamic>? result;
  RunDetail({
    required super.id,
    required super.orgId,
    super.problemId,
    required super.kind,
    required super.solver,
    required super.status,
    required super.success,
    required super.compliant,
    super.stationsUsed,
    super.actualCycleTime,
    super.efficiency,
    super.minCycleTime,
    required super.error,
    required super.createdAt,
    super.finishedAt,
    this.result,
  });

  factory RunDetail.fromApi(Map<String, dynamic> json) => RunDetail(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        problemId: json['problem_id'] as String?,
        kind: json['kind'] ?? '',
        solver: json['solver'] ?? '',
        status: json['status'] ?? '',
        success: json['success'] ?? false,
        compliant: json['compliant'] ?? false,
        stationsUsed: json['stations_used'] as int?,
        actualCycleTime: (json['actual_cycle_time'] as num?)?.toDouble(),
        efficiency: (json['efficiency'] as num?)?.toDouble(),
        minCycleTime: (json['min_cycle_time'] as num?)?.toDouble(),
        error: json['error'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        finishedAt: json['finished_at'] != null ? DateTime.tryParse(json['finished_at']!) : null,
        result: json['result'] as Map<String, dynamic>?,
      );
}

class JobResponse {
  final String jobId;
  final String status;
  JobResponse({required this.jobId, required this.status});
  factory JobResponse.fromApi(Map<String, dynamic> json) => JobResponse(
        jobId: json['job_id'] ?? '',
        status: json['status'] ?? '',
      );
}

class JobStatus {
  final String jobId;
  final String status; // 'pending' | 'running' | 'done' | 'failed'
  final RunDetail? result;
  final String? error;
  JobStatus({required this.jobId, required this.status, this.result, this.error});
  factory JobStatus.fromApi(Map<String, dynamic> json) => JobStatus(
        jobId: json['job_id'] ?? '',
        status: json['status'] ?? '',
        result: json['result'] != null ? RunDetail.fromApi(json['result']) : null,
        error: json['error'] as String?,
      );
}

class BalanceRequest {
  final String problemId;
  final String solver; // 'rpw' | 'cp_sat'
  final String objective; // 'min_stations' | 'min_cycle_time' | 'max_efficiency' | 'balance_workload'
  final int? maxStations;
  final int? timeLimit;

  BalanceRequest({
    required this.problemId,
    this.solver = 'cp_sat',
    this.objective = 'min_stations',
    this.maxStations,
    this.timeLimit,
  });

  Map<String, dynamic> toJson() => {
        'problem_id': problemId,
        'solver': solver,
        'objective': objective,
        if (maxStations != null) 'max_stations': maxStations,
        if (timeLimit != null) 'time_limit': timeLimit,
      };
}

class MinCycleRequest {
  final String problemId;
  final String solver;
  final int? timeLimit;

  MinCycleRequest({
    required this.problemId,
    this.solver = 'rpw',
    this.timeLimit,
  });

  Map<String, dynamic> toJson() => {
        'problem_id': problemId,
        'solver': solver,
        if (timeLimit != null) 'time_limit': timeLimit,
      };
}

class ProblemSummary {
  final String id;
  final String orgId;
  final String? lineId;
  final String name;
  final double targetCycleTime;
  final int operationsCount;
  final DateTime createdAt;

  ProblemSummary({
    required this.id,
    required this.orgId,
    this.lineId,
    required this.name,
    required this.targetCycleTime,
    required this.operationsCount,
    required this.createdAt,
  });

  factory ProblemSummary.fromApi(Map<String, dynamic> json) => ProblemSummary(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        lineId: json['line_id'] as String?,
        name: json['name'] ?? '',
        targetCycleTime: (json['target_cycle_time'] as num?)?.toDouble() ?? 0,
        operationsCount: json['operations_count'] ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}

class ProblemDetail extends ProblemSummary {
  final Map<String, dynamic> payload;
  ProblemDetail({
    required super.id,
    required super.orgId,
    super.lineId,
    required super.name,
    required super.targetCycleTime,
    required super.operationsCount,
    required super.createdAt,
    required this.payload,
  });
  factory ProblemDetail.fromApi(Map<String, dynamic> json) => ProblemDetail(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        lineId: json['line_id'] as String?,
        name: json['name'] ?? '',
        targetCycleTime: (json['target_cycle_time'] as num?)?.toDouble() ?? 0,
        operationsCount: json['operations_count'] ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );
}

class ProblemRequest {
  final String? lineId;
  final String name;
  final double targetCycleTime;
  final Map<String, dynamic> payload;

  ProblemRequest({
    this.lineId,
    required this.name,
    required this.targetCycleTime,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        if (lineId != null) 'line_id': lineId,
        'name': name,
        'target_cycle_time': targetCycleTime,
        'payload': payload,
      };
}

class WorkshopPlan {
  final String id;
  final String orgId;
  final String name;
  final String version;
  final double widthM;
  final double lengthM;
  final Map<String, dynamic>? background;
  final Map<String, dynamic>? elements;
  final Map<String, dynamic>? settings;
  final int? machineCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkshopPlan({
    required this.id,
    required this.orgId,
    required this.name,
    required this.version,
    required this.widthM,
    required this.lengthM,
    this.background,
    this.elements,
    this.settings,
    this.machineCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkshopPlan.fromApi(Map<String, dynamic> json) => WorkshopPlan(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        name: json['name'] ?? '',
        version: json['version'] ?? '',
        widthM: (json['width_m'] as num?)?.toDouble() ?? 0,
        lengthM: (json['length_m'] as num?)?.toDouble() ?? 0,
        background: json['background'] as Map<String, dynamic>?,
        elements: json['elements'] as Map<String, dynamic>?,
        settings: json['settings'] as Map<String, dynamic>?,
        machineCount: json['machine_count'] as int?,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      );
}

class ProductionSession {
  final String id;
  final String orgId;
  final String lineId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;

  ProductionSession({
    required this.id,
    required this.orgId,
    required this.lineId,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  factory ProductionSession.fromApi(Map<String, dynamic> json) => ProductionSession(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        lineId: json['line_id'] ?? '',
        startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
        endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']!) : null,
        status: json['status'] ?? '',
      );
}