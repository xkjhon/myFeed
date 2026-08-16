class Team {
  final int? id;
  final String name;
  final String logo; // base64, file path, or URL
  final String color; // Hex string, e.g. "#123456"
  final String country;

  Team({
    this.id,
    required this.name,
    required this.logo,
    required this.color,
    required this.country,
  });

  factory Team.fromMap(Map<dynamic, dynamic> map, int id) {
    return Team(
      id: id,
      name: map['name'] ?? '',
      logo: map['logo'] ?? map['escudo'] ?? '', // Handle old schema 'escudo'
      color: map['color'] ?? map['cor'] ?? '#1e3a8a',
      country: map['country'] ?? map['pais'] ?? 'Brasil',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logo': logo,
      'color': color,
      'country': country,
    };
  }
}

class Competition {
  final int? id;
  final String name;
  final String logo;

  Competition({
    this.id,
    required this.name,
    required this.logo,
  });

  factory Competition.fromMap(Map<dynamic, dynamic> map, int id) {
    return Competition(
      id: id,
      name: map['name'] ?? map['nome'] ?? '',
      logo: map['logo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logo': logo,
    };
  }
}

class MatchEvent {
  final String playerName;
  final String minute;
  final String type; // Gol, Vermelho, Amarelo
  final String side; // mandante, visitante

  MatchEvent({
    required this.playerName,
    required this.minute,
    required this.type,
    required this.side,
  });

  factory MatchEvent.fromMap(Map<dynamic, dynamic> map) {
    return MatchEvent(
      playerName: map['playerName'] ?? map['jogador'] ?? '',
      minute: map['minute'] ?? map['minuto'] ?? '',
      type: map['type'] ?? map['tipo'] ?? 'Gol',
      side: map['side'] ?? map['lado'] ?? 'mandante',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'minute': minute,
      'type': type,
      'side': side,
    };
  }
}

class Game {
  final int? id;
  final String title;
  final String text;
  final List<String> photos;
  final int teamMandanteId;
  final String placarM;
  final int teamVisitanteId;
  final String placarV;
  final String mvpName;
  final String mvpFoto;
  final String mvpJust;
  final String estadio;
  final String competicao;
  final String fase;
  final String juiz;
  final String transmissao;
  final List<MatchEvent> eventos;
  final DateTime data;

  Game({
    this.id,
    required this.title,
    required this.text,
    required this.photos,
    required this.teamMandanteId,
    required this.placarM,
    required this.teamVisitanteId,
    required this.placarV,
    required this.mvpName,
    required this.mvpFoto,
    required this.mvpJust,
    required this.estadio,
    required this.competicao,
    required this.fase,
    required this.juiz,
    required this.transmissao,
    required this.eventos,
    required this.data,
  });

  factory Game.fromMap(Map<dynamic, dynamic> map, int id) {
    var rawPhotos = map['photos'] ?? map['fotos'] ?? [];
    List<String> photosList = (rawPhotos as List).map((e) => e.toString()).toList();

    var rawEvents = map['eventos'] ?? map['events'] ?? [];
    List<MatchEvent> eventsList = (rawEvents as List).map((e) => MatchEvent.fromMap(e)).toList();

    DateTime parsedDate;
    if (map['data'] != null) {
      if (map['data'] is DateTime) {
        parsedDate = map['data'];
      } else {
        parsedDate = DateTime.tryParse(map['data'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return Game(
      id: id,
      title: map['title'] ?? map['titulo'] ?? '',
      text: map['text'] ?? map['texto'] ?? '',
      photos: photosList,
      teamMandanteId: int.tryParse(map['timeMandanteId'].toString()) ?? 0,
      placarM: map['placarM'].toString(),
      teamVisitanteId: int.tryParse(map['timeVisitanteId'].toString()) ?? 0,
      placarV: map['placarV'].toString(),
      mvpName: map['mvpName'] ?? map['mvpNome'] ?? '',
      mvpFoto: map['mvpFoto'] ?? '',
      mvpJust: map['mvpJust'] ?? '',
      estadio: map['estadio'] ?? '',
      competicao: map['competicao'] ?? '',
      fase: map['fase'] ?? '',
      juiz: map['juiz'] ?? '',
      transmissao: map['transmissao'] ?? '',
      eventos: eventsList,
      data: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'text': text,
      'photos': photos,
      'timeMandanteId': teamMandanteId,
      'placarM': placarM,
      'timeVisitanteId': teamVisitanteId,
      'placarV': placarV,
      'mvpName': mvpName,
      'mvpFoto': mvpFoto,
      'mvpJust': mvpJust,
      'estadio': estadio,
      'competicao': competicao,
      'fase': fase,
      'juiz': juiz,
      'transmissao': transmissao,
      'eventos': eventos.map((e) => e.toMap()).toList(),
      'data': data.toIso8601String(),
    };
  }
}

class News {
  final int? id;
  final String title;
  final String summary;
  final String body;
  final String photo;
  final int timeRelacionadoId;
  final DateTime data;

  News({
    this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.photo,
    required this.timeRelacionadoId,
    required this.data,
  });

  factory News.fromMap(Map<dynamic, dynamic> map, int id) {
    DateTime parsedDate;
    if (map['data'] != null) {
      if (map['data'] is DateTime) {
        parsedDate = map['data'];
      } else {
        parsedDate = DateTime.tryParse(map['data'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return News(
      id: id,
      title: map['title'] ?? map['titulo'] ?? '',
      summary: map['summary'] ?? map['resumo'] ?? '',
      body: map['body'] ?? map['corpo'] ?? '',
      photo: map['photo'] ?? map['foto'] ?? '',
      timeRelacionadoId: int.tryParse(map['timeRelacionadoId'].toString()) ?? 0,
      data: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'body': body,
      'photo': photo,
      'timeRelacionadoId': timeRelacionadoId,
      'data': data.toIso8601String(),
    };
  }
}
