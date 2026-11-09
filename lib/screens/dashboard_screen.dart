/// Dashboard Screen - Exact copy of web dashboard with tabs, entity dropdown, production lines, history table
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _lineNameCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _cadenceCtrl = TextEditingController();

  static const _tabs = [
    'Tableau de bord',
    'Gamme',
    'Nouveau calcul',
    'Historique',
    'Production',
    'Jumeau numérique',
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
                _buildDashboardTab(state),     // 0 Tableau de bord
                _buildPlaceholderTab('Gamme'), // 1
                _buildPlaceholderTab('Nouveau calcul'), // 2
                _buildHistoryTab(state),       // 3 Historique
                _buildPlaceholderTab('Production'), // 4
                _buildPlaceholderTab('Jumeau numérique'), // 5
                _buildPlaceholderTab('Plan de l\'atelier'), // 6
                _buildPlaceholderTab('Atelier'), // 7
                _buildPlaceholderTab('Super admin'), // 8
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
        children: [
          _buildLogo(),
          const SizedBox(width: 24),
          _buildTabBar(),
        ],
      ),
      actions: [
        _buildEntityDropdown(state),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => state.logout(),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Déconnexion'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFEAECF0),
        ),
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
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
              state.selectedOrg?.name ?? 'Sélectionner',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF667085)),
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
          const Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF6941C6)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Super admin : accès illimité à toutes les fonctionnalités, sans essai ni quota.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6941C6), fontWeight: FontWeight.w500),
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
        child: Text('Sélectionnez une organisation', style: TextStyle(color: Color(0xFF667085))),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF667085))),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF101828)),
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
            const Icon(Icons.factory_outlined, size: 48, color: Color(0xFFD0D5DD)),
            const SizedBox(height: 16),
            const Text(
              'Aucune ligne de production',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF344054)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première ligne pour commencer les calculs d\'équilibrage.',
              style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddLineDialogBottomSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer une ligne'),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF101828)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.product} · Cadence cible : ${line.targetCycleTime.toStringAsFixed(1)} min',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    backgroundColor: const Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _confirmDeleteLine(line, state),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFF04438)),
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
        content: Text('Supprimer "${line.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await state.deleteProductionLine(line.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF04438)),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF101828)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _tabController.animateTo(3), // Go to Historique tab
              child: const Text('Tout l\'historique'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.runsLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (state.runs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.history, size: 48, color: Color(0xFFD0D5DD)),
                  const SizedBox(height: 16),
                  const Text('Aucun calcul récent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Les calculs apparaîtront ici après exécution.', style: TextStyle(color: Color(0xFF667085))),
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
                SizedBox(width: 80, child: Text('Solveur', style: _headerStyle)),
                SizedBox(width: 100, child: Text('Statut', style: _headerStyle)),
                SizedBox(width: 70, child: Text('Stations', style: _headerStyle)),
                SizedBox(width: 80, child: Text('Cycle (min)', style: _headerStyle)),
                SizedBox(width: 80, child: Text('Rendement', style: _headerStyle)),
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
          SizedBox(width: 140, child: Text(fmt.format(r.createdAt), style: const TextStyle(fontSize: 13))),
          SizedBox(width: 100, child: Text(r.kind, style: const TextStyle(fontSize: 13))),
          SizedBox(width: 80, child: Text(r.solver, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.statusColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 70, child: Text('${r.stationsUsed ?? 0}', style: const TextStyle(fontSize: 13))),
          SizedBox(width: 80, child: Text(r.actualCycleTime?.toStringAsFixed(1) ?? '-', style: const TextStyle(fontSize: 13))),
          SizedBox(width: 80, child: Text('${r.efficiency?.toStringAsFixed(1) ?? '-'}%', style: const TextStyle(fontSize: 13))),
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
        title: Text('Détail du calcul - ${r.id}'),
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
              _detailRow('Cycle', '${r.actualCycleTime?.toStringAsFixed(1) ?? '-'} min'),
              _detailRow('Rendement', '${r.efficiency?.toStringAsFixed(1) ?? '-'}%'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Color(0xFF667085)))),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF101828)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tous vos calculs d\'équilibrage et de cadence.',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 24),
          _buildHistoryTable(state.runs),
        ],
      ),
    );
  }

  // ── Placeholder tabs ─────────────────────────────────────────────
  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForTab(title), size: 64, color: const Color(0xFFD0D5DD)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF344054)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cette fonctionnalité sera disponible prochainement.',
            style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTab(String title) {
    switch (title) {
      case 'Gamme': return Icons.route;
      case 'Nouveau calcul': return Icons.calculate;
      case 'Production': return Icons.production_quantity_limits;
      case 'Jumeau numérique': return Icons.memory;
      case 'Plan de l\'atelier': return Icons.map;
      case 'Atelier': return Icons.factory;
      case 'Super admin': return Icons.admin_panel_settings;
      default: return Icons.dashboard;
    }
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
                  const Text('Ajouter une ligne', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lineNameCtrl,
                decoration: const InputDecoration(labelText: 'Nom de la ligne', hintText: 'ex: Dos'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _productCtrl,
                decoration: const InputDecoration(labelText: 'Produit', hintText: 'ex: PANTALON THEO'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cadenceCtrl,
                decoration: const InputDecoration(labelText: 'Cadence cible (min)', hintText: 'ex: 5'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final cadence = double.tryParse(_cadenceCtrl.text);
                        if (_lineNameCtrl.text.isEmpty || _productCtrl.text.isEmpty || cadence == null) return;
                        final state = context.read<AppState>();
                        try {
                          await state.addProductionLine(ProductionLine(
                            id: '',
                            orgId: state.selectedOrg!.id,
                            name: _lineNameCtrl.text.trim(),
                            product: _productCtrl.text.trim(),
                            targetCycleTime: cadence,
                            createdBy: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ));
                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                          }
                        }
                      },
                      child: const Text('Créer'),
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
}