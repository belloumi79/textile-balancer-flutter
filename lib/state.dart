/// Global application state matching the web dashboard.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'api.dart';

class AppState extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  ApiClient get api => _api;

  // ── Auth ──────────────────────────────────────────────────────────
  String? _accessToken;
  dynamic _currentUser;
  bool _isSuperAdmin = false;

  String? get accessToken => _accessToken;
  dynamic get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;
  bool get isSuperAdmin => _isSuperAdmin;

  // ── Organizations ─────────────────────────────────────────────────
  List<dynamic> _organizations = [];
  dynamic _selectedOrg;

  List<dynamic> get organizations => _organizations;
  dynamic get selectedOrg => _selectedOrg;

  // ── Production Lines ──────────────────────────────────────────────
  List<dynamic> _productionLines = [];
  bool _linesLoading = false;

  List<dynamic> get productionLines => _productionLines;
  bool get linesLoading => _linesLoading;

  // ── Runs / Calculations History ───────────────────────────────────
  List<RunSummary> _runs = [];
  bool _runsLoading = false;

  List<RunSummary> get runs => _runs;
  bool get runsLoading => _runsLoading;

  // ── Problems ──────────────────────────────────────────────────────
  List<dynamic> _problems = [];
  bool _problemsLoading = false;

  List<dynamic> get problems => _problems;
  bool get problemsLoading => _problemsLoading;

  // ── Production Sessions ───────────────────────────────────────────
  List<dynamic> _productionSessions = [];
  bool _sessionsLoading = false;

  List<dynamic> get productionSessions => _productionSessions;
  bool get sessionsLoading => _sessionsLoading;

  // ── Workshop Plans ────────────────────────────────────────────────
  List<dynamic> _workshopPlans = [];
  bool _plansLoading = false;

  List<dynamic> get workshopPlans => _workshopPlans;
  bool get plansLoading => _plansLoading;

  int _selectedTabIndex = 0; // 0=Dashboard, 1=Gamme, 2=Nouveau calcul, etc.
  bool _sidebarCollapsed = false;

  int get selectedTabIndex => _selectedTabIndex;
  bool get sidebarCollapsed => _sidebarCollapsed;

  // ── Balance/Scenarios (legacy - standalone balance tab) ────────────
  ProjectData? projectData;
  double cycleTime = 1.5;
  String solver = 'rpw';
  String objective = 'min_stations';
  int timeLimit = 30;
  BalanceResult? balanceResult;
  bool balanceLoading = false;
  String? balanceError;

  // ── Auth Methods ──────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    try {
      final success = await _api.login(email, password);
      if (success) {
        _accessToken = _api.accessToken;
        _currentUser = _api.currentUser;
        _isSuperAdmin = _currentUser?.role == 'super_admin' ||
            _currentUser?.email == 'belloumi.karim.professional@gmail.com';
        await _loadOrganizations();
        if (_organizations.isNotEmpty) {
          _selectedOrg = _organizations.first;
          await _loadDashboardData();
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> loadUserData() async {
    if (_accessToken == null) return;
    final user = await _api.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  void logout() {
    _accessToken = null;
    _currentUser = null;
    _isSuperAdmin = false;
    _organizations = [];
    _selectedOrg = null;
    _productionLines = [];
    _runs = [];
    _problems = [];
    _workshopPlans = [];
    _productionSessions = [];
    _api.logout();
    notifyListeners();
  }

  // ── Organization Management ───────────────────────────────────────
  Future<void> _loadOrganizations() async {
    try {
      _organizations = await _api.getOrganizations();
      if (_selectedOrg == null && _organizations.isNotEmpty) {
        _selectedOrg = _organizations.first;
      }
    } catch (e) {
      debugPrint('Load organizations error: $e');
    }
  }

  void selectOrg(dynamic org) {
    _selectedOrg = org;
    _loadDashboardData();
    notifyListeners();
  }

  // ── Dashboard Data ────────────────────────────────────────────────
  Future<void> _loadDashboardData() async {
    if (_selectedOrg == null) return;
    await Future.wait([
      _loadProductionLines(),
      _loadRuns(),
      _loadProblems(),
      _loadWorkshopPlans(),
      _loadProductionSessions(),
    ]);
  }

  Future<void> _loadProductionLines() async {
    if (_selectedOrg == null) return;
    _linesLoading = true;
    notifyListeners();
    try {
      _productionLines = await _api.getProductionLines(_selectedOrg!.id);
    } catch (e) {
      debugPrint('Load lines error: $e');
    } finally {
      _linesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRuns() async {
    if (_selectedOrg == null) return;
    _runsLoading = true;
    notifyListeners();
    try {
      _runs = await _api.getRuns(_selectedOrg!.id);
    } catch (e) {
      debugPrint('Load runs error: $e');
    } finally {
      _runsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProblems() async {
    if (_selectedOrg == null) return;
    _problemsLoading = true;
    notifyListeners();
    try {
      _problems = await _api.getProblems(_selectedOrg!.id);
    } catch (e) {
      debugPrint('Load problems error: $e');
    } finally {
      _problemsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadWorkshopPlans() async {
    if (_selectedOrg == null) return;
    _plansLoading = true;
    notifyListeners();
    try {
      _workshopPlans = await _api.getWorkshopPlans(_selectedOrg!.id);
    } catch (e) {
      debugPrint('Load workshop plans error: $e');
    } finally {
      _plansLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProductionSessions() async {
    if (_selectedOrg == null) return;
    _sessionsLoading = true;
    notifyListeners();
    try {
      _productionSessions = await _api.getProductionSessions(_selectedOrg!.id);
    } catch (e) {
      debugPrint('Load production sessions error: $e');
    } finally {
      _sessionsLoading = false;
      notifyListeners();
    }
  }

  // ── Production Line Actions ──────────────────────────────────────
  Future<void> addProductionLine(ProductionLine line) async {
    if (_selectedOrg == null) return;
    try {
      final created = await _api.createProductionLine(_selectedOrg!.id, line);
      _productionLines.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('Add line error: $e');
      rethrow;
    }
  }

  Future<void> deleteProductionLine(String lineId) async {
    if (_selectedOrg == null) return;
    try {
      await _api.deleteProductionLine(_selectedOrg!.id, lineId);
      _productionLines.removeWhere((l) => l.id == lineId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete line error: $e');
      rethrow;
    }
  }

  Future<void> runCalculationForLine(String lineId) async {
    if (_selectedOrg == null) return;
    debugPrint('Run calculation for line: $lineId');
  }

  // ── Problems ──────────────────────────────────────────────────────
  Future<void> createProblem(dynamic request) async {
    if (_selectedOrg == null) return;
    try {
      final created = await _api.createProblem(_selectedOrg!.id, request);
      _problems.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('Create problem error: $e');
      rethrow;
    }
  }

  // ── Workshop Plans ────────────────────────────────────────────────
  Future<void> addWorkshopPlan(WorkshopPlan plan) async {
    if (_selectedOrg == null) return;
    try {
      final created = await _api.createWorkshopPlan(_selectedOrg!.id, plan);
      _workshopPlans.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('Add workshop plan error: $e');
      rethrow;
    }
  }

  Future<void> updateWorkshopPlan(String planId, Map<String, dynamic> updates) async {
    if (_selectedOrg == null) return;
    try {
      final updated = await _api.updateWorkshopPlan(_selectedOrg!.id, planId, updates);
      final idx = _workshopPlans.indexWhere((p) => p.id == planId);
      if (idx >= 0) {
        _workshopPlans[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update workshop plan error: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkshopPlan(String planId) async {
    if (_selectedOrg == null) return;
    try {
      await _api.deleteWorkshopPlan(_selectedOrg!.id, planId);
      _workshopPlans.removeWhere((p) => p.id == planId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete workshop plan error: $e');
      rethrow;
    }
  }

  // ── Production Sessions ───────────────────────────────────────────
  Future<void> loadProductionSessions() async {
    if (_selectedOrg == null) return;
    try {
      _productionSessions = await _api.getProductionSessions(_selectedOrg!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Load production sessions error: $e');
    }
  }

  Future<void> createProductionSession(ProductionSession session) async {
    if (_selectedOrg == null) return;
    try {
      final created = await _api.createProductionSession(_selectedOrg!.id, session);
      _productionSessions.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('Create production session error: $e');
      rethrow;
    }
  }

  Future<void> updateProductionSession(String sessionId, Map<String, dynamic> updates) async {
    if (_selectedOrg == null) return;
    try {
      final updated = await _api.updateProductionSession(_selectedOrg!.id, sessionId, updates);
      final idx = _productionSessions.indexWhere((s) => s.id == sessionId);
      if (idx >= 0) {
        _productionSessions[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update production session error: $e');
      rethrow;
    }
  }

  Future<void> deleteProductionSession(String sessionId) async {
    if (_selectedOrg == null) return;
    try {
      await _api.deleteProductionSession(_selectedOrg!.id, sessionId);
      _productionSessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete production session error: $e');
      rethrow;
    }
  }

  // ── Run Exports ───────────────────────────────────────────────────
  Future<Map<String, dynamic>?> exportRunJson(String runId) async {
    if (_selectedOrg == null) return null;
    try {
      return await _api.exportRunJson(_selectedOrg!.id, runId);
    } catch (e) {
      debugPrint('Export run JSON error: $e');
      return null;
    }
  }

  Future<List<int>?> exportRunXlsx(String runId) async {
    if (_selectedOrg == null) return null;
    try {
      return await _api.exportRunXlsx(_selectedOrg!.id, runId);
    } catch (e) {
      debugPrint('Export run XLSX error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> exportRunGantt(String runId) async {
    if (_selectedOrg == null) return null;
    try {
      return await _api.exportRunGantt(_selectedOrg!.id, runId);
    } catch (e) {
      debugPrint('Export run Gantt error: $e');
      return null;
    }
  }

  // ── Problem Import ────────────────────────────────────────────────
  Future<ImportOut?> importProblem({
    required String name,
    required double targetCycleTime,
    required List<int> samFile,
    List<int>? workstationsFile,
    List<int>? workersFile,
  }) async {
    if (_selectedOrg == null) return null;
    try {
      return await _api.importProblem(
        orgId: _selectedOrg!.id,
        name: name,
        targetCycleTime: targetCycleTime,
        samFile: samFile,
        workstationsFile: workstationsFile,
        workersFile: workersFile,
      );
    } catch (e) {
      debugPrint('Import problem error: $e');
      rethrow;
    }
  }

  // ── Organization Management (Super Admin) ─────────────────────────
  Future<Organization?> createOrganization(String name, String country) async {
    try {
      final org = await _api.createOrganization(name, country);
      _organizations.add(org);
      notifyListeners();
      return org;
    } catch (e) {
      debugPrint('Create organization error: $e');
      rethrow;
    }
  }

  Future<void> deleteOrganization(String orgId, String confirmName) async {
    try {
      await _api.deleteOrganization(orgId, confirmName);
      _organizations.removeWhere((o) => o.id == orgId);
      if (_selectedOrg?.id == orgId) {
        _selectedOrg = _organizations.isNotEmpty ? _organizations.first : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Delete organization error: $e');
      rethrow;
    }
  }

  // ── Solvers ───────────────────────────────────────────────────────
  Future<List<String>> getSolvers() async {
    try {
      return await _api.getSolvers();
    } catch (e) {
      debugPrint('Get solvers error: $e');
      return [];
    }
  }

  // ── Balance/Scenarios (Legacy - standalone balance tab) ───────────
  Future<void> runBalance() async {
    if (projectData == null) return;
    balanceLoading = true;
    balanceError = null;
    notifyListeners();
    try {
      debugPrint('Legacy runBalance called - use new API instead');
      balanceLoading = false;
    } catch (e) {
      balanceError = e.toString();
    } finally {
      balanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> runScenarios(List<double> cycleTimes) async {
    if (projectData == null) return;
    balanceLoading = true;
    balanceError = null;
    notifyListeners();
    try {
      debugPrint('Legacy runScenarios called - use new API instead');
      balanceLoading = false;
    } catch (e) {
      balanceError = e.toString();
    } finally {
      balanceLoading = false;
      notifyListeners();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────
  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
  }
}