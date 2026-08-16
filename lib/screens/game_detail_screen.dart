import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/helpers.dart';
import 'creator_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final DatabaseService _db = DatabaseService();
  late Game _currentGame;
  Team? _teamMandante;
  Team? _teamVisitante;
  final GlobalKey _boundaryKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isLatestGame = true;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 80;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
    });
    _loadTeams();
    _checkIfLatest();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLatest() async {
    final allGames = _db.getGames();
    if (allGames.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLatestGame = _currentGame.id == allGames.first.id;
        });
      }
    }
  }

  Future<void> _loadTeams() async {
    final tM = await _db.getTeam(_currentGame.teamMandanteId);
    final tV = await _db.getTeam(_currentGame.teamVisitanteId);
    if (mounted) {
      setState(() {
        _teamMandante = tM;
        _teamVisitante = tV;
      });
    }
  }

  Future<void> _refreshGame() async {
    final updated = await _db.getGame(_currentGame.id!);
    if (updated != null && mounted) {
      setState(() {
        _currentGame = updated;
      });
      _loadTeams();
      _checkIfLatest();
    }
  }

  Future<void> _deleteGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Excluir Jogo', style: TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir o jogo "${_currentGame.title}"?', style: const TextStyle(color: Colors.grey)),
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
      await _db.deleteGame(_currentGame.id!);
      if (mounted) {
        Navigator.pop(context); // Return to home
      }
    }
  }

  Future<void> _shareCardImage() async {
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renderizando card de jogo...'), duration: Duration(seconds: 1)),
      );

      await Future.delayed(const Duration(milliseconds: 300)); // wait for layout

      RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/match_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Card da partida: ${_currentGame.title}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar imagem: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mandanteColor = _teamMandante != null ? HexColor(_teamMandante!.color) : const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // RepaintBoundary wrapping the exportable card content
                RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    color: Colors.black,
                    child: Column(
                      children: [
                        // Dynamic Header Gradient
                        _buildHeader(mandanteColor),

                        // Photo Slider / Carrossel
                        _buildPhotoCarousel(),

                        // Manchete and Summary
                        _buildHeadlineSection(),

                        // MVP section
                        if (_currentGame.mvpName.isNotEmpty) _buildMVPSection(),

                        // Timeline
                        if (_currentGame.eventos.isNotEmpty) _buildTimelineSection(),

                        // Match Specs
                        _buildSpecsSection(),
                      ],
                    ),
                  ),
                ),

                // Share button (outside the exportable card boundary)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton.icon(
                    onPressed: _shareCardImage,
                    icon: const Icon(Icons.share, color: Colors.black),
                    label: Text(
                      'COMPARTILHAR CARD NA GALERIA',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
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
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

                // Center Title / Score Pill (vertically aligned with height 48)
                SizedBox(
                  height: 48,
                  child: Center(
                    child: _isScrolled
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_teamMandante != null) ...[
                                      AppImage(src: _teamMandante!.logo, width: 24, height: 24, fit: BoxFit.contain),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '${_currentGame.placarM} x ${_currentGame.placarV}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_teamVisitante != null) ...[
                                      const SizedBox(width: 8),
                                      AppImage(src: _teamVisitante!.logo, width: 24, height: 24, fit: BoxFit.contain),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Text(
                            _isLatestGame ? 'ÚLTIMO JOGO' : 'JOGO',
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
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                MaterialPageRoute(builder: (context) => CreatorScreen(game: _currentGame)),
                              );
                              _refreshGame();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete
                    ClipOval(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                            onPressed: _deleteGame,
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

  Widget _buildHeader(Color headerColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            headerColor,
            Colors.black,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          // Spacer for floating header
          SizedBox(height: MediaQuery.of(context).padding.top + 28),

          // Scores & Crests
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mandante
              Expanded(
                child: Column(
                  children: [
                    if (_teamMandante != null)
                      AppImage(src: _teamMandante!.logo, width: 68, height: 68, fit: BoxFit.contain)
                    else
                      const SizedBox(height: 68),
                    const SizedBox(height: 8),
                    Text(
                      _teamMandante?.name ?? 'Mandante',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Placar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '${_currentGame.placarM} x ${_currentGame.placarV}',
                  style: GoogleFonts.montserrat(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),

              // Visitante
              Expanded(
                child: Column(
                  children: [
                    if (_teamVisitante != null)
                      AppImage(src: _teamVisitante!.logo, width: 68, height: 68, fit: BoxFit.contain)
                    else
                      const SizedBox(height: 68),
                    const SizedBox(height: 8),
                    Text(
                      _teamVisitante?.name ?? 'Visitante',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    if (_currentGame.photos.isEmpty) return const SizedBox();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: PageView.builder(
        itemCount: _currentGame.photos.length,
        itemBuilder: (context, index) {
          return AppImage(src: _currentGame.photos[index], fit: BoxFit.cover);
        },
      ),
    );
  }

  Widget _buildHeadlineSection() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Text(
            _currentGame.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentGame.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMVPSection() {
    // Format name to split first name and last names into separate lines
    String mvpNameFormatted = _currentGame.mvpName;
    List<String> nameParts = _currentGame.mvpName.split(' ');
    if (nameParts.length >= 2) {
      mvpNameFormatted = "${nameParts[0]}\n${nameParts.sublist(1).join(' ')}";
    }

    return Container(
      width: double.infinity,
      height: 280,
      color: Colors.black,
      child: Stack(
        children: [
          // 1. Giant Player Name (Behind the player image) - starts further left to be behind the player
          Positioned(
            top: 40,
            left: 80,
            right: 16,
            child: Text(
              mvpNameFormatted.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.85),
                height: 1.05,
              ),
            ),
          ),

          // 2. Player Cutout Image on the Left (Huge and taking full height)
          Positioned(
            bottom: 0,
            left: -20, // Shifted left to make room and look dynamic
            width: 220,
            height: 280, // Full height of the container
            child: _currentGame.mvpFoto.isNotEmpty
                ? ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Colors.white, Colors.transparent],
                        stops: [0.0, 0.75, 1.0], // Fade out the bottom 25%
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AppImage(
                        src: _currentGame.mvpFoto,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.person, size: 80, color: Colors.grey),
                  ),
          ),

          // 3. MVP Info Text (Bottom Right, next to the player)
          Positioned(
            bottom: 35,
            left: 170, // Shifted right to avoid overlapping the player's main body
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Melhor Jogador em Campo',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentGame.mvpJust,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRONOLOGIA',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _currentGame.eventos.map((ev) {
              final isMandante = ev.side == 'mandante';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: isMandante ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    if (!isMandante) const Spacer(),
                    _buildEventBubble(ev),
                    if (isMandante) const Spacer(),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBubble(MatchEvent ev) {
    IconData icon;
    Color iconColor;
    Widget? customIcon;

    final type = ev.type.toLowerCase();
    if (type.contains('gol') || type.contains('⚽')) {
      icon = Icons.sports_soccer;
      iconColor = Colors.white;
    } else if (type.contains('vermelho') || type.contains('🟥')) {
      icon = Icons.crop_portrait;
      iconColor = Colors.red;
      customIcon = Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)),
      );
    } else {
      icon = Icons.crop_portrait;
      iconColor = Colors.yellow;
      customIcon = Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(2)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF1C1C1E)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIcon ?? Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            "${ev.minute} ${ev.playerName}",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsSection() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MAIS INFORMAÇÕES',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Estádio', _currentGame.estadio),
          _buildSpecRow('Competição', _currentGame.competicao),
          _buildSpecRow('Fase', _currentGame.fase),
          _buildSpecRow('Árbitro', _currentGame.juiz),
          _buildSpecRow('Transmissão', _currentGame.transmissao),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
