/// Dashboard Screen - Exact copy of web dashboard with tabs, entity dropdown, production lines, history table
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../models.dart';
import '../state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _lineNameCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _cadenceCtrl = TextEditingController();

  // Gamme tab controllers
  final _problemNameCtrl = TextEditingController();
  final _problemCycleCtrl = TextEditingController();
  bool _importingProblem = false;

  // Nouveau calcul tab controllers
  String _selectedSolver = 'cp_sat';
  String _selectedObjective = 'min_stations';
  int _timeLimit = 30;
  bool _runningCalculation = false;
  String? _calculationLineId;

  // Production tab controllers
  final _sessionLineIdCtrl = TextEditingController();
  final _sessionStatusCtrl = TextEditingController(text: 'running');
  bool _loadingSessions = false;

  static const _tabs = [
    'Tableau de bord',
    'Gamme',
    'Nouveau calcul',
    'Historique',
    'Production',
    'Jumeau numerique',
    'Plan de l\'atelier',
    'Atelier',
    'Super admin',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<AppState>().setTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lineNameCtrl.dispose();
    _productCtrl.dispose();
    _cadenceCtrl.dispose();
    _problemNameCtrl.dispose();
    _problemCycleCtrl.dispose();
    _sessionLineIdCtrl.dispose();
    _sessionStatusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          if (state.isSuperAdmin) _buildSuperAdminBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(state), // 0 Tableau de bord
                _buildGammeTab(state), // 1 Gamme
                _buildNouveauCalculTab(state), // 2 Nouveau calcul
                _buildHistoryTab(state), // 3 Historique
                _buildProductionTab(state), // 4 Production
                _buildJumeauNumeriqueTab(state), // 5 Jumeau numerique
                _buildPlaceholderTab('Plan de l\'atelier'), // 6
                _buildPlaceholderTab('Atelier'), // 7
                _buildSuperAdminTab(state), // 8 Super admin
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddLineDialogBottomSheet,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une ligne'),
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(AppState state) {
    return AppBar(
      title: Row(
        children: [_buildLogo(), const SizedBox(width: 24), _buildTabBar()],
      ),
      actions: [
        _buildEntityDropdown(state),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => state.logout(),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Deconnexion'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEAECF0)),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Center(
            child: Icon(Icons.bar_chart, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Line Balancer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 40,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF1E3A5F),
        unselectedLabelColor: const Color(0xFF667085),
        indicatorColor: const Color(0xFF1E3A5F),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildEntityDropdown(AppState state) {
    return PopupMenuButton<Organization>(
      initialValue: state.selectedOrg,
      onSelected: (e) => state.selectOrg(e),
      itemBuilder: (context) => state.organizations
          .map(
            (e) => PopupMenuItem<Organization>(
              value: e,
              child: Text(e.name, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.selectedOrg?.name ?? 'Selectionner',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAdminBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: const Color(0xFFF3F0FF),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings,
            size: 18,
            color: Color(0xFF6941C6),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Super admin : acces illimite a toutes les fonctionnalites, sans essai ni quota.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6941C6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Tableau de bord ──────────────────────────────────────
  Widget _buildDashboardTab(AppState state) {
    final org = state.selectedOrg;
    if (org == null) {
      return const Center(
        child: Text(
          'Selectionnez une organisation',
          style: TextStyle(color: Color(0xFF667085)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            org.name,
            'Vos lignes de production et vos derniers calculs.',
            action: ElevatedButton.icon(
              onPressed: _showAddLineDialogBottomSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouveau calcul'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildProductionLinesSection(state),
          const SizedBox(height: 24),
          _buildRecentCalculationsSection(state),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildProductionLinesSection(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lignes de production',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showAddLineDialogBottomSheet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter une ligne'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A5F),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.linesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.productionLines.isEmpty)
          _buildEmptyLinesCard()
        else
          ...state.productionLines.map((line) => _buildLineCard(line, state)),
      ],
    );
  }

  Widget _buildEmptyLinesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.factory_outlined,
              size: 48,
              color: Color(0xFFD0D5DD),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune ligne de production',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Creez votre premiere ligne pour commencer les calculs d\'equilibrage.',
              style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddLineDialogBottomSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Creer une ligne'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineCard(ProductionLine line, AppState state) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.product} · Cadence cible : ${line.targetCycleTime.toStringAsFixed(1)} min',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => state.runCalculationForLine(line.id),
                  icon: const Icon(Icons.calculate, size: 16),
                  label: const Text('Calculer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    backgroundColor: const Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _confirmDeleteLine(line, state),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF04438),
                  ),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLine(ProductionLine line, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la ligne'),
        content: Text(
          'Supprimer "${line.name}" ? Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await state.deleteProductionLine(line.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF04438),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCalculationsSection(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Derniers calculs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  _tabController.animateTo(3), // Go to Historique tab
              child: const Text('Tout l\'historique'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.runsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.runs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.history, size: 48, color: Color(0xFFD0D5DD)),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun calcul recent',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Les calculs apparaîtront ici apres execution.',
                    style: TextStyle(color: Color(0xFF667085)),
                  ),
                ],
              ),
            ),
          )
        else
          _buildHistoryTable(state.runs),
      ],
    );
  }

  Widget _buildHistoryTable(List<RunSummary> runs) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 140, child: Text('Date', style: _headerStyle)),
                SizedBox(width: 100, child: Text('Type', style: _headerStyle)),
                SizedBox(
                  width: 80,
                  child: Text('Solveur', style: _headerStyle),
                ),
                SizedBox(
                  width: 100,
                  child: Text('Statut', style: _headerStyle),
                ),
                SizedBox(
                  width: 70,
                  child: Text('Stations', style: _headerStyle),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Cycle (min)', style: _headerStyle),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Rendement', style: _headerStyle),
                ),
                SizedBox(width: 60, child: Text('Action', style: _headerStyle)),
              ],
            ),
          ),
          // Rows
          ...runs.map((r) => _buildHistoryRow(r, dateFormat)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF667085),
  );

  Widget _buildHistoryRow(RunSummary r, DateFormat fmt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              fmt.format(r.createdAt),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(r.kind, style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 80,
            child: Text(
              r.solver,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: r.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: r.statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${r.stationsUsed ?? 0}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              r.actualCycleTime?.toStringAsFixed(1) ?? '-',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${r.efficiency?.toStringAsFixed(1) ?? '-'}%',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 60,
            child: TextButton(
              onPressed: () => _showCalculationDetail(r),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Voir', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculationDetail(RunSummary r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detail du calcul - ${r.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Date', fmt.format(r.createdAt)),
              _detailRow('Type', r.kind),
              _detailRow('Solveur', r.solver),
              _detailRow('Statut', r.statusLabel),
              _detailRow('Stations', '${r.stationsUsed ?? 0}'),
              _detailRow(
                'Cycle',
                '${r.actualCycleTime?.toStringAsFixed(1) ?? '-'} min',
              ),
              _detailRow(
                'Rendement',
                '${r.efficiency?.toStringAsFixed(1) ?? '-'}%',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  static final DateFormat fmt = DateFormat('dd/MM/yyyy HH:mm');

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Tab 3: Historique (full history table) ────────────────────────
  Widget _buildHistoryTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique des calculs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tous vos calculs d\'equilibrage et de cadence.',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 24),
          _buildHistoryTable(state.runs),
        ],
      ),
    );
  }

  // ── Real Tab Implementations ───────────────────────────────────────

  // Tab 1: Gamme - Problem management (import, list, CRUD)
  Widget _buildGammeTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Gestion des gammes (SAM)',
            'Importez vos gammes, postes et ouvriers pour cr\u00e9er des probl\u00e8mes d\'equilibrage.',
            action: ElevatedButton.icon(
              onPressed: _showImportProblemDialog,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Importer une gamme'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildProblemsList(state),
        ],
      ),
    );
  }

  // Tab 2: Nouveau calcul - Balance/Min-Cycle configuration
  Widget _buildNouveauCalculTab(AppState state) {
    final lines = state.productionLines.whereType<ProductionLine>().toList();
    if (lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber,
              size: 64,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune ligne de production',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Creez une ligne dans le Tableau de bord pour lancer un calcul.',
              style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Nouveau calcul d\'equilibrage',
            'Configurez les parametres et lancez un equilibrage (RPW) ou un calcul de cadence min (Min-Cycle).',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProductionLine>(
                    value: _calculationLineId != null
                        ? lines.firstWhere(
                            (l) => l.id == _calculationLineId,
                            orElse: () => lines.first,
                          )
                        : lines.first,
                    items: lines
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              '${l.name} (${l.product}) - ${l.targetCycleTime.toStringAsFixed(1)} min',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _calculationLineId = v?.id),
                    decoration: const InputDecoration(
                      labelText: 'Ligne de production',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSolver,
                    items: const [
                      DropdownMenuItem(
                        value: 'rpw',
                        child: Text('RPW — Heuristique rapide'),
                      ),
                      DropdownMenuItem(
                        value: 'cp_sat',
                        child: Text('CP-SAT — Optimal (OR-Tools)'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedSolver = v!),
                    decoration: const InputDecoration(labelText: 'Solveur'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedObjective,
                    items: const [
                      DropdownMenuItem(
                        value: 'min_stations',
                        child: Text('Minimiser les stations'),
                      ),
                      DropdownMenuItem(
                        value: 'min_cycle_time',
                        child: Text('Minimiser le temps de cycle'),
                      ),
                      DropdownMenuItem(
                        value: 'max_efficiency',
                        child: Text('Maximiser le rendement'),
                      ),
                      DropdownMenuItem(
                        value: 'balance_workload',
                        child: Text('Équilibrer la charge'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedObjective = v!),
                    decoration: const InputDecoration(labelText: 'Objectif'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _timeLimit.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Limite solveur (secondes)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _timeLimit = int.tryParse(v) ?? 30,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _runningCalculation
                              ? null
                              : () => _runBalance(state),
                          icon: _runningCalculation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.calculate),
                          label: Text(
                            _runningCalculation
                                ? 'Calcul en cours...'
                                : 'Lancer l\'equilibrage',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _runningCalculation
                              ? null
                              : () => _runMinCycle(state),
                          icon: const Icon(Icons.speed),
                          label: const Text('Cadence min (Min-Cycle)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 4: Production - Session tracking
  Widget _buildProductionTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Suivi de production',
            'Demarrez, arrêtez et suivez vos sessions de production par ligne.',
            action: ElevatedButton.icon(
              onPressed: _showCreateSessionDialog,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Nouvelle session'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSessionsList(state),
        ],
      ),
    );
  }

  // Tab 5: Jumeau numerique - Workshop plans
  Widget _buildJumeauNumeriqueTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Jumeau numerique / Plans d\'atelier',
            'Visualisez et gerez vos plans d\'atelier 2D/3D.',
            action: ElevatedButton.icon(
              onPressed: _showCreateWorkshopPlanDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouveau plan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildWorkshopPlansGrid(state),
        ],
      ),
    );
  }

  // Tab 8: Super Admin - Organization management
  Widget _buildSuperAdminTab(AppState state) {
    if (!state.isSuperAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Color(0xFFD0D5DD)),
            const SizedBox(height: 16),
            const Text(
              'Acces reserve aux super-administrateurs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre compte n\'a pas les droits super-admin.',
              style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Administration des organisations',
            'Creez, gerez et supprimez les organisations (multi-tenant).',
            action: ElevatedButton.icon(
              onPressed: _showCreateOrgDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Creer organisation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildOrgsAdminTable(state),
        ],
      ),
    );
  }

  // ── Gamme Tab Components ───────────────────────────────────────────

  void _showImportProblemDialog() {
    _problemNameCtrl.clear();
    _problemCycleCtrl.text = '1.5';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer une gamme (SAM + Postes + Ouvriers)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _problemNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du probleme',
                  hintText: 'ex: Chemise Homme',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _problemCycleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cadence cible (min)',
                  hintText: '1.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selectionnez les fichiers CSV/Excel :',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _FilePickerRow(
                label: 'Fichier SAM (requis)',
                onPick: (f) => _samFile = f,
              ),
              _FilePickerRow(
                label: 'Fichier Postes (optionnel)',
                onPick: (f) => _workstationsFile = f,
              ),
              _FilePickerRow(
                label: 'Fichier Ouvriers (optionnel)',
                onPick: (f) => _workersFile = f,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _importingProblem
                ? null
                : () async {
                    if (_problemNameCtrl.text.isEmpty || _samFile == null)
                      return;
                    Navigator.pop(ctx);
                    setState(() => _importingProblem = true);
                    try {
                      final state = context.read<AppState>();
                      final result = await state.importProblem(
                        name: _problemNameCtrl.text.trim(),
                        targetCycleTime:
                            double.tryParse(_problemCycleCtrl.text) ?? 1.5,
                        samFile: _samFile!,
                        workstationsFile: _workstationsFile,
                        workersFile: _workersFile,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Probleme importe: ${result?.problemId ?? "OK"}',
                            ),
                          ),
                        );
                        _samFile = _workstationsFile = _workersFile = null;
                      }
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    } finally {
                      if (mounted) setState(() => _importingProblem = false);
                    }
                  },
            child: _importingProblem
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Importer'),
          ),
        ],
      ),
    );
  }

  List<int>? _samFile;
  List<int>? _workstationsFile;
  List<int>? _workersFile;

  Widget _buildProblemsList(AppState state) {
    if (state.problemsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.problems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Color(0xFFD0D5DD),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune gamme importee',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Importez votre premiere gamme SAM pour commencer.',
                style: TextStyle(color: Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showImportProblemDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Importer une gamme'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: state.problems
          .whereType<ProblemSummary>()
          .map(
            (p) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Cadence: ${p.targetCycleTime.toStringAsFixed(1)} min · ${p.operationsCount} operations',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer la gamme'),
                          content: Text('Supprimer "${p.name}" ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        // Note: delete problem API not implemented yet
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Nouveau Calcul Tab Components ──────────────────────────────────

  Future<void> _runBalance(AppState state) async {
    if (_calculationLineId == null) return;
    setState(() => _runningCalculation = true);
    try {
      final req = BalanceRequest(
        problemId: '', // Would need problem selection
        solver: _selectedSolver,
        objective: _selectedObjective,
        maxStations: _selectedObjective == 'min_stations' ? 50 : null,
        timeLimit: _timeLimit,
      );
      final job = await state.api.startBalance(state.selectedOrg!.id, req);
      // Poll job status
      _pollJob(state, job.jobId);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _runningCalculation = false);
    }
  }

  Future<void> _runMinCycle(AppState state) async {
    if (_calculationLineId == null) return;
    setState(() => _runningCalculation = true);
    try {
      final req = MinCycleRequest(
        problemId: '',
        solver: _selectedSolver,
        timeLimit: _timeLimit,
      );
      final job = await state.api.startMinCycle(state.selectedOrg!.id, req);
      _pollJob(state, job.jobId);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _runningCalculation = false);
    }
  }

  void _pollJob(AppState state, String jobId) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      final status = await state.api.getJobStatus(state.selectedOrg!.id, jobId);
      if (status.status == 'done' || status.status == 'failed') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status.status == 'done'
                    ? 'Calcul termine !'
                    : 'Échec: ${status.error}',
              ),
            ),
          );
        }
        return false;
      }
      return true;
    });
  }

  // ── Production Tab Components ──────────────────────────────────────

  void _showCreateSessionDialog() {
    _sessionLineIdCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle session de production'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProductionLine>(
              items: context
                  .read<AppState>()
                  .productionLines
                  .whereType<ProductionLine>()
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text('${l.name} (${l.product})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => _sessionLineIdCtrl.text = v?.id ?? '',
              decoration: const InputDecoration(
                labelText: 'Ligne de production',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: 'running',
              items: const [
                DropdownMenuItem(value: 'running', child: Text('En cours')),
                DropdownMenuItem(value: 'paused', child: Text('En pause')),
                DropdownMenuItem(value: 'completed', child: Text('Terminee')),
              ],
              onChanged: (v) => _sessionStatusCtrl.text = v ?? 'running',
              decoration: const InputDecoration(labelText: 'Statut initial'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (_sessionLineIdCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final state = context.read<AppState>();
                await state.createProductionSession(
                  ProductionSession(
                    id: '',
                    orgId: state.selectedOrg!.id,
                    lineId: _sessionLineIdCtrl.text,
                    startTime: DateTime.now(),
                    status: _sessionStatusCtrl.text,
                  ),
                );
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session creee')),
                  );
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: const Text('Creer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(AppState state) {
    if (state.productionSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.production_quantity_limits,
                size: 48,
                color: Color(0xFFD0D5DD),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune session de production',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creez votre premiere session pour suivre la production.',
                style: TextStyle(color: Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showCreateSessionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle session'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: state.productionSessions
          .whereType<ProductionSession>()
          .map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  'Session ${s.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Ligne: ${s.lineId} · Statut: ${s.status} · Debut: ${DateFormat('dd/MM HH:mm').format(s.startTime)}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'stop') {
                      await state.updateProductionSession(s.id, {
                        'status': 'completed',
                        'end_time': DateTime.now().toIso8601String(),
                      });
                    } else if (v == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer la session'),
                          content: const Text('Confirmer la suppression ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true)
                        await state.deleteProductionSession(s.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (s.status == 'running')
                      const PopupMenuItem(
                        value: 'stop',
                        child: Text('Arrêter'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Jumeau Numerique Tab Components ─────────────────────────────────

  void _showCreateWorkshopPlanDialog() {
    final nameCtrl = TextEditingController();
    final widthCtrl = TextEditingController(text: '30');
    final lengthCtrl = TextEditingController(text: '50');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau plan d\'atelier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'ex: Atelier Principal',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widthCtrl,
              decoration: const InputDecoration(
                labelText: 'Largeur (m)',
                hintText: '30',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lengthCtrl,
              decoration: const InputDecoration(
                labelText: 'Longueur (m)',
                hintText: '50',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final state = context.read<AppState>();
                final plan = WorkshopPlan(
                  id: '',
                  orgId: state.selectedOrg!.id,
                  name: nameCtrl.text.trim(),
                  version: '1.0',
                  widthM: double.tryParse(widthCtrl.text) ?? 30,
                  lengthM: double.tryParse(lengthCtrl.text) ?? 50,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await state.addWorkshopPlan(plan);
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Plan cree')));
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: const Text('Creer'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkshopPlansGrid(AppState state) {
    if (state.workshopPlans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.map, size: 48, color: Color(0xFFD0D5DD)),
              const SizedBox(height: 16),
              const Text(
                'Aucun plan d\'atelier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creez votre premier plan pour le jumeau numerique.',
                style: TextStyle(color: Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showCreateWorkshopPlanDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau plan'),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.workshopPlans.whereType<WorkshopPlan>().length,
      itemBuilder: (ctx, i) {
        final plan = state.workshopPlans.whereType<WorkshopPlan>().toList()[i];
        return Card(
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ouvrir ${plan.name} (placeholder)')),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.widthM.toStringAsFixed(0)} x ${plan.lengthM.toStringAsFixed(0)} m',
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await state.deleteWorkshopPlan(plan.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Super Admin Tab Components ──────────────────────────────────────

  void _showCreateOrgDialog() {
    final nameCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'TN');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Creer une organisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'ex: Usine Textile Alpha',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countryCtrl,
              decoration: const InputDecoration(
                labelText: 'Pays (code ISO)',
                hintText: 'TN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final state = context.read<AppState>();
                await state.createOrganization(
                  nameCtrl.text.trim(),
                  countryCtrl.text.trim().toUpperCase(),
                );
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Organisation creee')),
                  );
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: const Text('Creer'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgsAdminTable(AppState state) {
    final orgs = state.organizations.whereType<Organization>().toList();
    if (orgs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 48,
                color: Color(0xFFD0D5DD),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucune organisation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Creez la premiere organisation.',
                style: TextStyle(color: Color(0xFF667085)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showCreateOrgDialog,
                icon: const Icon(Icons.add),
                label: const Text('Creer organisation'),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    'Organisation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Pays',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    'Creee le',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Abonnement',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Action',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...orgs
              .map(
                (o) => (Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEAECF0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
                          o.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          o.country,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(o.createdAt),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          o.subscription?.status ?? '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'Supprimer l\'organisation',
                                  ),
                                  content: Text(
                                    'Confirmer en tapant: ${o.name}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Annuler'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true)
                                await state.deleteOrganization(o.id, o.name);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              )
              .toList(),
        ],
      ),
    );
  }

  // ── File Picker Helper ─────────────────────────────────────────────
  Widget _FilePickerRow({
    required String label,
    required Function(List<int>?) onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv', 'xlsx', 'xls', 'json'],
                withData: true,
              );
              if (result != null && result.files.isNotEmpty) {
                onPick(result.files.first.bytes);
              }
            },
            icon: const Icon(Icons.attach_file, size: 16),
            label: const Text('Choisir'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Line Dialog ──────────────────────────────────────────────
  void _showAddLineDialogBottomSheet() {
    _lineNameCtrl.clear();
    _productCtrl.clear();
    _cadenceCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Ajouter une ligne',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lineNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la ligne',
                  hintText: 'ex: Dos',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _productCtrl,
                decoration: const InputDecoration(
                  labelText: 'Produit',
                  hintText: 'ex: PANTALON THEO',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cadenceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cadence cible (min)',
                  hintText: 'ex: 5',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final cadence = double.tryParse(_cadenceCtrl.text);
                        if (_lineNameCtrl.text.isEmpty ||
                            _productCtrl.text.isEmpty ||
                            cadence == null)
                          return;
                        final state = context.read<AppState>();
                        try {
                          await state.addProductionLine(
                            ProductionLine(
                              id: '',
                              orgId: state.selectedOrg!.id,
                              name: _lineNameCtrl.text.trim(),
                              product: _productCtrl.text.trim(),
                              targetCycleTime: cadence,
                              createdBy: '',
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );
                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Creer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Placeholder tabs (for tabs 6, 7) ────────────────────────────────
  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForTab(title), size: 64, color: const Color(0xFFD0D5DD)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cette fonctionnalit\u00e9 sera disponible prochainement.',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTab(String title) {
    switch (title) {
      case 'Gamme':
        return Icons.route;
      case 'Nouveau calcul':
        return Icons.calculate;
      case 'Production':
        return Icons.production_quantity_limits;
      case 'Jumeau num\u00e9rique':
        return Icons.memory;
      case 'Plan de l\'atelier':
        return Icons.map;
      case 'Atelier':
        return Icons.factory;
      case 'Super admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.dashboard;
    }
  }
}
