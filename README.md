
This repo is intended to demonstrate what seems to be an issue with the Dart Server SDK,
(running version 2.2.0), using `HttpServer.bind(..., shared: true)` from separate isolates,
when combined with isolates exiting (i.e., whether from internal error, or due to external
`kill` calls).

`server.dart` works by spawning multiple worker isolates from the root isolate (think `cluster`
from `node.js`). In this example, periodically one isolate is killed, which then triggers the
first issue: killing one isolate causes a _separate_ isolate that is also running an HttpServer
bound with `shared: true` to exit. If asserts are enabled, then this assert is hit in a separate
isolate from the one that has had `kill` called on it (or, if using `WorkerDeath.suicide`, a
separate isolate from the one that throws an exception):
```
'dart:io/runtime/binsocket_patch.dart': Failed assertion: line 906: '<optimized out>': is not true.,
#0      _AssertionError._doThrowNew (dart:core/runtime/liberrors_patch.dart:40:39)
#1      _AssertionError._throwNew (dart:core/runtime/liberrors_patch.dart:36:5)
#2      _NativeSocket.multiplex (dart:io/runtime/binsocket_patch.dart:906:18)
#3      _RawReceivePortImpl._handleMessage (dart:isolate/runtime/libisolate_patch.dart:171:12)
```

Additionally, when running the server with these isolates periodically exiting and respawning,
and while hitting the server with HTTP requests (i.e., by running `client.dart`), it is possible
to trigger a hard crash (see crash dump below). The crash occurs while requests are incoming and
at least one worker is restarting (specifically, the crash comes in between the call to
`Isolate.spawn` and the first line of the isolate's entry point callback):
```
Worker 3 exited, restarting...
GET / 127.0.0.1 -> Hello from worker: 2
onDone: workerid=1
GET / 127.0.0.1 -> Hello from worker: 2
Worker 1 exited, restarting...
GET / 127.0.0.1 -> Hello from worker: 2

===== CRASH =====
version=2.2.0 (Tue Feb 26 15:04:32 2019 +0100) on "macos_x64"
si_signo=Segmentation fault: 11(11), si_code=1, si_addr=0x8
thread=4867, isolate=(null)(0x0)
GET / 127.0.0.1 -> Hello from worker: 2
  [0x000000010c731a81] dart::bin::EventHandlerImplementation::SendData(long, long long, long long)
  [0x000000010c731a81] dart::bin::EventHandlerImplementation::SendData(long, long long, long long)
  [0x000000010c73083d] dart::bin::EventHandlerImplementation::HandleInterruptFd()
  [0x000000010c73124a] dart::bin::EventHandlerImplementation::EventHandlerEntry(unsigned long)
  [0x000000010c75145e] dart::bin::Thread::GetMaxStackSize()
  [0x00007fff65500305] _pthread_body
  [0x00007fff6550326f] _pthread_start
  [0x00007fff654ff415] thread_start
-- End of DumpStackTrace
Abort trap: 6
```

I've tried to keep this repro case as simple as possible, see `options.dart` to play with the settings.
For example, it's pretty easy to show that by getting rid of the HttpServer or by using unique ports
and `shared: false`, both the assert and crash behaviors go away.

Added an issue here: https://github.com/dart-lang/sdk/issues/36106