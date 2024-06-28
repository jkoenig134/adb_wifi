import 'dart:io';

import 'package:adb_wifi/generate_qr_code.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:nanoid/nanoid.dart';

/// Run the adb wifi pairing process.
Future<void> run() async {
  final name = 'ADB_WIFI_${nanoid()}';
  final password = nanoid();

  _showQrCode(name: name, password: password);

  final discovered = await _discover();

  await _runAdbPair(
    address: discovered.address,
    port: discovered.port,
    password: password,
  );
}

void _showQrCode({required String name, required String password}) {
  final text = 'WIFI:T:ADB;S:$name;P:$password;;';
  final qrCode = generateQrCode(text);
  print(qrCode);
}

Future<({String address, int port})> _discover() async {
  const name = '_adb-tls-pairing._tcp.local';

  final client = MDnsClient();
  await client.start();

  while (true) {
    final ptrs = client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(name),
    );

    await for (final PtrResourceRecord ptr in ptrs) {
      final srvs = client.lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      );

      await for (final SrvResourceRecord srv in srvs) {
        client.stop();

        return (address: srv.target, port: srv.port);
      }
    }
  }
}

Future<void> _runAdbPair({
  required String address,
  required int port,
  required String password,
}) async {
  final process = await Process.start(
    'adb',
    ['pair', '$address:$port', password],
  );

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  await process.exitCode;
}
