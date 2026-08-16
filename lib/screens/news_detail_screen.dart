import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/helpers.dart';
import 'game_detail_screen.dart';
import 'creator_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final News news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final DatabaseService _db = DatabaseService();
  late News _currentNews;
  Game? _relatedGame;
  Team? _teamMandante;
  Team? _teamVisitante;

  @override
  void initState() {
    super.initState();
    _currentNews = widget.news;
    _loadRelatedGame();
  }

  Future<void> _loadRelatedGame() async {
    final allGames = _db.getGames();
    final related = allGames.where((j) =>
        j.teamMandanteId == _currentNews.timeRelacionadoId ||
        j.teamVisitanteId == _currentNews.timeRelacionadoId).toList();
    
    if (related.isNotEmpty) {
      final lastGame = related.first; // Last related game
      final tM = await _db.getTeam(lastGame.teamMandanteId);
      final tV = await _db.getTeam(lastGame.teamVisitanteId);
      if (mounted) {
        setState(() {
          _relatedGame = lastGame;
          _teamMandante = tM;
          _teamVisitante = tV;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _relatedGame = null;
        });
      }
    }
  }

  Future<void> _refreshNews() async {
    final updated = await _db.getSingleNews(_currentNews.id!);
    if (updated != null && mounted) {
      setState(() {
        _currentNews = updated;
      });
      _loadRelatedGame();
    }
  }

  Future<void> _deleteNews() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Excluir Notícia', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir a notícia "${_currentNews.title}"?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteNews(_currentNews.id!);
      if (mounted) {
        Navigator.pop(context); // Return to home
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [

          // News Cover Photo
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: AppImage(src: _currentNews.photo, fit: BoxFit.cover),
            ),
          ),

          // Content body
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Related Match Widget if exists
                if (_relatedGame != null) _buildRelatedMatchWidget(),

                const SizedBox(height: 16),

                // Title
                Text(
                  _currentNews.title.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Body text
                Text(
                  _currentNews.body,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.6,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      
      // Top black gradient overlay for status bar contrast
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: MediaQuery.of(context).padding.top + 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black87,
                Colors.black54,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),

      // Floating Glassmorphic Back and Action buttons row
      Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Back Button with Blur
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),

            // Center Title (vertically aligned with height 48)
            SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  'NOTÍCIA',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Right: Edit & Delete Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Edit
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 22),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreatorScreen(news: _currentNews)),
                          );
                          _refreshNews();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                        onPressed: _deleteNews,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
);
}

  Widget _buildRelatedMatchWidget() {
    final game = _relatedGame!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameDetailScreen(game: game)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ÚLTIMO JOGO RELACIONADO',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_teamMandante != null)
                  AppImage(src: _teamMandante!.logo, width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Text(
                  '${game.placarM} x ${game.placarV}',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                if (_teamVisitante != null)
                  AppImage(src: _teamVisitante!.logo, width: 28, height: 28, fit: BoxFit.contain),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              game.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Saber mais >',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
