import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_model.dart';

/// A beautifully styled "frosted glass" card that displays a [Quote].
class QuoteCard extends StatelessWidget {
  final Quote quote;

  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large decorative opening quote mark
              Text(
                '\u201C',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 80,
                  height: 0.6,
                  color: Colors.white.withValues(alpha: 0.30),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Quote text
              Text(
                quote.text,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Author
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB388FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '\u2014 ${quote.author}',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: const Color(0xFFB388FF),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
