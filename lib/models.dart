/// Legacy models for standalone balance tab (api/v1/balance/direct etc.).
class Operation {
  final String id;
  final String name;
  double duration;
  final List<String> predecessors;
  final String machineType;
  final List<String> requiredSkills;
  final String section;
  final bool optional;
  final String taskType;

  Operation({
    required this.id,
    required this.name,
    required this.duration,
    this.predecessors = const [],
    this.machineType = '',
    this.requiredSkills = const [],
    this.section = '',
    this.optional = false,
    this.taskType = '',
  });

  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
        predecessors: (json['predecessors'] as List?)?.cast<String>() ?? [],
        machineType: json['machine_type'] ?? '',
        requiredSkills: (json['required_skills'] as List?)?.cast<String>() ?? [],
        section: json['section'] ?? '',
        optional: json['optional'] ?? false,
        taskType: json['task_type'] ?? '',
      );
}

class Workstation {
  final String id;
  final String name;
  final String machineType;
  final bool available;
  final int maxWorkers;
  final String section;

  Workstation({
    required this.id,
    required this.name,
    required this.machineType,
    this.available = true,
    this.maxWorkers = 1,
    this.section = '',
  });

  factory Workstation.fromJson(Map<String, dynamic> json) => Workstation(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        machineType: json['machine_type'] ?? '',
        available: json['available'] ?? true,
        maxWorkers: json['max_workers'] ?? 1,
        section: json['section'] ?? '',
      );
}

class Worker {
  final String id;
  final String name;
  final List<String> skills;
  final double efficiency;
  final bool available;

  Worker({
    required this.id,
    required this.name,
    this.skills = const [],
    this.efficiency = 1.0,
    this.available = true,
  });

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        skills: (json['skills'] as List?)?.cast<String>() ?? [],
        efficiency: (json['efficiency'] as num?)?.toDouble() ?? 1.0,
        available: json['available'] ?? true,
      );
}

class StationDetail {
  final int station;
  final double totalTime;
  final double loadPct;
  final List<String> operations;
  final List<String> workers;

  StationDetail({
    required this.station,
    required this.totalTime,
    required this.loadPct,
    this.operations = const [],
    this.workers = const [],
  });

  factory StationDetail.fromJson(Map<String, dynamic> json) => StationDetail(
        station: json['station'] ?? 0,
        totalTime: (json['total_time'] as num?)?.toDouble() ?? 0,
        loadPct: (json['load_pct'] as num?)?.toDouble() ?? 0,
        operations: (json['operations'] as List?)?.cast<String>() ?? [],
        workers: (json['workers'] as List?)?.cast<String>() ?? [],
      );
}

class Recommendation {
  final String severity;
  final String category;
  final String message;
  final String action;

  Recommendation({
    required this.severity,
    required this.category,
    required this.message,
    required this.action,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        severity: json['severity'] ?? 'info',
        category: json['category'] ?? '',
        message: json['message'] ?? '',
        action: json['action'] ?? '',
      );
}

class BalanceResult {
  final bool success;
  final String solverUsed;
  final String status;
  final double solveTimeSeconds;
  final int stationsUsed;
  final double actualCycleTime;
  final double efficiency;
  final double balanceDelay;
  final double smoothnessIndex;
  final List<StationDetail> stationDetails;
  final Map<String, int> operationAssignments;
  final List<Recommendation> recommendations;

