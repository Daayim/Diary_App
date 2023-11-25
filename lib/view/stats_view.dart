// lib/view/diary_stats_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/diary_entry_model.dart';
import '../controller/diary_controller.dart';

class DiaryStatsView extends StatefulWidget {
  final DiaryController controller;
  final String? userId;

  DiaryStatsView({required this.controller, this.userId});

  @override
  _DiaryStatsViewState createState() => _DiaryStatsViewState();
}

class _DiaryStatsViewState extends State<DiaryStatsView> {
  late Future<Map<String, DiaryStats>> statsFuture;

  @override
  void initState() {
    super.initState();
    statsFuture = _calculateStats();
  }

  Future<Map<String, DiaryStats>> _calculateStats() async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User not identified'),
      ));
      return {}; // or handle this case appropriately
    }
    List<DiaryEntry> entries =
        await widget.controller.getAllEntries(widget.userId!);
    Map<String, DiaryStats> stats = {};

    for (var entry in entries) {
      String monthYear = DateFormat('MMMM yyyy').format(entry.date);
      stats.putIfAbsent(monthYear, () => DiaryStats(0, 0));

      stats[monthYear]!.totalRating += entry.rating;
      stats[monthYear]!.entryCount++;
    }

    for (var key in stats.keys) {
      stats[key]!.averageRating =
          stats[key]!.totalRating / stats[key]!.entryCount;
    }

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Stats'),
      ),
      body: FutureBuilder<Map<String, DiaryStats>>(
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stats available.'));
          } else {
            var stats = snapshot.data!;
            return ListView.builder(
              itemCount: stats.length,
              itemBuilder: (context, index) {
                String monthYear = stats.keys.elementAt(index);
                DiaryStats monthStats = stats[monthYear]!;
                return ListTile(
                  title: Text(monthYear),
                  subtitle: Text(
                      'Average Rating: ${monthStats.averageRating.toStringAsFixed(2)}, Entries: ${monthStats.entryCount}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class DiaryStats {
  double totalRating;
  int entryCount;
  double averageRating = 0;

  DiaryStats(this.totalRating, this.entryCount);
}
