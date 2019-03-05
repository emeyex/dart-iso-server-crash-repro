import 'package:http/http.dart' as http;

import 'options.dart';

Future<String> get(String url) async {
  while (true) {
    try {
      final res = await http.get(url);
      return res.body;
    } catch (err) {
      print(err);
    }
  }
}

void main() async {
  while (true) {
    final futures = <Future>[];
    final numAtOnce = 4 * workerCount; // enough to keep the server busy
    for (int i = 0; i < numAtOnce; ++i) {
      int port = basePort;
      if (serverType == ServerType.unique) {
        port += i % workerCount;
      }
      futures.add(get('http://localhost:$port').then((res) {
        print(res);
      }));
    }
    await Future.wait(futures);
  }
}
