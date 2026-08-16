import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/helpers.dart';

class CreatorScreen extends StatefulWidget {
  final Game? game; // If editing a game
  final News? news; // If editing news

  const CreatorScreen({Key? key, this.game, this.news}) : super(key: key);

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  String _activeTab = 'jogo'; // 'jogo' or 'noticia'

  // --- GENERAL INPUT CONTROLLERS ---
  final _gameTitleCtrl = TextEditingController();
  final _gameTextCtrl = TextEditingController();
  final _gamePlacarMCtrl = TextEditingController();
  final _gamePlacarVCtrl = TextEditingController();
  final _gameMvpNameCtrl = TextEditingController();
  final _gameMvpJustCtrl = TextEditingController();
  final _gameEstadioCtrl = TextEditingController();
  final _gameFaseCtrl = TextEditingController();
  final _gameJuizCtrl = TextEditingController();
  final _gameTransmissaoCtrl = TextEditingController();

  final _newsTitleCtrl = TextEditingController();
  final _newsSummaryCtrl = TextEditingController();
  final _newsBodyCtrl = TextEditingController();

  // --- FORM DATA STATES ---
  List<Team> _teams = [];
  List<Competition> _comps = [];

  int? _selectedTeamMId;
  int? _selectedTeamVId;
  String _selectedCompName = '';
  int? _selectedNewsTeamId;

  List<String> _gamePhotos = [];
  String _gameMvpFoto = '';
  String _newsPhoto = '';

  List<MatchEvent> _eventosTemp = [];

  // --- EVENT INPUT STATE ---
  final _eventPlayerCtrl = TextEditingController();
  final _eventMinuteCtrl = TextEditingController();
  String _eventSide = 'mandante'; // mandante, visitante
  String _eventType = 'Gol'; // Gol, Vermelho, Amarelo

  @override
  void initState() {
    super.initState();
    _isEditing = widget.game != null || widget.news != null;
    if (widget.game != null) {
      _activeTab = 'jogo';
      _loadGameData(widget.game!);
    } else if (widget.news != null) {
      _activeTab = 'noticia';
      _loadNewsData(widget.news!);
    }
    _loadSelectors();
  }

  void _loadSelectors() {
    setState(() {
      _teams = _db.getTeams();
      _comps = _db.getCompetitions();
    });
  }

  void _loadGameData(Game g) {
    _gameTitleCtrl.text = g.title;
    _gameTextCtrl.text = g.text;
    _gamePlacarMCtrl.text = g.placarM;
    _gamePlacarVCtrl.text = g.placarV;
    _gameMvpNameCtrl.text = g.mvpName;
    _gameMvpJustCtrl.text = g.mvpJust;
    _gameEstadioCtrl.text = g.estadio;
    _gameFaseCtrl.text = g.fase;
    _gameJuizCtrl.text = g.juiz;
    _gameTransmissaoCtrl.text = g.transmissao;

    _selectedTeamMId = g.teamMandanteId;
    _selectedTeamVId = g.teamVisitanteId;
    _selectedCompName = g.competicao;

    _gamePhotos = List.from(g.photos);
    _gameMvpFoto = g.mvpFoto;
    _eventosTemp = List.from(g.eventos);
  }

  void _loadNewsData(News n) {
    _newsTitleCtrl.text = n.title;
    _newsSummaryCtrl.text = n.summary;
    _newsBodyCtrl.text = n.body;
    _selectedNewsTeamId = n.timeRelacionadoId;
    _newsPhoto = n.photo;
  }

