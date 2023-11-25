// lib/view/diary_entry_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/diary_entry_model.dart';
import '../controller/diary_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

String generateEntryId(int length) {
  const characters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  Random random = Random();

  return String.fromCharCodes(Iterable.generate(
    length,
    (_) => characters.codeUnitAt(random.nextInt(characters.length)),
  ));
}

class DiaryEntryView extends StatefulWidget {
  final DiaryController controller;
  final DiaryEntry? editingEntry;
  final String? userId;

  DiaryEntryView({required this.controller, this.editingEntry, this.userId});

  @override
  _DiaryEntryViewState createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  TextEditingController descriptionController = TextEditingController();
  late DateTime selectedDate;
  String description = '';
  int rating = 1;
  String entryId = '';

  @override
  void initState() {
    super.initState();
    if (widget.editingEntry != null) {
      selectedDate = widget.editingEntry!.date;
      description = widget.editingEntry!.description;
      rating = widget.editingEntry!.rating;
      entryId = widget.editingEntry!.entryId;

      descriptionController.text = description;
    } else {
      DateTime now = DateTime.now();
      selectedDate = DateTime(now.year, now.month, now.day);
      entryId = generateEntryId(8);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Diary Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Date Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: () => _selectDate(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text(
                        'Selected date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                  ],
                ),
              ),
            ),

            // Description TextField
            TextField(
              maxLength: 140,
              controller: descriptionController,
              onChanged: (value) => description = value,
              decoration: const InputDecoration(
                  hintText: 'Enter your diary note (Max: 140 characters)'),
            ),

            // Rating Slider
            Slider(
              value: rating.toDouble(),
              onChanged: (newRating) {
                setState(() => rating = newRating.toInt());
              },
              divisions: 4,
              label: rating.toString(),
              min: 1,
              max: 5,
            ),

            // Pick Images Button
            Center(
              child: ElevatedButton(
                onPressed: _pickImages,
                child: const Text('Upload Images'),
              ),
            ),

            // Displaying Selected Images
            Wrap(
              spacing: 8.0,
              children: [
                // Display existing images with a network URL
                if (widget.editingEntry != null)
                  ...widget.editingEntry!.imageUrls.map((url) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.network(url, width: 100, height: 100),
                        IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () async {
                            await widget.controller
                                .deleteEntryImage(entryId, url, widget.userId!);
                            setState(() {
                              widget.editingEntry!.imageUrls.remove(url);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),

                // Display newly uploaded images
                ..._selectedImages.map((file) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.file(file, width: 100, height: 100),
                      IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _selectedImages.remove(file);
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            // Save Entry Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (description.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please add a description')));
                    return;
                  }

                  // Handling image URLs for new and existing images
                  final newImageUrls = await widget.controller
                      .uploadImages(_selectedImages, widget.userId!);
                  final allImageUrls =
                      List<String>.from(widget.editingEntry?.imageUrls ?? [])
                        ..addAll(newImageUrls);

                  final entry = DiaryEntry(
                    date: selectedDate,
                    entryId: entryId,
                    description: description,
                    rating: rating,
                    imageUrls: allImageUrls, // Merged image URLs
                  );

                  bool wasSaved;
                  if (widget.editingEntry != null) {
                    wasSaved = await widget.controller
                        .updateEntry(entry, widget.userId!);
                  } else {
                    wasSaved =
                        await widget.controller.addEntry(entry, widget.userId!);
                  }

                  if (!wasSaved) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Entry already exists on this date')));
                  } else {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}
