import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/saved_quote_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_background.dart';

/// Displays the current user's personally saved quotes.
///
/// Redirects to home if the user is not logged in.
class SavedQuotesScreen extends StatefulWidget {
  const SavedQuotesScreen({super.key});

  @override
  State<SavedQuotesScreen> createState() => _SavedQuotesScreenState();
}

class _SavedQuotesScreenState extends State<SavedQuotesScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Redirect unauthenticated users after frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authService.currentUser == null) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  Future<void> _deleteQuote(String quoteId) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestoreService.deleteQuote(uid, quoteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Citação removida.',
                style: GoogleFonts.lato(color: Colors.white)),
            backgroundColor: Colors.deepPurple.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D0B60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remover citação?',
            style: GoogleFonts.playfairDisplay(color: Colors.white)),
        content: Text(
          'Esta citação será removida das suas favoritas.',
          style: GoogleFonts.lato(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                Text('Cancelar', style: GoogleFonts.lato(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Remover',
                style: GoogleFonts.lato(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Minhas Citações Salvas',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A0533).withValues(alpha: 0.95),
                const Color(0xFF0D1B6E).withValues(alpha: 0.70),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: GradientBackground(
        child: StreamBuilder<List<SavedQuote>>(
          stream: _firestoreService.savedQuotesStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB388FF),
                  strokeWidth: 2.5,
                ),
              );
            }
            if (snapshot.hasError) {
              return _buildErrorState();
            }
            final quotes = snapshot.data ?? [];
            if (quotes.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              color: const Color(0xFFB388FF),
              backgroundColor: const Color(0xFF2D0B60),
              onRefresh: () async {
                // Stream auto-refreshes; just small delay for UX
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                itemCount: quotes.length,
                itemBuilder: (context, index) {
                  final q = quotes[index];
                  return _buildQuoteTile(q);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuoteTile(SavedQuote q) {
    final formattedDate = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR')
        .format(q.savedAt.toDate());

    return Dismissible(
      key: Key(q.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _deleteQuote(q.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\u201C${q.text}\u201D',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 2.5,
                    height: 16,
                    color: const Color(0xFFB388FF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '\u2014 ${q.author}',
                      style: GoogleFonts.lato(
                        color: const Color(0xFFB388FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      final confirm = await _confirmDelete(context);
                      if (confirm == true) _deleteQuote(q.id);
                    },
                    tooltip: 'Remover',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bookmark_outlined,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Salva em $formattedDate',
                    style: GoogleFonts.lato(
                        fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              ),
              child: const Icon(Icons.bookmark_border,
                  color: Colors.white38, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma citação salva',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Toque no coração na tela inicial\npara salvar citações que te inspiram.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: Colors.white54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFFB388FF)),
              label: Text('Voltar ao início',
                  style: GoogleFonts.lato(color: const Color(0xFFB388FF))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFB388FF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              'Ocorreu um erro',
              style: GoogleFonts.playfairDisplay(
                  color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível carregar suas citações.',
              style: GoogleFonts.lato(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
