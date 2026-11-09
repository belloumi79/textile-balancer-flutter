/// Écran de configuration + lancement de l'équilibrage.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets/results_view.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});
  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final _cycleCtrl = TextEditingController(text: '1.5');
  final _timeCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    _cycleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ Équilibrage'),
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
                  const Text('Paramètres de résolution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _field('Temps de cycle cible (min)', _cycleCtrl, (v) {
                    state.cycleTime = double.tryParse(v) ?? 1.5;
                  }),
                  const SizedBox(height: 12),
                  _field('Limite solveur (s)', _timeCtrl, (v) {
                    state.timeLimit = int.tryParse(v) ?? 30;
                  }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: state.solver,
                    items: const [
                      DropdownMenuItem(value: 'rpw', child: Text('RPW — heuristique rapide')),
                      DropdownMenuItem(value: 'cp_sat', child: Text('CP-SAT — optimal (OR-Tools)')),
                    ],
                    onChanged: (v) => setState(() => state.solver = v!),
                    decoration: const InputDecoration(border: UnderlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state.objective,
                    items: const [
                      DropdownMenuItem(value: 'min_stations', child: Text('Min stations')),
                      DropdownMenuItem(value: 'min_cycle_time', child: Text('Min cycle time')),
                      DropdownMenuItem(value: 'max_efficiency', child: Text('Max efficacité')),
                      DropdownMenuItem(value: 'balance_workload', child: Text('Équilibrage charge')),
                    ],
                    onChanged: (v) => setState(() => state.objective = v!),
                    decoration: const InputDecoration(border: UnderlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: state.balanceLoading ? null : state.runBalance,
                    icon: state.balanceLoading
                        ? const SizedBox(width: 16, height: 16, child: CassidySpinner())
                        : const Icon(Icons.play_arrow),
                    label: Text(state.balanceLoading ? 'Résolution en cours...' : 'Lancer l\'équilibrage'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.balanceResult != null) ResultsView(result: state.balanceResult!, loading: state.balanceLoading, error: state.balanceError),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, Function(String) onChange) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const UnderlineInputBorder()),
      keyboardType: TextInputType.number,
      onChanged: onChange,
    );
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