  BalanceResult({
    required this.success,
    required this.solverUsed,
    required this.status,
    required this.solveTimeSeconds,
    required this.stationsUsed,
    required this.actualCycleTime,
    required this.efficiency,
    required this.balanceDelay,
    required this.smoothnessIndex,
    this.stationDetails = const [],
    this.operationAssignments = const {},
    this.recommendations = const [],
  );

  factory BalanceResult.fromApi(Map<String, dynamic> json) => BalanceResult(
        success: json['success'] ?? false,
        solverUsed: json['solver_used'] ?? '',
        status: json['status'] ?? '',
        solveTimeSeconds: (json['solve_time_seconds'] as num?)?.toDouble() ?? 0,
        stationsUsed: json['stations_used'] ?? 0,
        actualCycleTime: (json['actual_cycle_time'] as num?)?.toDouble() ?? 0,
        efficiency: (json['efficiency'] as num?)?.toDouble() ?? 0,
        balanceDelay: (json['balance_delay'] as num?)?.toDouble() ?? 0,
        smoothnessIndex: (json['smoothness_index'] as num?)?.toDouble() ?? 0,
        stationDetails: (json['station_details'] as List?)
                ?.map((e) => StationDetail.fromJson(e))
                .toList() ??
            [],
        operationAssignments: (json['operation_assignments'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            {},
        recommendations: (json['recommendations'] as List?)
                ?.map((e) => Recommendation.fromJson(e))
                .toList() ??
            [],
      );
}

class ProjectData {
  final List<Node> nodes;
  final List<Edge> edges;

  ProjectData({this.nodes = const [], this.edges = const []});

  factory ProjectData.fromJson(Map<String, dynamic> json) => ProjectData(
        nodes: (json['nodes'] as List?)?.map((e) => Node.fromJson(e)).toList() ?? [],
        edges: (json['edges'] as List?)?.map((e) => Edge.fromJson(e)).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}

class Node {
  final String id;
  final String type;
  final bool enabled;
  final Map<String, dynamic> config;

  Node({required this.id, required this.type, this.enabled = true, this.config = const {}});

  factory Node.fromJson(Map<String, dynamic> json) => Node(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        enabled: json['enabled'] ?? true,
        config: (json['config'] as Map<String, dynamic>?) ?? {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'enabled': enabled,
        'config': config,
      };
}

class Edge {
  final String source;
  final String target;

  Edge({required this.source, required this.target});

  factory Edge.fromJson(Map<String, dynamic> json) =>
      Edge(source: json['source'] ?? '', target: json['target'] ?? '');

  Map<String, dynamic> toJson() => {'source': source, 'target': target};
}

// ── Auth Models ─────────────────────────────────────────────────────

class User {
  final String id;
  final String email;
  final String name;
  final String role;

  User({required this.id, required this.email, required this.name, required this.role});

  factory User.fromApi(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'user',
      );
}

class AuthResponse {
  final String accessToken;
  final User user;

  AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromApi(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['access_token'] ?? '',
        user: User.fromApi(json['user'] ?? {}),
      );
}

class Organization {
  final String id;
  final String name;
  final String country;
  final DateTime createdAt;
  final Subscription? subscription;

  Organization({required this.id, required this.name, required this.country, required this.createdAt, this.subscription});

  factory Organization.fromApi(Map<String, dynamic> json) => Organization(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        country: json['country'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
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

/// Modèles de production.

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
  );

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

/// Modèles de calculs.

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
  );

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
    if (!compliant) return const Color(0xFFF79009);
    if (success) return const Color(0xFF039855);
    return const Color(0xFFF04438);
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
  );

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
  );

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
  );
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
  );

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
  );

  factory ProductionSession.fromApi(Map<String, dynamic> json) => ProductionSession(
        id: json['id'] ?? '',
        orgId: json['org_id'] ?? '',
        lineId: json['line_id'] ?? '',
        startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
        endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']!) : null,
        status: json['status'] ?? '',
      );
}

// ── Legacy models for standalone balance tab ───────────────────────

/// Legacy Operation model for standalone balance tab (kept for compatibility)
class LegacyOperation {
  final String id;
  final String name;
  double duration;
  final List<String> predecessors;
  final String machineType;
  final List<String> requiredSkills;
  final String section;
  final bool optional;
  final String taskType;

  LegacyOperation({
    required this.id,
    required this.name,
    required this.duration,
    this.predecessors = const [],
    this.machineType = '',
    this.requiredSkills = const [],
    this.section = '',
    this.optional = false,
    this.taskType = '',
  });

  factory LegacyOperation.fromJson(Map<String, dynamic> json) => LegacyOperation(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
        predecessors: (json['predecessors'] as List?)?.cast<String>() ?? [],
        machineType: json['machine_type'] ?? '',
        requiredSkills: (json['required_skills'] as List?)?.cast<String>() ?? [],
        section: json['section'] ?? '',
        optional: json['optional'] ?? false,
        taskType: json['task_type'] ?? '',
      );
}