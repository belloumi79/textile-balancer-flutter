/// Global application state matching the web dashboard.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'api.dart';

class AppState extends ChangeNotifier {
  final ApiClient _api = ApiClient();

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
  List<dynamic> _runs = [];
  bool _runsLoading = false;

  List<dynamic> get runs => _runs;
  bool get runsLoading => _runsLoading;

  // ── Problems ──────────────────────────────────────────────────────
  List<dynamic> _problems = [];
  bool _problemsLoading = false;

  List<dynamic> get problems => _problems;
  bool get problemsLoading => _problemsLoading;

  // ── Workshop Plans ────────────────────────────────────────────────
  List<dynamic> _workshopPlans = [];
  bool _plansLoading = false;

  List<dynamic> get workshopPlans => _workshopPlans;
  bool get plansLoading => _plansLoading;

  // ── UI State ──────────────────────────────────────────────────────
  int _selectedTabIndex = 0; // 0=Dashboard, 1=Gamme, 2=Nouveau calcul, etc.
  bool _sidebarCollapsed = false;

  int get selectedTabIndex => _selectedTabIndex;
  bool get sidebarCollapsed => _sidebarCollapsed;

  // ── Balance/Scenarios (legacy - standalone balance tab) ────────────
  Map<String, dynamic>? projectData;
  double cycleTime = 1.5;
  String solver = 'rpw';
  String objective = 'min_stations';
  int timeLimit = 30;
  Map<String, dynamic>? balanceResult;
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
      _linesLoading = false;
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

  // ── Production Line Actions ──────────────────────────────────────
  Future<void> addProductionLine(dynamic line) async {
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

  Future<void> runBalanceForLine(String lineId) async {
    if (_selectedOrg == null) return;
    debugPrint('Run balance for line: $lineId');
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
  Future<void> addWorkshopPlan(dynamic plan) async {
    if (_selectedOrg == null) return;
    try {
      final created = await _api.getWorkshopPlan(_selectedOrg!.id, plan.id);
      _workshopPlans.insert(0, created);
      notifyListeners();
    } catch (e) {
      debugPrint('Add workshop plan error: $e');
      rethrow;
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