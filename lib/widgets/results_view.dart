/// Widget d'affichage des résultats d'équilibrage.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models.dart';

class ResultsView extends StatelessWidget {
  final BalanceResult result;
  final bool loading;
  final String? error;

  const ResultsView({
    super.key,
    required this.result,
    required this.loading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _LoadingCard();
    }
    if (error != null) {
      return _ErrorCard(error: error!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Résultats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _KpiRow(result: result),
        const SizedBox(height: 16),
        _StationTable(result: result),
        const SizedBox(height: 16),
        if (result.recommendations.isNotEmpty) _RecommendationsCard(recommendations: result.recommendations),
        const SizedBox(height: 16),
        if (result.stationDetails.isNotEmpty) _YamazumiChart(result: result),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Résolution en cours...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF7F1D1D),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text('Erreur: $error', style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    ),
  );
}

class _KpiRow extends StatelessWidget {
  final BalanceResult result;
  const _KpiRow({required this.result});
  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiCard(label: 'Solveur', value: result.solverUsed.toUpperCase(), detail: result.status),
      _KpiCard(label: 'Stations', value: '${result.stationsUsed}'),
      _KpiCard(label: 'Cycle réel', value: '${result.actualCycleTime.toStringAsFixed(2)} min'),
      _KpiCard(label: 'Efficacité', value: '${result.efficiency.toStringAsFixed(1)}%'),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  const _KpiCard({required this.label, required this.value, this.detail});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (detail != null) Text(detail!, style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ),
    ),
  );
}

class _StationTable extends StatelessWidget {
  final BalanceResult result;
  const _StationTable({required this.result});
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Détail par poste', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Station')),
              DataColumn(label: Text('Temps (min)')),
              DataColumn(label: Text('Charge %')),
              DataColumn(label: Text('Opérations')),
              DataColumn(label: Text('Ouvriers')),
            ],
            rows: result.stationDetails.map((s) => DataRow(cells: [
              DataCell(Text('${s.station}')),
              DataCell(Text(s.totalTime.toStringAsFixed(2))),
              DataCell(Text('${s.loadPct.toStringAsFixed(1)}%')),
              DataCell(Text(s.operations.join(', '))),
              DataCell(Text(s.workers.join(', '))),
            ])).toList(),
          ),
        ),
      ],
    ),
  );
}

class _RecommendationsCard extends StatelessWidget {
  final List<Recommendation> recommendations;
  const _RecommendationsCard({required this.recommendations});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Recommandations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...recommendations.map((r) => _RecItem(rec: r)),
        ],
      ),
    ),
  );
}

class _RecItem extends StatelessWidget {
  final Recommendation rec;
  const _RecItem({required this.rec});
  Color _sevColor() => switch (rec.severity) {
    'critical' => Colors.redAccent,
    'warning' => Colors.orangeAccent,
    _ => Colors.blueAccent,
  };
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: _sevColor()),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${rec.category}: ${rec.message}', style: const TextStyle(fontSize: 13)),
              Text('→ ${rec.action}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _YamazumiChart extends StatelessWidget {
  final BalanceResult result;
  const _YamazumiChart({required this.result});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagramme Yamazumi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: result.stationDetails.map((s) => s.totalTime).reduce((a, b) => a > b ? a : b) * 1.2,
                  barGroups: result.stationDetails.asMap().entries.map((e) {
                    final idx = e.key;
                    final s = e.value;
                    return BarChartGroupData(x: idx + 1, barRods: [
                      BarChartRodData(toY: s.totalTime, width: 12, color: Colors.blueAccent, borderRadius: BorderRadius.circular(2)),
                    ]);
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}