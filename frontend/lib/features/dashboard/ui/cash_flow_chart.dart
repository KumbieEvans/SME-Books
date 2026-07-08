import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../repositories/dashboard_repository.dart';

class CashFlowChartWidget extends StatefulWidget {
  const CashFlowChartWidget({super.key});

  @override
  State<CashFlowChartWidget> createState() => _CashFlowChartWidgetState();
}

class _CashFlowChartWidgetState extends State<CashFlowChartWidget> {
  late DashboardRepository _repository;
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(client: Supabase.instance.client);
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    try {
      final data = await _repository.getCashFlowForecast(30);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('Error loading chart: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_data.isEmpty) {
      return const Center(child: Text('No upcoming cash flow data.'));
    }

    // Convert data to FlSpot
    List<FlSpot> inflowSpots = [];
    List<FlSpot> outflowSpots = [];
    
    // We map dates to an x-axis integer (e.g., days offset from start)
    if (_data.isNotEmpty) {
      final startDate = DateTime.parse(_data.first['expected_date']);
      for (var row in _data) {
        final d = DateTime.parse(row['expected_date']);
        final daysDiff = d.difference(startDate).inDays.toDouble();
        final inflow = double.tryParse(row['expected_inflow'].toString()) ?? 0;
        final outflow = double.tryParse(row['expected_outflow'].toString()) ?? 0;
        
        inflowSpots.add(FlSpot(daysDiff, inflow));
        outflowSpots.add(FlSpot(daysDiff, outflow));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '30-Day Cash Flow Forecast',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyBlue),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5, // Show a label every 5 days
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Day ${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: inflowSpots,
                    isCurved: true,
                    color: AppTheme.primaryTeal,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: outflowSpots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(AppTheme.primaryTeal, 'Expected Inflows'),
              const SizedBox(width: 24),
              _buildLegend(Colors.redAccent, 'Expected Outflows'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