  // --- FILE PICKER CONVERSION UTILITY ---
  Future<String?> _pickImageAsBase64() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        final extension = file.name.split('.').last.toLowerCase();
        final mimeType = extension == 'svg' ? 'image/svg+xml' : 'image/png';
        return 'data:$mimeType;base64,${base64Encode(bytes)}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
    return null;
  }

  // --- MULTI-IMAGE PICKER FOR MATCH ---
  Future<void> _pickMatchPhotos() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (files.isNotEmpty) {
        List<String> base64s = [];
        for (var file in files.take(6)) {
          final bytes = await file.readAsBytes();
          base64s.add('data:image/png;base64,${base64Encode(bytes)}');
        }
        setState(() {
          _gamePhotos = base64s;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar fotos: $e')),
      );
    }
  }

  // --- ADD NEW TEAM MODAL ---
  Future<void> _createNewTeam() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String base64Logo = '';
    Color selectedColor = const Color(0xFF1E3A8A);

    final addedTeam = await showDialog<Team>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D0D0D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1C1C1E))),
              title: Text('Criar Novo Time', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Nome do Time', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                          onPressed: () async {
                            final res = await _pickImageAsBase64();
                            if (res != null) {
                              setModalState(() {
                                base64Logo = res;
                              });
                            }
                          },
                          child: const Text('Selecionar Escudo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        if (base64Logo.isNotEmpty) const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const Center(child: Text('ou', style: TextStyle(color: Colors.grey))),
                    TextField(
                      controller: urlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'URL da imagem', labelStyle: TextStyle(color: Colors.grey)),
                      onChanged: (v) {
                        if (v.isNotEmpty) setModalState(() => base64Logo = '');
                      },
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        Color? picked = await showDialog<Color>(
                          context: context,
                          builder: (context) {
                            Color tempColor = selectedColor;
                            return AlertDialog(
                              backgroundColor: const Color(0xFF0D0D0D),
                              title: const Text('Cor do Clube', style: TextStyle(color: Colors.white)),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: tempColor,
                                  onColorChanged: (c) => tempColor = c,
                                  colorPickerWidth: 300,
                                  pickerAreaHeightPercent: 0.7,
                                  enableAlpha: false,
                                  displayThumbColor: true,
                                  paletteType: PaletteType.hsvWithHue,
                                  labelTypes: const [],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, tempColor),
                                  child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedColor = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cor do Tema', style: TextStyle(color: Colors.white)),
                            Container(width: 24, height: 24, decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () {
                    final name = nameCtrl.text;
                    final logo = base64Logo.isNotEmpty ? base64Logo : urlCtrl.text;
                    final colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';

                    if (name.isEmpty || logo.isEmpty) return;

                    Navigator.pop(context, Team(name: name, logo: logo, color: colorHex, country: 'Brasil'));
                  },
                  child: const Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (addedTeam != null) {
      final id = await _db.addTeam(addedTeam);
      _loadSelectors();
      setState(() {
        _selectedTeamMId = id;
      });
    }
  }

  // --- SAVE GAME / SAVE NEWS ---
  Future<void> _saveGame() async {
    final title = _gameTitleCtrl.text;
    final text = _gameTextCtrl.text;
    final placarM = _gamePlacarMCtrl.text;
    final placarV = _gamePlacarVCtrl.text;
    final mvpName = _gameMvpNameCtrl.text;
    final mvpJust = _gameMvpJustCtrl.text;
    final estadio = _gameEstadioCtrl.text;
    final competicao = _selectedCompName;
    final fase = _gameFaseCtrl.text;
    final juiz = _gameJuizCtrl.text;
    final transmissao = _gameTransmissaoCtrl.text;

    if (title.isEmpty || text.isEmpty || _selectedTeamMId == null || _selectedTeamVId == null || placarM.isEmpty || placarV.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.')),
      );
      return;
    }

    final newGame = Game(
      title: title,
      text: text,
      photos: _gamePhotos,
      teamMandanteId: _selectedTeamMId!,
      placarM: placarM,
      teamVisitanteId: _selectedTeamVId!,
      placarV: placarV,
      mvpName: mvpName,
      mvpFoto: _gameMvpFoto,
      mvpJust: mvpJust,
      estadio: estadio,
      competicao: competicao,
      fase: fase,
      juiz: juiz,
      transmissao: transmissao,
      eventos: _eventosTemp,
      data: widget.game?.data ?? DateTime.now(),
    );

    if (widget.game != null) {
      await _db.updateGame(widget.game!.id!, newGame);
    } else {
      await _db.addGame(newGame);
    }

    Navigator.pop(context);
  }

  Future<void> _saveNews() async {
    final title = _newsTitleCtrl.text;
    final summary = _newsSummaryCtrl.text;
    final body = _newsBodyCtrl.text;

    if (title.isEmpty || summary.isEmpty || body.isEmpty || _selectedNewsTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.')),
      );
      return;
    }

    final newNews = News(
      title: title,
      summary: summary,
      body: body,
      photo: _newsPhoto.isNotEmpty ? _newsPhoto : 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
      timeRelacionadoId: _selectedNewsTeamId!,
      data: widget.news?.data ?? DateTime.now(),
    );

    if (widget.news != null) {
      await _db.updateNews(widget.news!.id!, newNews);
    } else {
      await _db.addNews(newNews);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Top Spacer for floating header
                SizedBox(height: MediaQuery.of(context).padding.top + 80),

                // Tabs only visible when creating, hidden when editing
                if (!_isEditing) _buildTypeTabs(),

                const SizedBox(height: 20),

                _activeTab == 'jogo' ? _buildGameForm() : _buildNewsForm(),

                // Bottom Spacer to prevent overlap with bottom action bar
                const SizedBox(height: 120),
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

                // Center Title
                Text(
                  _isEditing ? (_activeTab == 'jogo' ? 'EDITAR JOGO' : 'EDITAR NOTÍCIA') : 'CRIAR ENTRADA',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),

                // Balance spacing
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Floating Bottom Save Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                    Colors.black,
                  ],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _activeTab == 'jogo' ? _saveGame : _saveNews,
                child: Text(
                  _activeTab == 'jogo' ? 'SALVAR JOGO' : 'SALVAR NOTÍCIA',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'jogo'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 'jogo' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ADICIONAR JOGO',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: _activeTab == 'jogo' ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 'noticia'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 'noticia' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ADICIONAR NOTÍCIA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: _activeTab == 'noticia' ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GAME FORM WIDGETS ---
  Widget _buildGameForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_gameTitleCtrl, 'Título do Jogo'),
        const SizedBox(height: 16),
        _buildTextField(_gameTextCtrl, 'Texto / Resumo', maxLines: 3),
        const SizedBox(height: 24),

        // Photos selector
        const Text('Imagens Principais (Máx 6)', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: _pickMatchPhotos,
              icon: const Icon(Icons.photo_library),
              label: const Text('Selecionar Fotos', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text('${_gamePhotos.length} fotos selecionadas', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        if (_gamePhotos.isNotEmpty)
          Container(
            height: 90,
            margin: const EdgeInsets.only(top: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gamePhotos.length,
              itemBuilder: (context, idx) {
                final photo = _gamePhotos[idx];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 110,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppImage(src: photo, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _gamePhotos.removeAt(idx);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: GestureDetector(
                        onTap: () async {
                          final cropped = await showDialog<String>(
                            context: context,
                            builder: (context) => CropDialog(base64Image: photo),
                          );
                          if (cropped != null) {
                            setState(() {
                              _gamePhotos[idx] = cropped;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Cortar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 24),

        // Teams & Scores
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTeamDropdown(_selectedTeamMId, 'Time Local', (val) {
                if (val == -1) {
                  _createNewTeam();
                } else {
                  setState(() => _selectedTeamMId = val);
                }
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_gamePlacarMCtrl, 'Placar M', keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTeamDropdown(_selectedTeamVId, 'Time Visitante', (val) {
                if (val == -1) {
                  _createNewTeam();
                } else {
                  setState(() => _selectedTeamVId = val);
                }
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_gamePlacarVCtrl, 'Placar V', keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // MVP Section
        const Text('Jogador Destaque (MVP)', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_gameMvpNameCtrl, 'Nome do Jogador')),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () async {
                final res = await _pickImageAsBase64();
                if (res != null) setState(() => _gameMvpFoto = res);
              },
              child: const Text('Foto (.PNG)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_gameMvpFoto.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppImage(src: _gameMvpFoto, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
                      onPressed: () async {
                        final cropped = await showDialog<String>(
                          context: context,
                          builder: (context) => CropDialog(base64Image: _gameMvpFoto),
                        );
                        if (cropped != null) setState(() => _gameMvpFoto = cropped);
                      },
                      child: const Text('Recortar', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _gameMvpFoto = ''),
                      child: const Text('Remover', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _buildTextField(_gameMvpJustCtrl, 'Justificativa do MVP'),
        const SizedBox(height: 24),

        // Timeline events
        _buildInteractiveTimelineSection(),
        const SizedBox(height: 24),

        // Spec fields
        _buildTextField(_gameEstadioCtrl, 'Estádio'),
        const SizedBox(height: 16),
        _buildCompDropdown(_selectedCompName, 'Competição', (val) {
          setState(() => _selectedCompName = val ?? '');
        }),
        const SizedBox(height: 16),
        _buildTextField(_gameFaseCtrl, 'Fase (ex: Final)'),
        const SizedBox(height: 16),
        _buildTextField(_gameJuizCtrl, 'Árbitro'),
        const SizedBox(height: 16),
        _buildTextField(_gameTransmissaoCtrl, 'Transmissão'),
        const SizedBox(height: 32),

      ],
    );
  }

  // --- NEWS FORM WIDGETS ---
  Widget _buildNewsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_newsTitleCtrl, 'Título da Notícia'),
        const SizedBox(height: 16),
        _buildTextField(_newsSummaryCtrl, 'Resumo Curto (Exibido no feed)'),
        const SizedBox(height: 16),
        _buildTextField(_newsBodyCtrl, 'Corpo Completo da Notícia', maxLines: 6),
        const SizedBox(height: 24),

        // Cover image selector
        const Text('Imagem de Capa', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () async {
                final res = await _pickImageAsBase64();
                if (res != null) setState(() => _newsPhoto = res);
              },
              icon: const Icon(Icons.photo),
              label: const Text('Selecionar Imagem', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_newsPhoto.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AppImage(src: _newsPhoto, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
                      onPressed: () async {
                        final cropped = await showDialog<String>(
                          context: context,
                          builder: (context) => CropDialog(base64Image: _newsPhoto),
                        );
                        if (cropped != null) setState(() => _newsPhoto = cropped);
                      },
                      child: const Text('Recortar', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _newsPhoto = ''),
                      child: const Text('Remover', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        _buildTeamDropdown(_selectedNewsTeamId, 'Time Relacionado', (val) {
          if (val == -1) {
            _createNewTeam();
          } else {
            setState(() => _selectedNewsTeamId = val);
          }
        }),
        const SizedBox(height: 32),

      ],
    );
  }

  // --- UTILS FORM FIELD BUILDERS ---
  Widget _buildTextField(TextEditingController ctrl, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0D0D0D),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1C1C1E)), borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildTeamDropdown(int? selectedId, String label, Function(int?) onChanged) {
    // Sort teams by country, then by name
    final sortedTeams = List<Team>.from(_teams)
      ..sort((a, b) {
        int cmp = a.country.compareTo(b.country);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

    final items = sortedTeams.map((t) {
      return DropdownMenuItem<int>(
        value: t.id,
        child: Text("${t.country.toUpperCase()} | ${t.name}", style: const TextStyle(color: Colors.white, fontSize: 13)),
      );
    }).toList();

    items.add(
      const DropdownMenuItem<int>(
        value: -1,
        child: Text('+ Criar Novo Time...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );

    return DropdownButtonFormField<int>(
      value: selectedId,
      isExpanded: true,
      dropdownColor: const Color(0xFF0D0D0D),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0D0D0D),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1C1C1E)), borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(16)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildCompDropdown(String selectedName, String label, Function(String?) onChanged) {
    final items = _comps.map((c) {
      return DropdownMenuItem<String>(
        value: c.name,
        child: Text(c.name, style: const TextStyle(color: Colors.white)),
      );
    }).toList();

    return DropdownButtonFormField<String>(
      value: selectedName.isEmpty ? null : selectedName,
      isExpanded: true,
      dropdownColor: const Color(0xFF0D0D0D),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0D0D0D),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1C1C1E)), borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(16)),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // --- INTERACTIVE TIMELINE EVENTS SECTION ---
  Widget _buildInteractiveTimelineSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF1C1C1E)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRONOLOGIA DE EVENTOS',
            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          // Inputs for adding a single event
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _eventPlayerCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(labelText: 'Jogador', labelStyle: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _eventMinuteCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(labelText: "Minuto (Ex: 45')", labelStyle: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _eventSide,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0D0D0D),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: Container(height: 1, color: Colors.grey),
                  items: const [
                    DropdownMenuItem(value: 'mandante', child: Text('Time Local')),
                    DropdownMenuItem(value: 'visitante', child: Text('Time Visitante')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _eventSide = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _eventType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0D0D0D),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: Container(height: 1, color: Colors.grey),
                  items: const [
                    DropdownMenuItem(value: 'Gol', child: Text('Gol')),
                    DropdownMenuItem(value: 'Vermelho', child: Text('Cartão Vermelho')),
                    DropdownMenuItem(value: 'Amarelo', child: Text('Cartão Amarelo')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _eventType = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(40, 40)),
                onPressed: () {
                  final player = _eventPlayerCtrl.text;
                  final min = _eventMinuteCtrl.text;
                  if (player.isEmpty || min.isEmpty) return;

                  setState(() {
                    _eventosTemp.add(MatchEvent(
                      playerName: player,
                      minute: min,
                      type: _eventType,
                      side: _eventSide,
                    ));
                    _eventPlayerCtrl.clear();
                    _eventMinuteCtrl.clear();
                  });
                },
                child: const Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable list of temporary events
          if (_eventosTemp.isEmpty)
            const Text('Nenhum evento adicionado (apenas Pontapé Inicial 1\')', style: TextStyle(color: Colors.grey, fontSize: 11))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _eventosTemp.length,
              itemBuilder: (context, idx) {
                final ev = _eventosTemp[idx];
                final sideLabel = ev.side == 'mandante' ? 'Local' : 'Visitante';
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '• ${ev.minute} ${ev.playerName} (${ev.type}) [$sideLabel]',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _eventosTemp.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class CropDialog extends StatefulWidget {
  final String base64Image;

  const CropDialog({Key? key, required this.base64Image}) : super(key: key);

  @override
  State<CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<CropDialog> {
  ui.Image? _image;
  bool _loading = true;

  double _cropLeft = 20.0;
  double _cropTop = 20.0;
  double _cropWidth = 150.0;
  double _cropHeight = 150.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = base64Decode(widget.base64Image.split(',').last);
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      setState(() {
        _image = frameInfo.image;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _doCrop(double containerWidth, double containerHeight) async {
    if (_image == null) return;

    final imgWidth = _image!.width.toDouble();
    final imgHeight = _image!.height.toDouble();

    final double scaleX = imgWidth / containerWidth;
    final double scaleY = imgHeight / containerHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double displayedWidth = imgWidth / scale;
    final double displayedHeight = imgHeight / scale;

    final double offsetX = (containerWidth - displayedWidth) / 2;
    final double offsetY = (containerHeight - displayedHeight) / 2;

    double relativeLeft = _cropLeft - offsetX;
    double relativeTop = _cropTop - offsetY;
    double relativeWidth = _cropWidth;
    double relativeHeight = _cropHeight;

    if (relativeLeft < 0) {
      relativeWidth += relativeLeft;
      relativeLeft = 0;
    }
    if (relativeTop < 0) {
      relativeHeight += relativeTop;
      relativeTop = 0;
    }
    if (relativeLeft + relativeWidth > displayedWidth) {
      relativeWidth = displayedWidth - relativeLeft;
    }
    if (relativeTop + relativeHeight > displayedHeight) {
      relativeHeight = displayedHeight - relativeTop;
    }

    final double cropX = relativeLeft * scale;
    final double cropY = relativeTop * scale;
    final double cropW = relativeWidth * scale;
    final double cropH = relativeHeight * scale;

    if (cropW <= 0 || cropH <= 0) return;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final src = Rect.fromLTWH(cropX, cropY, cropW, cropH);
    final dst = Rect.fromLTWH(0, 0, cropW, cropH);
    canvas.drawImageRect(_image!, src, dst, Paint());

    final croppedImage = await recorder.endRecording().toImage(cropW.toInt(), cropH.toInt());
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    final croppedBytes = byteData!.buffer.asUint8List();

    final extension = widget.base64Image.contains('image/svg') ? 'svg+xml' : 'png';
    final result = 'data:image/$extension;base64,${base64Encode(croppedBytes)}';

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        backgroundColor: Color(0xFF0D0D0D),
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (_image == null) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Erro', style: TextStyle(color: Colors.white)),
        content: const Text('Não foi possível carregar a imagem para recortar.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok')),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF0D0D0D),
      title: Text('Recortar Imagem', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      content: SizedBox(
        width: 300,
        height: 300,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                Positioned.fill(
                  child: RawImage(
                    image: _image,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: _cropLeft,
                  top: _cropTop,
                  width: _cropWidth,
                  height: _cropHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final dx = details.delta.dx;
                      final dy = details.delta.dy;

                      final touchX = details.localPosition.dx;
                      final touchY = details.localPosition.dy;
                      final brCornerX = _cropLeft + _cropWidth;
                      final brCornerY = _cropTop + _cropHeight;

                      if ((touchX - brCornerX).abs() < 30 && (touchY - brCornerY).abs() < 30) {
                        setState(() {
                          _cropWidth = (_cropWidth + dx).clamp(50.0, w - _cropLeft);
                          _cropHeight = (_cropHeight + dy).clamp(50.0, h - _cropTop);
                        });
                      } else {
                        setState(() {
                          _cropLeft = (_cropLeft + dx).clamp(0.0, w - _cropWidth);
                          _cropTop = (_cropTop + dy).clamp(0.0, h - _cropHeight);
                        });
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: _cropLeft + _cropWidth - 10,
                  top: _cropTop + _cropHeight - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_out_map, size: 10, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => _doCrop(300, 300),
          child: const Text('Recortar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
