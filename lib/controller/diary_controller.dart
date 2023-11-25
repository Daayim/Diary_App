// lib/controller/diary_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/diary_entry_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class DiaryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _getUserEntriesCollectionPath(String userId) {
    return 'users/$userId/diary_entries';
  }

  Future<bool> addEntry(DiaryEntry entry, String userId) async {
    String collectionPath = _getUserEntriesCollectionPath(userId);
    // Check for existing entry with the same date
    var dateQuerySnapshot = await _firestore
        .collection(collectionPath)
        .where('date', isEqualTo: Timestamp.fromDate(entry.date))
        .get();

    if (dateQuerySnapshot.docs.isNotEmpty) {
      // An entry with this date already exists
      return false;
    }

    try {
      await _firestore
          .collection(collectionPath)
          .doc(entry.entryId)
          .set(entry.toFirestoreMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> removeEntry(String entryId, String userId) async {
    String collectionPath = _getUserEntriesCollectionPath(userId);
    DocumentSnapshot entrySnapshot =
        await _firestore.collection(collectionPath).doc(entryId).get();

    if (entrySnapshot.exists && entrySnapshot.data() != null) {
      DiaryEntry entry = DiaryEntry.fromFirestoreMap(
          entrySnapshot.data() as Map<String, dynamic>);
      // Delete associated images
      for (String imageUrl in entry.imageUrls) {
        await deleteImage(imageUrl);
      }
    }

    await _firestore.collection(collectionPath).doc(entryId).delete();
  }

  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    String collectionPath = _getUserEntriesCollectionPath(userId);
    // Query the entries, ordering them by date in descending order
    final querySnapshot = await _firestore
        .collection(collectionPath)
        .orderBy('date', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => DiaryEntry.fromFirestoreMap(doc.data()))
        .toList();
  }

  Future<bool> updateEntry(DiaryEntry entry, String userId) async {
    String collectionPath = _getUserEntriesCollectionPath(userId);
    try {
      // Check if a different entry exists on the new date
      var querySnapshot = await _firestore
          .collection(collectionPath)
          .where('date', isEqualTo: Timestamp.fromDate(entry.date))
          .get();

      bool hasConflictingEntry =
          querySnapshot.docs.any((doc) => doc.id != entry.entryId);

      if (hasConflictingEntry) {
        // Another entry with the same date exists
        return false;
      }

      // Update the entry
      await _firestore
          .collection(collectionPath)
          .doc(entry.entryId)
          .set(entry.toFirestoreMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> uploadImages(List<File> images, String userId) async {
    List<String> imageUrls = [];
    for (var image in images) {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      Reference ref = _storage
          .ref()
          .child('users/$userId/$fileName'); // Correct usage of Reference
      await ref.putFile(image); // Upload the file
      String imageUrl = await ref.getDownloadURL(); // Get the download URL
      imageUrls.add(imageUrl);
    }
    return imageUrls;
  }

  Future<void> deleteImage(String imageUrl) async {
    Reference ref = _storage.refFromURL(imageUrl); // Get the reference from URL
    await ref.delete(); // Delete the file
  }

  Future<void> deleteEntryImage(
      String entryId, String imageUrl, String userId) async {
    String collectionPath = _getUserEntriesCollectionPath(userId);

    // Remove the image URL from the Firestore document
    await _firestore.collection(collectionPath).doc(entryId).update({
      'imageUrls': FieldValue.arrayRemove([imageUrl])
    });

    // Delete the image file from Firebase Storage
    await deleteImage(imageUrl);
  }
}
