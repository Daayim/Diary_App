// lib/view/diary_log_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/diary_entry_model.dart';
import '../controller/diary_controller.dart';
import 'diary_entry_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'notification_view.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'login_view.dart';
import 'stats_view.dart';

class DiaryLogView extends StatefulWidget {
  final DiaryController controller;

  DiaryLogView({required this.controller});

  @override
  _DiaryLogViewState createState() => _DiaryLogViewState();
}

class _DiaryLogViewState extends State<DiaryLogView> {
  Future<List<DiaryEntry>>? entriesFuture;

  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _fetchEntries();
  }

  _fetchEntries() {
    if (userId != null) {
      entriesFuture = widget.controller.getAllEntries(userId!);
    }
  }

  pw.Document generatePDF(DiaryEntry entry) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Diary Entry',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(entry.date)}'),
            pw.Text('Description: ${entry.description}'),
            pw.Row(
              children: List.generate(
                entry.rating,
                (index) => pw.Text('★',
                    style: pw.TextStyle(color: PdfColors.yellow, fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => SignInView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Log'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<DiaryEntry>>(
        future: entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading indicator until the entries are loaded
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              // Center widget wraps the Text widget
              child: Text(
                'No entries found.',
                style: TextStyle(
                  // Adjust the text's size using TextStyle
                  fontSize: 20.0, // For example, setting the size to 20
                ),
              ),
            );
          } else {
            final entries = snapshot.data!;
            // Display list of entries
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  margin: const EdgeInsets.all(8.0), // Outer spacing
                  padding: const EdgeInsets.all(10.0), // Inner spacing
                  decoration: BoxDecoration(
                    border: Border.all(
                        color:
                            const Color.fromARGB(255, 0, 0, 0)), // Border color
                    borderRadius:
                        BorderRadius.circular(10.0), // Rounded corners
                  ),
                  child: ListTile(
                    title: Text(entry.description),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(entry.date)),
                    onLongPress: () async {
                      final edited = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DiaryEntryView(
                                    controller: widget.controller,
                                    editingEntry: entry,
                                    userId: userId,
                                  )));
                      if (edited != null && edited == true) {
                        setState(() {
                          _fetchEntries(); // Fetch entries again
                        });
                      }
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Display stars for rating
                        ...List.generate(
                            entry.rating,
                            (index) => const Icon(Icons.star,
                                color: Colors.yellow, size: 20.0)),
                        const SizedBox(
                            width: 10), // Spacer between stars and delete icon
                        // Delete icon button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            await widget.controller
                                .removeEntry(entry.entryId, userId!);
                            setState(() {
                              _fetchEntries(); // Refresh the list after deletion
                            });
                          },
                        ),
                        // Print icon button
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.grey),
                          onPressed: () {
                            final pdf = generatePDF(entry);
                            Printing.layoutPdf(
                              onLayout: (PdfPageFormat format) async =>
                                  pdf.save(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        // Stats Button
        Positioned(
          right: 0,
          bottom: 140.0, // Adjust the position
          child: FloatingActionButton(
            heroTag: 'statsButton',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DiaryStatsView(
                          controller: widget.controller,
                          userId: userId,
                        )),
              );
            },
            child: Icon(Icons.bar_chart),
            tooltip: 'Diary Stats',
          ),
        ),
        // Set Notification Button
        Positioned(
          right: 0,
          bottom: 70.0, // Adjust the position
          child: FloatingActionButton(
            heroTag: 'setNotificationButton',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SetNotificationView()),
              );
            },
            child: Icon(Icons.notifications),
            tooltip: 'Set Reminder',
          ),
        ),
        // Add Entry Button
        Positioned(
          right: 0,
          bottom: 0,
          child: FloatingActionButton(
            heroTag: 'addButton',
            onPressed: () async {
              final added = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiaryEntryView(
                            controller: widget.controller,
                            userId: userId,
                          )));
              if (added != null && added == true) {
                setState(() {
                  _fetchEntries(); // Fetch entries again
                });
              }
            },
            child: Icon(Icons.add),
            tooltip: 'Add Entry',
          ),
        ),
      ],
    );
  }
}
