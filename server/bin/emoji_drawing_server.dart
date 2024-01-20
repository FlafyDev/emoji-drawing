import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite_async/sqlite_async.dart';

class Database {
  final SqliteDatabase database;
  final migrations = SqliteMigrations()
    ..add(SqliteMigration(
        1,
        (tx) async => await tx.execute(
              '''
                CREATE TABLE users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT,
                    password TEXT,
                    emoji_counter INTEGER DEFAULT 0
                );
              ''',
            )));

  Database(this.database) {
    migrations.migrate(database);
  }

  Future<bool> checkIfUserExists(String username, [String? password]) async {
    final result = await database.execute(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE username = (?)
      AND (password = (?) OR (?) IS NULL);
    ''',
      [
        username,
        password,
        password
      ],
    );
    return result.first['count'] > 0;
  }

  Future<void> createUser(String username, String password) async {
    await database.execute(
      '''
        INSERT INTO users (username, password)
        VALUES (?, ?);
      ''',
      [
        username,
        password,
      ],
    );
  }

  Future<List<LeaderboardUser>> getTopPlayers(String username) async {
    final res = await database.execute(
      '''
        SELECT username, emoji_counter, RANK() OVER (ORDER BY emoji_counter DESC) AS emoji_rank
        FROM users
        ORDER BY emoji_counter DESC
        LIMIT 3;
      ''',
    );

    final topPlayers = res.map((row) => LeaderboardUser.fromJson(row)).toList();

    if (topPlayers.every((user) => user.username != username)) {
      final userRes = await database.execute(
        '''
          SELECT username, emoji_counter
          FROM users
          WHERE username = (?);
        ''',
        [
          username,
        ],
      );
      topPlayers.add(LeaderboardUser.fromJson(userRes.first));
    }

    return topPlayers;
  }

  Future<void> storeEmoji(String username, String emojiBase64, int emojiId, Directory imageDir) async {
    database.execute(
      '''
        UPDATE users
        SET emoji_counter = emoji_counter + 1
        WHERE username = (?);
      ''',
      [
        username,
      ],
    );
    final imageFile = File('${imageDir.path}/$username-$emojiId-${DateTime.now().millisecondsSinceEpoch}.png');
    imageFile.writeAsBytesSync(base64Decode(emojiBase64));
  }
}

void main(List<String> args) async {
  final app = Router();

  // Parse command line arguments
  final parser = ArgParser();
  parser.addOption('port', abbr: 'p', defaultsTo: '8080');
  parser.addOption('host', abbr: 'H', defaultsTo: 'localhost');
  parser.addOption('data-dir', abbr: 'D', mandatory: true);

  final results = parser.parse(args);
  final port = int.parse(results['port']);
  final host = results['host'];
  final dataDir = Directory(results['data-dir']);
  final imagesDir = Directory('${dataDir.path}/images');

  if (dataDir.existsSync() == false) {
    dataDir.createSync(recursive: true);
  }
  if (imagesDir.existsSync() == false) {
    imagesDir.createSync(recursive: true);
  }

  final database = Database(SqliteDatabase(path: '${dataDir.path}/database.db'));

  Future<
      (
        String,
        Response?
      )> authorize(Request request) async {
    try {
      final authCookie = request.headers['cookie']?.split(';').firstWhere((element) => element.trim().startsWith('auth=')).trim().substring(5);
      final authSplit = utf8.decode(base64Decode(authCookie!)).split(':');
      final username = authSplit[0];
      final password = authSplit[1];
      if (!(await database.checkIfUserExists(username, password))) {
        return (
          "",
          Response.forbidden('Invalid username or password')
        );
      }
      return (
        username,
        null
      );
    } catch (e) {
      return (
        "",
        Response.internalServerError()
      );
    }
  }

  app.post('/api/isLogged', (Request request) async {
    final (
      username,
      authRes
    ) = await authorize(request);
    if (authRes != null) return authRes;

    return Response.ok(username);
  });

  app.post('/api/send', (Request request) async {
    final (
      username,
      authRes
    ) = await authorize(request);
    if (authRes != null) return authRes;

    final body = await request.readAsString();
    final json = jsonDecode(body);
    if ((json['emojiBase64'] as String? ?? "").length < 6) {
      return Response.forbidden('Invalid emoji');
    }
    if ((json['emojiId'] as int? ?? -1) < 0) {
      return Response.forbidden('Invalid emoji id');
    }
    database.storeEmoji(username, (json['emojiBase64'] as String).replaceFirst("data:image/png;base64,", ""), json['emojiId'] as int, imagesDir);
    return Response.ok(null);
  });

  app.get('/api/leaderboard', (Request request) async {
    final (
      username,
      authRes
    ) = await authorize(request);
    if (authRes != null) return authRes;

    final topPlayers = await database.getTopPlayers(username);

    return Response.ok(jsonEncode(topPlayers));
  });

  app.post('/api/login', (Request request) async {
    final body = await request.readAsString();
    final json = jsonDecode(body);
    final username = json['username'] as String?;
    final password = json['password'] as String?;

    if ((username ?? "").length < 3 || (password ?? "").length < 3) {
      return Response.forbidden('Bad username or password');
    }

    if (!(await database.checkIfUserExists(username!, password!))) {
      if (await database.checkIfUserExists(username)) {
        return Response.forbidden('User already exists');
      }

      await database.createUser(username, password);
    }

    return Response.ok(base64Encode(utf8.encode('$username:$password')), headers: {
      'Set-Cookie': 'auth=${base64Encode(utf8.encode('$username:$password'))}; Path=/; HttpOnly; SameSite=Strict'
    });
  });

  print('Listening on $host:$port');
  final server = await io.serve(app, host, port);
}

class LeaderboardUser {
  final String username;
  final int rank;
  final int emojiCounter;

  const LeaderboardUser(this.username, this.rank, this.emojiCounter);

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      json['username'] as String,
      json['emoji_rank'] as int,
      json['emoji_counter'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'emoji_rank': rank,
      'emoji_counter': emojiCounter,
    };
  }
}
