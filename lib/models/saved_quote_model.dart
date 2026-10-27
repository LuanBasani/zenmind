import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a quote saved by a specific user in their personal collection.
class SavedQuote {
  final String id;
  final String text;
  final String author;
  final Timestamp savedAt;

  const SavedQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.savedAt,
  });

  /// Creates a [SavedQuote] from a Firestore document snapshot.
  factory SavedQuote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SavedQuote(
      id: doc.id,
      text: data['text'] as String? ?? '',
      author: data['author'] as String? ?? 'Desconhecido',
      savedAt: data['savedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Converts this [SavedQuote] to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'savedAt': savedAt,
    };
  }

  @override
  String toString() => 'SavedQuote(id: $id, text: $text, author: $author)';
}
