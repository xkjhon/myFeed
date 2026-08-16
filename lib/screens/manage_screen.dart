import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/helpers.dart';

class ManageScreen extends StatefulWidget {
  final int initialIndex;
  const ManageScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;
  List<Team> _teams = [];
  List<Competition> _comps = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _refreshLists();
  }

  void _refreshLists() {
    setState(() {
      _teams = _db.getTeams();
      _comps = _db.getCompetitions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- IMAGE PICKER UTILITY ---
  Future<String?> _pickAndConvertImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        // Support SVG/Images as Base64 Data URL to keep compatibility with the web backups
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

  // --- TEAM DIALOG (Create & Edit) ---
  Future<void> _showTeamDialog({Team? team}) async {
    final isEdit = team != null;
    final nameCtrl = TextEditingController(text: team?.name ?? '');
    final urlCtrl = TextEditingController(text: (team?.logo != null && !team!.logo.startsWith('data:')) ? team.logo : '');
    final countryCtrl = TextEditingController(text: team?.country ?? 'Brasil');
    String base64Image = team?.logo.startsWith('data:') == true ? team!.logo : '';
    Color selectedColor = team != null ? HexColor(team.color) : const Color(0xFF1E3A8A);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D0D0D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1C1C1E))),
              title: Text(
                isEdit ? 'Editar Time' : 'Criar Novo Time',
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nome do Time',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C1C1E))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Escudo do Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                final result = await _pickAndConvertImage();
                                if (result != null) {
                                  setDialogState(() {
                                    base64Image = result;
                                    urlCtrl.text = ''; // clear url if uploaded file
                                  });
                                }
                              },
                              child: const Text('Upload Arquivo', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            if (base64Image.isNotEmpty)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else
                              const Text('Nenhum arquivo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Center(child: Text('ou', style: TextStyle(color: Colors.grey))),
                        TextField(
                          controller: urlCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Link da imagem (URL)',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C1C1E))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              setDialogState(() {
                                base64Image = ''; // clear file if url is written
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Theme color picking
                    GestureDetector(
                      onTap: () async {
                        Color? picked = await showDialog<Color>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF0D0D0D),
                            title: const Text('Cor do Clube (Tema)', style: TextStyle(color: Colors.white)),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (c) => Navigator.pop(context, c),
                              ),
                            ),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedColor = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cor do Tema:', style: TextStyle(color: Colors.white)),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: selectedColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: countryCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'País de Origem',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C1C1E))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text;
                    final country = countryCtrl.text;
                    final logo = base64Image.isNotEmpty ? base64Image : urlCtrl.text;
                    final colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';

                    if (name.isEmpty || logo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, preencha o nome e o escudo.')),
                      );
                      return;
                    }

                    final newTeam = Team(
                      name: name,
                      logo: logo,
                      color: colorHex,
                      country: country,
                    );

                    if (isEdit) {
                      await _db.updateTeam(team.id!, newTeam);
                    } else {
                      await _db.addTeam(newTeam);
                    }

                    Navigator.pop(context);
                    _refreshLists();
                  },
                  child: Text(isEdit ? 'Salvar' : 'Adicionar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- COMPETITION DIALOG (Create & Edit) ---
  Future<void> _showCompDialog({Competition? comp}) async {
    final isEdit = comp != null;
    final nameCtrl = TextEditingController(text: comp?.name ?? '');
    final urlCtrl = TextEditingController(text: (comp?.logo != null && !comp!.logo.startsWith('data:')) ? comp.logo : '');
    String base64Image = comp?.logo.startsWith('data:') == true ? comp!.logo : '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D0D0D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1C1C1E))),
              title: Text(
                isEdit ? 'Editar Competição' : 'Criar Competição',
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nome da Competição',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C1C1E))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Logo da Competição', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                final result = await _pickAndConvertImage();
                                if (result != null) {
                                  setDialogState(() {
                                    base64Image = result;
                                    urlCtrl.text = '';
                                  });
                                }
                              },
                              child: const Text('Upload Arquivo', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            if (base64Image.isNotEmpty)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else
                              const Text('Nenhum arquivo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Center(child: Text('ou', style: TextStyle(color: Colors.grey))),
                        TextField(
                          controller: urlCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Link da imagem (URL)',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C1C1E))),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              setDialogState(() {
                                base64Image = '';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text;
                    final logo = base64Image.isNotEmpty ? base64Image : urlCtrl.text;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, preencha o nome.')),
                      );
                      return;
                    }

                    final newComp = Competition(
                      name: name,
                      logo: logo,
                    );

                    if (isEdit) {
                      await _db.updateCompetition(comp.id!, newComp);
                    } else {
                      await _db.addCompetition(newComp);
                    }

                    Navigator.pop(context);
                    _refreshLists();
                  },
                  child: Text(isEdit ? 'Salvar' : 'Adicionar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DELETE CONFIRMATION UTILITY ---
  Future<void> _deleteItem(String type, int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Text('Excluir $type', style: const TextStyle(color: Colors.white)),
        content: Text('Tem certeza que deseja excluir "$name"? Jogos relacionados podem não exibir o logo corretamente.', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (type == 'Time') {
        await _db.deleteTeam(id);
      } else {
        await _db.deleteCompetition(id);
      }
      _refreshLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GERENCIAR',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          tabs: const [
            Tab(text: 'TIMES'),
            Tab(text: 'COMPETIÇÕES'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
        onPressed: () {
          if (_tabController.index == 0) {
            _showTeamDialog();
          } else {
            _showCompDialog();
          }
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Times tab view
          _buildTeamsTab(),

          // Competições tab view
          _buildCompsTab(),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    if (_teams.isEmpty) {
      return const Center(child: Text('Nenhum time cadastrado', style: TextStyle(color: Colors.grey)));
    }

    // Group teams by country
    final Map<String, List<Team>> groupedTeams = {};
    for (var t in _teams) {
      final country = t.country.trim().isEmpty ? 'Outros' : t.country;
      groupedTeams.putIfAbsent(country, () => []).add(t);
    }

    // Sort countries alphabetically
    final sortedCountries = groupedTeams.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedCountries.length,
      itemBuilder: (context, countryIndex) {
        final country = sortedCountries[countryIndex];
        final teamsInCountry = groupedTeams[country]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Section Header
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0),
              child: Text(
                country.toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            // Teams list inside this country
            ...teamsInCountry.map((t) {
              final clubColor = HexColor(t.color);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  border: Border.all(color: const Color(0xFF1C1C1E)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    AppImage(
                      src: t.logo,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: clubColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(t.country, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: () => _showTeamDialog(team: t),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteItem('Time', t.id!, t.name),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCompsTab() {
    if (_comps.isEmpty) {
      return const Center(child: Text('Nenhuma competição cadastrada', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _comps.length,
      itemBuilder: (context, index) {
        final c = _comps[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border.all(color: const Color(0xFF1C1C1E)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              c.logo.isNotEmpty
                  ? AppImage(src: c.logo, width: 44, height: 44, fit: BoxFit.contain)
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Icon(Icons.emoji_events, color: Colors.yellow, size: 20)),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c.name,
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: () => _showCompDialog(comp: c),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteItem('Competição', c.id!, c.name),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
