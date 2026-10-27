import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the daily quote fetched from Firestore's /dailyContent/quoteOfTheDay document.
class Quote {
  final String text;
  final String author;
  final Timestamp updatedAt;

  const Quote({
    required this.text,
    required this.author,
    required this.updatedAt,
  });

  /// Creates a [Quote] from a Firestore document snapshot.
  factory Quote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Quote(
      text: data['text'] as String? ?? '',
      author: data['author'] as String? ?? 'Desconhecido',
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Converts this [Quote] to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          author == other.author;

  @override
  int get hashCode => Object.hash(text, author);

  @override
  String toString() => 'Quote(text: $text, author: $author)';
}
