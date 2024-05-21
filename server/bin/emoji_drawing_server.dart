import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:image/image.dart';

class Database {
  final SqliteDatabase database;
  final migrations = SqliteMigrations()
    ..add(SqliteMigration(7, (tx) async {
      await tx.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            hide INTEGER DEFAULT 0,
            admin INTEGER DEFAULT 0,
            emoji_counter INTEGER DEFAULT 0
        );
        """);

//       await tx.execute('''
// PRAGMA foreign_keys=off;
// ''');
      try {
        await tx.execute('''
          ALTER TABLE users ADD COLUMN username TEXT;
        ''');
      } catch (e) {}

      try {
        await tx.execute('''
          ALTER TABLE users ADD COLUMN password TEXT;
        ''');
      } catch (e) {}

      try {
        await tx.execute('''
          ALTER TABLE users ADD COLUMN hide INTEGER DEFAULT 0;
        ''');
      } catch (e) {}

      try {
        await tx.execute('''
          ALTER TABLE users ADD COLUMN admin INTEGER DEFAULT 0;
        ''');
      } catch (e) {}

      try {
        await tx.execute('''
          ALTER TABLE users ADD COLUMN emoji_counter INTEGER DEFAULT 0;
        ''');
      } catch (e) {}

//       await tx.execute('''
// PRAGMA foreign_keys=on;
// ''');
    }));

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
        SELECT username, emoji_counter, hide, RANK() OVER (ORDER BY emoji_counter DESC) AS emoji_rank
        FROM users
        WHERE hide = 0
        ORDER BY emoji_counter DESC
        LIMIT 5;
      ''',
    );

    final topPlayers = res.map((row) => LeaderboardUser.fromJson(row)).toList();

    if (topPlayers.every((user) => user.username != username)) {
      final userRes = await database.execute(
        '''
          SELECT username, emoji_counter, hide, emoji_rank
          FROM (
              SELECT username, emoji_counter, hide, RANK() OVER (ORDER BY emoji_counter DESC) AS emoji_rank
              FROM users
          ) AS ranked_users
          WHERE username = (?) AND hide = 0;
        ''',
        [
          username,
        ],
      );
      if (userRes.isNotEmpty) {
        topPlayers.add(LeaderboardUser.fromJson(userRes.first));
      }
    }

    return topPlayers;
  }

  Future<void> hideUser(String username, [bool hide = true]) async {
    await database.execute(
      '''
        UPDATE users
        SET hide = (?)
        WHERE username = (?);
      ''',
      [
        hide ? 1 : 0,
        username,
      ],
    );
  }

  Future<bool> isUserHidden(String username) async {
    final result = await database.execute(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE username = (?)
      AND hide = 1;
    ''',
      [
        username,
      ],
    );
    return result.first['count'] > 0;
  }

  Future<void> changeUsername(String username, String newUsername) async {
    await database.execute(
      '''
        UPDATE users
        SET username = (?)
        WHERE username = (?);
      ''',
      [
        newUsername,
        username,
      ],
    );
  }

  Future<bool> checkIfUserIsAdmin(String username) async {
    final result = await database.execute(
      '''
      SELECT COUNT(*) AS count
      FROM users
      WHERE username = (?)
      AND admin = 1;
    ''',
      [
        username,
      ],
    );
    return result.first['count'] > 0;
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
  parser.addFlag('filter-images', defaultsTo: false);
  parser.addFlag('filter-images-dry', defaultsTo: false);

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

  if (results['filter-images']) {
    final images = imagesDir.listSync();
    for (final imageFileEntity in images) {
      final imageFile = File(imageFileEntity.path);
      final imageName = imageFile.path.split('/').last;
      final username = imageName.split('-').first;
      final emojiId = int.parse(imageName.split('-')[1]);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(imageName.split('-')[2].split('.').first));

      if (await database.isUserHidden(username)) {
        print('Deleting $imageName');
        if (!results['filter-images-dry']) {
          imageFile.deleteSync();
        }
        continue;
      }

      final imageBytes = imageFile.readAsBytesSync();
      final image = decodeImage(imageBytes);
      if (image == null) {
        print('Deleting $imageName');
        if (!results['filter-images-dry']) {
          imageFile.deleteSync();
        }
        continue;
      }
      int transparentPixels = 0;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (pixel.a < 10) {
            transparentPixels++;
          }
        }
      }
      if (transparentPixels / (image.width * image.height) > 0.99) {
        print('Deleting $imageName');
        if (!results['filter-images-dry']) {
          imageFile.deleteSync();
        }
        continue;
      }
    }
    exit(0);
  }

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

  app.post('/api/predictEmoji', (Request request) async {
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
    // Custom emoji prediction server.
    final res = await http.post(Uri.parse("http://localhost:3001/upload"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "emojiBase64": json['emojiBase64'],
          "modelType": json['modelType'],
        }));

    return Response(res.statusCode, body: res.body);
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

  app.post('/api/changeUsername', (Request request) async {
    final (
      username,
      authRes
    ) = await authorize(request);
    if (authRes != null) return authRes;
    if (!(await database.checkIfUserIsAdmin(username))) {
      return Response.forbidden('You are not an admin');
    }

    final body = await request.readAsString();
    final json = jsonDecode(body);

    await database.changeUsername(json['username'] as String, json['newUsername'] as String);

    return Response.ok(null);
  });

  app.post('/api/hide', (Request request) async {
    final (
      username,
      authRes
    ) = await authorize(request);
    if (authRes != null) return authRes;
    if (!(await database.checkIfUserIsAdmin(username))) {
      return Response.forbidden('You are not an admin');
    }

    final body = await request.readAsString();
    final json = jsonDecode(body);

    await database.hideUser(json['username'] as String);

    return Response.ok(null);
  });

  app.post('/api/unhide', (Request request) async {
    final (
      username,
      authRes
    ) = await authorize(request);
    if (authRes != null) return authRes;
    if (!(await database.checkIfUserIsAdmin(username))) {
      return Response.forbidden('You are not an admin');
    }

    final body = await request.readAsString();
    final json = jsonDecode(body);

    await database.hideUser(json['username'] as String, false);

    return Response.ok(null);
  });

  app.post('/api/login', (Request request) async {
    final body = await request.readAsString();
    final json = jsonDecode(body);
    final username = json['username'] as String?;
    final password = json['password'] as String?;

    if ((username ?? "").length < 3 || (password ?? "").length < 3) {
      return Response.forbidden('Bad username or password');
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username!)) {
      return Response.forbidden('Only alphanumeric characters allowed');
    }

    if (!(await database.checkIfUserExists(username, password!))) {
      if (await database.checkIfUserExists(username)) {
        return Response.forbidden('User already exists');
      }

      // return Response.forbidden("User doesn't exists");
      await database.createUser(username, password);
    }

    return Response.ok(base64Encode(utf8.encode('$username:$password')), headers: {
      'Set-Cookie': 'auth=${base64Encode(utf8.encode('$username:$password'))}; Path=/; HttpOnly; SameSite=Strict'
    });
  });

  app.post('/api/logout', (Request request) async {
    return Response.ok(null, headers: {
      'Set-Cookie': 'auth=; Path=/; HttpOnly; SameSite=Strict'
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
