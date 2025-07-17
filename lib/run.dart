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

  final ipv4Address = await _lookupAddress(discovered.address);
  if (ipv4Address == null) return;

  await _runAdbPair(
    address: ipv4Address,
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

Future<String?> _lookupAddress(String address) async {
  // IPv4 address doesn't need to be resolved
  final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
  if (ipRegex.hasMatch(address)) return address;

  // IPv6 address doesn't need to be resolved
  final ipv6Regex = RegExp(
    r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$',
  );
  if (ipv6Regex.hasMatch(address)) return address;

  final lookup = await InternetAddress.lookup(address);
  final ipv4 = lookup.where(
    (address) => address.type == InternetAddressType.IPv4,
  );

  if (ipv4.isEmpty) {
    print('Error: Could not resolve address $address');
    return null;
  }

  final ipv4Address = ipv4.first.address;
  return ipv4Address;
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
