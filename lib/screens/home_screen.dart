import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quote_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/quote_card.dart';

/// The main screen of ZenMind — shows the daily quote.
///
/// Accessible without authentication. Saving a quote or viewing the saved list
/// requires the user to be logged in.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Quote? _currentQuote;
  bool _isSaving = false;

  late final Stream<Quote?> _quoteStream;
  late AnimationController _bgAnimController;

  // Floating decorative circles
  final List<_FloatingCircle> _circles = List.generate(6, (i) {
    final rng = Random(i * 42);
    return _FloatingCircle(
      left: rng.nextDouble(),
      top: rng.nextDouble(),
      size: 60 + rng.nextDouble() * 120,
      opacity: 0.03 + rng.nextDouble() * 0.06,
    );
  });

  @override
  void initState() {
    super.initState();
    _quoteStream = _firestoreService.quoteOfTheDayStream();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  Future<void> _saveQuote() async {
    final user = _authService.currentUser;
    if (user == null) {
      Navigator.of(context).pushNamed('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Faça login para salvar citações',
              style: GoogleFonts.lato(color: Colors.white)),
          backgroundColor: const Color(0xFF4A148C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_currentQuote == null) return;

    final alreadySaved =
        await _firestoreService.isQuoteSaved(user.uid, _currentQuote!);
    if (alreadySaved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esta citação já está salva! ✨',
                style: GoogleFonts.lato(color: Colors.white)),
            backgroundColor: Colors.deepPurple.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firestoreService.saveQuote(user.uid, _currentQuote!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Citação salva com sucesso! 💜',
                style: GoogleFonts.lato(color: Colors.white)),
            backgroundColor: Colors.deepPurple.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Ver salvas',
              textColor: const Color(0xFFB388FF),
              onPressed: () => Navigator.of(context).pushNamed('/saved'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyQuoteToClipboard() {
    if (_currentQuote == null) return;
    final text = '"${_currentQuote!.text}" — ${_currentQuote!.author}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Citação copiada! 📋',
            style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: Colors.deepPurple.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showZenMoment() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D0B60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.spa_outlined, color: Color(0xFFB388FF), size: 24),
            const SizedBox(width: 10),
            Text(
              'Momento de Reflexão',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Respire fundo e tome um instante para você:',
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            _zenTipRow('🌬️', 'Inspire profundamente contando até 4.'),
            const SizedBox(height: 10),
            _zenTipRow('⏸️', 'Segure o ar suavemente por 2 segundos.'),
            const SizedBox(height: 10),
            _zenTipRow('🍃', 'Expire devagar, liberando qualquer tensão.'),
            const SizedBox(height: 14),
            Text(
              'Deixe esta sabedoria guiar o seu dia com tranquilidade e propósito.',
              style: GoogleFonts.lato(
                color: const Color(0xFFB388FF),
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Gratidão 🙏', style: GoogleFonts.lato(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _zenTipRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(user),
          body: GradientBackground(
            child: Stack(
              children: [
                // Decorative floating circles
                ..._circles.map((c) => _buildFloatingCircle(c)),
                // Main content
                SafeArea(
                  child: StreamBuilder<Quote?>(
                    stream: _quoteStream,
                    builder: (context, quoteSnap) {
                      if (quoteSnap.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }
                      if (quoteSnap.hasError) {
                        return _buildErrorState();
                      }
                      final quote = quoteSnap.data;
                      if (quote == null) {
                        return _buildNoQuoteState();
                      }
                      // Keep local reference updated for saving
                      _currentQuote = quote;
                      return _buildQuoteContent(quote, user);
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(user),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(User? user) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A0533).withValues(alpha: 0.95),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.self_improvement, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'ZenMind',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (user != null) ...[
          // Saved quotes button
          IconButton(
            icon: const Icon(Icons.bookmark_outline, color: Colors.white),
            tooltip: 'Citações salvas',
            onPressed: () => Navigator.of(context).pushNamed('/saved'),
          ),
          // User avatar / logout
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7B1FA2),
              child: Text(
                (user.email?.isNotEmpty == true)
                    ? user.email![0].toUpperCase()
                    : 'U',
                style: GoogleFonts.lato(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            color: const Color(0xFF2D0B60),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              if (value == 'logout') {
                await _authService.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Até logo! 👋',
                          style: GoogleFonts.lato(color: Colors.white)),
                      backgroundColor: Colors.deepPurple.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'email',
                enabled: false,
                child: Text(
                  user.email ?? '',
                  style: GoogleFonts.lato(
                      color: Colors.white60, fontSize: 12),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text('Sair',
                        style: GoogleFonts.lato(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: Text('Entrar',
                style:
                    GoogleFonts.lato(color: Colors.white70, fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Criar conta',
                style: GoogleFonts.lato(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildQuoteContent(Quote quote, User? user) {
    final formattedDate = _formatTimestamp(quote.updatedAt.toDate());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Header label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFB388FF).withValues(alpha: 0.40)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFFB388FF), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Citação do Dia',
                        style: GoogleFonts.lato(
                          color: const Color(0xFFB388FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quote card
          QuoteCard(quote: quote),
          const SizedBox(height: 12),
          // Updated at timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                const Icon(Icons.update, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Citação atualizada em: $formattedDate',
                  style: GoogleFonts.lato(
                      color: Colors.white38, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Copy button
                Expanded(
                  child: _actionButton(
                    icon: Icons.copy_outlined,
                    label: 'Copiar',
                    onTap: _copyQuoteToClipboard,
                  ),
                ),
                const SizedBox(width: 12),
                // Zen Moment
                Expanded(
                  child: _actionButton(
                    icon: Icons.spa_outlined,
                    label: 'Momento Zen',
                    onTap: _showZenMoment,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Bottom info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12), width: 1),
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Uma nova dose de sabedoria e serenidade selecionada a cada dia para você.',
                      style: GoogleFonts.lato(
                        color: Colors.white60,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.lato(
                    color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(User? user) {
    return FloatingActionButton.extended(
      onPressed: _isSaving ? null : _saveQuote,
      backgroundColor: const Color(0xFF7B1FA2),
      elevation: 8,
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Icon(
              user != null ? Icons.favorite_border : Icons.login,
              color: Colors.white,
            ),
      label: Text(
        user != null ? 'Salvar citação' : 'Fazer login',
        style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: Color(0xFFB388FF),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Buscando a sabedoria do dia...',
            style: GoogleFonts.lato(
              color: Colors.white54,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            Text(
              'Ops! Algo deu errado',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar a citação.\nVerifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuoteState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_quote_rounded,
                color: Colors.white24, size: 80),
            const SizedBox(height: 20),
            Text(
              'Nenhuma citação disponível',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A citação do dia ainda não foi gerada.\nVolte mais tarde!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCircle(_FloatingCircle c) {
    return Positioned(
      left: c.left * MediaQuery.of(context).size.width,
      top: c.top * MediaQuery.of(context).size.height,
      child: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (_, _) {
          final offset = sin(_bgAnimController.value * pi) * 15;
          return Transform.translate(
            offset: Offset(0, offset),
            child: Container(
              width: c.size,
              height: c.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: c.opacity),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(dt);
  }
}

class _FloatingCircle {
  final double left;
  final double top;
  final double size;
  final double opacity;
  const _FloatingCircle({
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
  });
}
