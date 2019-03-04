import 'dart:async';
import 'dart:io';
import 'dart:isolate';

enum WorkerDeath {
  deathByMurder,
  deathBySuicide,
}

final int workerDeathId = 0;
final WorkerDeath deathStyle = WorkerDeath.deathByMurder;

void main() async {
  print('main starting');
  for (int i = 0; i < 4; ++i) {
    final w = Worker(i);
    w.start();
  }
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
      print('Worker $workerid exited, restarting...');
      onExit.close();
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
    if (deathStyle ==WorkerDeath.deathByMurder && workerid == workerDeathId) {
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
    final reply = 'Hello from worker: $workerid';
    print('Worker._main starting with workerid=$workerid');
    final server = await HttpServer.bind('0.0.0.0', 1234, shared: true);
    server.listen((HttpRequest request) {
      print('${request.method} ${request.uri} ${request.connectionInfo.remoteAddress.host} -> $reply');
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.write(reply);
      response.close();
    }, onError: (err, stack) {
      print('onError: workerid=$workerid: $err');
      print('    stack=$stack');
    }, onDone: () {
      print('onDone: workerid=$workerid'); 
    });
    if (deathStyle == WorkerDeath.deathBySuicide && workerid == workerDeathId) {
      Future.delayed(Duration(seconds: 10), () {
        print('Killing worker: $workerid');
        throw 'SUICIDE';
      });
    }
  }
}
