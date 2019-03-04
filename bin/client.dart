import 'package:http/http.dart' as http;

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
    for (int i = 0; i < 10; ++i) {
      futures.add(get('http://localhost:1234').then((res) {
        print(res);
      }));
    }
    await Future.wait(futures);
  }
}
