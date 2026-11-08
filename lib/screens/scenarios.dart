/// Écran de comparaison de scénarios what-if (multiples temps de cycle).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';

class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});
  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  final _ctrl = TextEditingController(text: '1.0, 1.3, 1.5, 1.8, 2.0');

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Comparaison de scénarios'),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What-if : tester plusieurs temps de cycle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Séparer par virgules (ex: 1.0, 1.3, 1.5, 1.8, 2.0)', style: TextStyle(color: Color(0xFF667085))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Temps de cycle (min)',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: state.balanceLoading ? null : () => _run(state),
                    icon: state.balanceLoading
                        ? const SizedBox(width: 16, height: 16, child: CassidySpinner())
                        : const Icon(Icons.compare_arrows),
                    label: Text(state.balanceLoading ? 'Calcul...' : 'Lancer la comparaison'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.balanceResult != null) _ScenarioTable(result: state.balanceResult!),
        ],
      ),
    );
  }

  Future<void> _run(AppState state) async {
    final parts = _ctrl.text.split(',').map((s) => double.tryParse(s.trim())).whereType<double>().toList();
    if (parts.isEmpty) return;
    await state.runScenarios(parts);
  }
}

class CassidySpinner extends StatefulWidget {
  const CassidySpinner({super.key});
  @override
  State<CassidySpinner> createState() => _CassidySpinnerState();
}
class _CassidySpinnerState extends State<CassidySpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => RotationTransition(turns: _c, child: const Icon(Icons.autorenew, size: 16));
}

class _ScenarioTable extends StatelessWidget {
  final BalanceResult result;
  const _ScenarioTable({required this.result});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comparaison (API retourne headers/rows ; affichage simplifié)', style: TextStyle(color: Color(0xFF667085))),
            const SizedBox(height: 8),
            _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Stations')),
          DataColumn(label: Text('Cycle')),
          DataColumn(label: Text('Efficacité')),
          DataColumn(label: Text('Statut')),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text('${result.stationsUsed}')),
            DataCell(Text(result.actualCycleTime.toStringAsFixed(2))),
            DataCell(Text('${result.efficiency.toStringAsFixed(1)}%')),
            DataCell(Text(result.status)),
          ]),
        ],
      ),
    );
  }
}