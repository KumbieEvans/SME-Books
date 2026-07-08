import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';

class ReportChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String reportType;

  const ReportChartWidget({
    super.key,
    required this.data,
    required this.reportType,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for chart'));
    }

    // Process data for chart
    // For Income Statement, we might chart Revenue vs Expenses
    // For Balance Sheet, Assets vs Liabilities vs Equity

    Map<String, double> groupedData = {};
    for (var row in data) {
      final type = row['account_type'].toString();
      final balance = double.tryParse(row['balance']?.toString() ?? '0') ?? 0;
      
      if (groupedData.containsKey(type)) {
        groupedData[type] = groupedData[type]! + balance.abs();
      } else {
        groupedData[type] = balance.abs();
      }
    }

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    final colors = [
      AppTheme.primaryTeal,
      Colors.redAccent,
      Colors.orangeAccent,
      AppTheme.navyBlue,
      Colors.purpleAccent
    ];

    groupedData.forEach((key, value) {
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: value,
            title: '$key\n${value.toStringAsFixed(0)}',
            radius: 80,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
        colorIndex++;
      }
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}
