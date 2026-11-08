/// Modèles legacy pour l'équilibrage autonome (standalone balance tab).
/// Ces modèles sont utilisés par l'ancien onglet "Équilibrage" qui appelle /api/v1/balance/direct etc.
/// Pour le nouveau tableau de bord, les modèles sont dans api.dart.

class Operation {
  final String id;
  final String name;
  final double duration;
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
  });

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