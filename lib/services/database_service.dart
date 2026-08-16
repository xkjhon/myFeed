import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Box _timesBox;
  late Box _compsBox;
  late Box _jogosBox;
  late Box _noticiasBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _timesBox = await Hive.openBox('times');
    _compsBox = await Hive.openBox('competicoes');
    _jogosBox = await Hive.openBox('jogos');
    _noticiasBox = await Hive.openBox('noticias');

    await seedDatabase();
  }

  Future<void> seedDatabase() async {
    // Começa completamente vazio sem dados de exemplo
  }

  // --- TEAMS (Times) ---
  List<Team> getTeams() {
    return _timesBox.keys.map((key) {
      final val = _timesBox.get(key) as Map;
      return Team.fromMap(val, key as int);
    }).toList();
  }

  Future<Team?> getTeam(int id) async {
    final val = _timesBox.get(id);
    if (val == null) return null;
    return Team.fromMap(val as Map, id);
  }

  Future<int> addTeam(Team team) async {
    return await _timesBox.add(team.toMap());
  }

  Future<void> updateTeam(int id, Team team) async {
    await _timesBox.put(id, team.toMap());
  }

  Future<void> deleteTeam(int id) async {
    await _timesBox.delete(id);
  }

  // --- COMPETITIONS (Competições) ---
  List<Competition> getCompetitions() {
    return _compsBox.keys.map((key) {
      final val = _compsBox.get(key) as Map;
      return Competition.fromMap(val, key as int);
    }).toList();
  }

  Future<int> addCompetition(Competition comp) async {
    return await _compsBox.add(comp.toMap());
  }

  Future<void> updateCompetition(int id, Competition comp) async {
    await _compsBox.put(id, comp.toMap());
  }

  Future<void> deleteCompetition(int id) async {
    await _compsBox.delete(id);
  }

  // --- GAMES (Jogos) ---
  List<Game> getGames() {
    final games = _jogosBox.keys.map((key) {
      final val = _jogosBox.get(key) as Map;
      return Game.fromMap(val, key as int);
    }).toList();
    // Sort descending by date/id
    games.sort((a, b) => b.data.compareTo(a.data));
    return games;
  }

  Future<Game?> getGame(int id) async {
    final val = _jogosBox.get(id);
    if (val == null) return null;
    return Game.fromMap(val as Map, id);
  }

  Future<int> addGame(Game game) async {
    return await _jogosBox.add(game.toMap());
  }

  Future<void> updateGame(int id, Game game) async {
    await _jogosBox.put(id, game.toMap());
  }

  Future<void> deleteGame(int id) async {
    await _jogosBox.delete(id);
  }

  // --- NEWS (Notícias) ---
  List<News> getNews() {
    final newsList = _noticiasBox.keys.map((key) {
      final val = _noticiasBox.get(key) as Map;
      return News.fromMap(val, key as int);
    }).toList();
    // Sort descending by date
    newsList.sort((a, b) => b.data.compareTo(a.data));
    return newsList;
  }

  Future<News?> getSingleNews(int id) async {
    final val = _noticiasBox.get(id);
    if (val == null) return null;
    return News.fromMap(val as Map, id);
  }

  Future<int> addNews(News news) async {
    return await _noticiasBox.add(news.toMap());
  }

  Future<void> updateNews(int id, News news) async {
    await _noticiasBox.put(id, news.toMap());
  }

  Future<void> deleteNews(int id) async {
    await _noticiasBox.delete(id);
  }

  // --- BACKUP ---
  String exportBackup() {
    final data = {
      'times': _timesBox.keys.map((k) => {'id': k, ...(_timesBox.get(k) as Map)}).toList(),
      'competicoes': _compsBox.keys.map((k) => {'id': k, ...(_compsBox.get(k) as Map)}).toList(),
      'jogos': _jogosBox.keys.map((k) => {'id': k, ...(_jogosBox.get(k) as Map)}).toList(),
      'noticias': _noticiasBox.keys.map((k) => {'id': k, ...(_noticiasBox.get(k) as Map)}).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importBackup(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    await _timesBox.clear();
    await _compsBox.clear();
    await _jogosBox.clear();
    await _noticiasBox.clear();

    if (data['times'] != null) {
      for (var item in data['times']) {
        final Map map = Map.from(item as Map);
        final id = map.remove('id');
        if (id != null) {
          await _timesBox.put(id as int, map);
        } else {
          await _timesBox.add(map);
        }
      }
    }

    if (data['competicoes'] != null || data['competitions'] != null) {
      final list = data['competicoes'] ?? data['competitions'];
      for (var item in list) {
        final Map map = Map.from(item as Map);
        final id = map.remove('id');
        if (id != null) {
          await _compsBox.put(id as int, map);
        } else {
          await _compsBox.add(map);
        }
      }
    }

    if (data['jogos'] != null || data['games'] != null) {
      final list = data['jogos'] ?? data['games'];
      for (var item in list) {
        final Map map = Map.from(item as Map);
        final id = map.remove('id');
        if (id != null) {
          await _jogosBox.put(id as int, map);
        } else {
          await _jogosBox.add(map);
        }
      }
    }

    if (data['noticias'] != null || data['news'] != null) {
      final list = data['noticias'] ?? data['news'];
      for (var item in list) {
        final Map map = Map.from(item as Map);
        final id = map.remove('id');
        if (id != null) {
          await _noticiasBox.put(id as int, map);
        } else {
          await _noticiasBox.add(map);
        }
      }
    }
  }
}
