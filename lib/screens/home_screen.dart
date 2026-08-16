import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/helpers.dart';
import 'game_detail_screen.dart';
import 'news_detail_screen.dart';
import 'creator_screen.dart';
import 'manage_screen.dart';

enum FeedMode { myFeed, jogos, news }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Game> _games = [];
  List<News> _news = [];
  Game? _heroGame;
  FeedMode _currentFeedMode = FeedMode.myFeed;
  bool _isDropdownOpen = false;
  Map<int, Team> _teamsMap = {};
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
    });
    _refreshData();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      final allGames = _db.getGames();
      _games = allGames;
      _heroGame = allGames.isNotEmpty ? allGames.first : null;
      _news = _db.getNews();
      final allTeams = _db.getTeams();
      _teamsMap = {for (var t in allTeams) if (t.id != null) t.id!: t};
    });
  }

  Future<void> _exportBackup() async {
    try {
      final jsonStr = _db.exportBackup();
      await Share.share(jsonStr, subject: 'backup_notiball.json');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar backup: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        await _db.importBackup(jsonStr);
        _refreshData();
        Navigator.pop(context); // Close drawer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup importado com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar backup: $e')),
      );
    }
  }

  String get _currentFeedTitle {
    switch (_currentFeedMode) {
      case FeedMode.myFeed:
        return 'myFeed';
      case FeedMode.jogos:
        return 'JOGOS';
      case FeedMode.news:
        return 'NEWS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                _refreshData();
              },
              color: Colors.white,
              backgroundColor: Colors.grey[900],
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _isLoading
                    ? (_currentFeedMode == FeedMode.myFeed
                        ? [
                            SliverToBoxAdapter(child: _buildHeroSkeleton()),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  'Mais Jogos',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildGameListItemSkeleton(),
                                  childCount: 2,
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  'Últimas Notícias',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Container(
                                height: 220,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  itemCount: 3,
                                  itemBuilder: (context, index) => _buildNewsCardSkeleton(),
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ]
                        : _currentFeedMode == FeedMode.jogos
                            ? [
                                SliverToBoxAdapter(
                                  child: SizedBox(height: MediaQuery.of(context).padding.top + 76),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.all(16.0),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildGameListItemSkeleton(),
                                      childCount: 5,
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                              ]
                            : [
                                SliverToBoxAdapter(
                                  child: SizedBox(height: MediaQuery.of(context).padding.top + 76),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.82,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildNewsGridItemSkeleton(),
                                      childCount: 6,
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                              ])
                    : _currentFeedMode == FeedMode.myFeed
                        ? [
                        // Hero Match Section
                        SliverToBoxAdapter(
                          child: _buildHeroSection(),
                        ),

                        // "Mais Jogos" List Section
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mais Jogos',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        _games.length <= 1
                            ? const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'Nenhum outro jogo agendado.',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      // Exclude the hero game from this list
                                      final game = _games[index + 1];
                                      return _buildGameListItem(game);
                                    },
                                    childCount: (_games.length - 1) > 2 ? 2 : (_games.length - 1),
                                  ),
                                ),
                              ),

                        // "Ver Mais Jogos" Button
                        if (_games.length > 3)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextButton(
                                onPressed: () => setState(() => _currentFeedMode = FeedMode.jogos),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('VER MAIS JOGOS', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // "Últimas Notícias" Section
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Últimas Notícias',
                              style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: _news.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'Nenhuma notícia cadastrada.',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 220,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: _news.length > 3 ? 3 : _news.length,
                                    itemBuilder: (context, index) {
                                      final item = _news[index];
                                      return _buildNewsCard(item);
                                    },
                                  ),
                                ),
                        ),

                        // "Ver Mais Notícias" Button
                        if (_news.length > 3)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextButton(
                                onPressed: () => setState(() => _currentFeedMode = FeedMode.news),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('VER MAIS NOTÍCIAS', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ]
                    : _currentFeedMode == FeedMode.jogos
                        ? [
                            // Spacing
                            SliverToBoxAdapter(
                              child: SizedBox(height: MediaQuery.of(context).padding.top + 76),
                            ),

                            // Full list of games
                            _games.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Center(child: Text('Nenhum jogo cadastrado.', style: TextStyle(color: Colors.grey))),
                                    ),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.all(16.0),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final game = _games[index];
                                          return _buildGameListItem(game);
                                        },
                                        childCount: _games.length,
                                      ),
                                    ),
                                  ),

                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ]
                        : [
                            // Spacing
                            SliverToBoxAdapter(
                              child: SizedBox(height: MediaQuery.of(context).padding.top + 76),
                            ),

                            // Full grid of news
                            _news.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Center(child: Text('Nenhuma notícia cadastrada.', style: TextStyle(color: Colors.grey))),
                                    ),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    sliver: SliverGrid(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.82,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final item = _news[index];
                                          return _buildNewsGridItem(item);
                                        },
                                        childCount: _news.length,
                                      ),
                                    ),
                                  ),

                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ],
              ),
            ),

            // Invisible Modal Barrier to close dropdown on tap outside
            if (_isDropdownOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDropdownOpen = false;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
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

            // Top Header: Settings Gear (Left), Plus Add Button (Right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Settings Gear
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
                          icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                          onPressed: () => _showSettingsBottomSheet(context),
                        ),
                      ),
                    ),
                  ),

                  // Right: Plus Add button
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
                          icon: const Icon(Icons.add, color: Colors.white, size: 26),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreatorScreen()),
                            );
                            _refreshData();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Animated Dropdown Menu Card (Center, aligned with top row but expands downwards)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 70, // Positioned between left Gear (16+48) and right Plus (16+48)
              right: 70,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isDropdownOpen ? 140 : 48,
                  decoration: BoxDecoration(
                    color: (_isDropdownOpen || _isScrolled) ? Colors.black.withOpacity(0.55) : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: (_isDropdownOpen || _isScrolled) ? Colors.white12 : Colors.transparent,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // BackdropFilter for glassmorphic blur when open or scrolled
                      if (_isDropdownOpen || _isScrolled)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(color: Colors.transparent),
                          ),
                        ),

                      // Animated title shifting alignment and font size
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: _isDropdownOpen ? Alignment.topLeft : Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _isDropdownOpen ? 20.0 : 0.0,
                            top: _isDropdownOpen ? 14.0 : 0.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentFeedTitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: _isDropdownOpen ? 28 : 22,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter Pills (Jogos / Noticias)
                      Positioned(
                        bottom: 16,
                        left: 14,
                        right: 14,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isDropdownOpen ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: !_isDropdownOpen,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _buildPillButtons(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Configurações',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(color: Color(0xFF1C1C1E), height: 1),
              ListTile(
                leading: const Icon(Icons.shield, color: Colors.white),
                title: Text(
                  'Gerenciar Times',
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageScreen(initialIndex: 0)),
                  );
                  _refreshData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.white),
                title: Text(
                  'Gerenciar Competições',
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageScreen(initialIndex: 1)),
                  );
                  _refreshData();
                },
              ),
              const Divider(color: Color(0xFF1C1C1E)),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.grey),
                title: const Text('Exportar Backup (JSON)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _exportBackup();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.grey),
                title: const Text('Importar Backup (JSON)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                onTap: () {
                  _importBackup();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    if (_heroGame == null) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          color: Colors.grey[950],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Sem Jogos Cadastrados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Toque no "+" no topo para cadastrar uma partida.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    final game = _heroGame!;
    final teamM = _teamsMap[game.teamMandanteId];
    final teamV = _teamsMap[game.teamVisitanteId];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameDetailScreen(game: game)),
        );
        _refreshData();
      },
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Poster Image
            AppImage(
              src: game.photos.isNotEmpty ? game.photos.first : '',
              fit: BoxFit.cover,
            ),

            // Black Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.black54,
                    Colors.black,
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Match details at bottom
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scores and Crests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (teamM != null)
                        AppImage(src: teamM.logo, width: 44, height: 44, fit: BoxFit.contain),
                      const SizedBox(width: 16),
                      Text(
                        '${game.placarM}  x  ${game.placarV}',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (teamV != null)
                        AppImage(src: teamV.logo, width: 44, height: 44, fit: BoxFit.contain),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    game.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    game.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameListItem(Game game) {
    final tm = _teamsMap[game.teamMandanteId];
    final tv = _teamsMap[game.teamVisitanteId];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF1C1C1E)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameDetailScreen(game: game)),
          );
          _refreshData();
        },
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (tm != null)
                  AppImage(src: tm.logo, width: 22, height: 22, fit: BoxFit.contain),
                const SizedBox(width: 8),
                Text(
                  '${game.placarM} x ${game.placarV}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (tv != null)
                  AppImage(src: tv.logo, width: 22, height: 22, fit: BoxFit.contain),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              game.title.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              game.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: AppImage(
            src: game.photos.isNotEmpty ? game.photos.first : '',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(News item) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailScreen(news: item)),
        );
        _refreshData();
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E)),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: AppImage(src: item.photo),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsGridItem(News item) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailScreen(news: item)),
        );
        _refreshData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E)),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: AppImage(src: item.photo, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPillButtons() {
    final List<Map<String, dynamic>> options = [];
    if (_currentFeedMode != FeedMode.myFeed) {
      options.add({'label': 'myFeed', 'mode': FeedMode.myFeed});
    }
    if (_currentFeedMode != FeedMode.jogos) {
      options.add({'label': 'Jogos', 'mode': FeedMode.jogos});
    }
    if (_currentFeedMode != FeedMode.news) {
      options.add({'label': 'Notícias', 'mode': FeedMode.news});
    }

    return options.map((opt) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentFeedMode = opt['mode'];
                _isDropdownOpen = false;
              });
            },
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(
                  opt['label'],
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildHeroSkeleton() {
    return SkeletonPulse(
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Center(
            child: Icon(Icons.sports_soccer, size: 80, color: Colors.white.withOpacity(0.15)),
          ),
        ),
      ),
    );
  }

  Widget _buildGameListItemSkeleton() {
    return SkeletonPulse(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 104,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 80, height: 16, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Container(width: 140, height: 20, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 180, height: 12, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCardSkeleton() {
    return SkeletonPulse(
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(color: Colors.white12),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 16, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 200, height: 12, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 4),
                    Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsGridItemSkeleton() {
    return SkeletonPulse(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border.all(color: const Color(0xFF1C1C1E)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Container(color: Colors.white12),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 10, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({Key? key, required this.child}) : super(key: key);

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
