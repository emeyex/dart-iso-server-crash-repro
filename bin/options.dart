
enum WorkerDeath {
  murder,
  suicide,
}

final WorkerDeath deathStyle = WorkerDeath.murder;
final int workerDeathId = 0;

enum ServerType {
  none,
  unique,
  shared,
}

final ServerType serverType = ServerType.shared;

final int workerCount = 4;

final int basePort = 1234;
