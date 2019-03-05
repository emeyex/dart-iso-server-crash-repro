import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'options.dart';

void main() async {
  print('main starting');
  final workers = List<Worker>.generate(workerCount, (i) => Worker(i));
  workers.forEach((w) => w.start());
  await Future.delayed(Duration(days: 365));
}

class Worker {
  final int workerid;
  Isolate _isolate;

  Worker(this.workerid);

  Future<void> start() async {
    final onExit = ReceivePort();
    final onError = ReceivePort();
    onExit.listen((_) {
      onExit.close();
      onError.close();
      print('Worker $workerid exited, restarting...');
      start();
    });
    onError.listen((err) {
      print('Worker $workerid threw an error: $err');
    });

    _isolate = await Isolate.spawn(
      _main, 
      workerid,
      errorsAreFatal: true,
      onExit: onExit.sendPort,
      onError: onError.sendPort,
    );

    _queueError();
  }

  void _queueError() {
    if (deathStyle == WorkerDeath.murder && workerid == workerDeathId) {
      Future.delayed(Duration(seconds: 10), () {
        if (_isolate != null) {
          print('Manually killing worker $workerid');
          _isolate.kill();
          _isolate = null;
        }
      });
    }
  }

  static _main(int workerid) async {
    print('Worker._main starting with workerid=$workerid');

    if (deathStyle == WorkerDeath.suicide && workerid == workerDeathId) {
      Future.delayed(Duration(seconds: 10), () {
        print('Killing worker: $workerid');
        throw Exception('SUICIDE');
      });
    }

    if (serverType == ServerType.none) {
      await Future.delayed(Duration(days: 365));
    } else {
      int port = basePort;
      bool shared = true;
      if (serverType == ServerType.unique) {
        port += workerid;
        shared = false;
      }
      final server = await HttpServer.bind('0.0.0.0', port, shared: shared);
      server.listen((HttpRequest request) {
        final reply = 'Hello from worker: $workerid';
        print('${request.method} ${request.uri} ${request.connectionInfo.remoteAddress.host} -> $reply');
        final response = request.response;
        response.statusCode = HttpStatus.ok;
        response.write(reply);
        response.close();
      }, onError: (err, stack) {
        print('HttpServer onError: workerid=$workerid: $err\nstack=$stack');
      }, onDone: () {
        print('HttpServer onDone: workerid=$workerid'); 
      });
    }
  }
}
