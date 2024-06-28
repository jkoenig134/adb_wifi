import 'package:qr/qr.dart';

/// Generates a QR code from the given [input] string.
String generateQrCode(String input, {int typeNumber = 5}) {
  final qrcode = QrCode.fromData(
    data: input,
    errorCorrectLevel: QrErrorCorrectLevel.H,
  );

  final qri = QrImage(qrcode);
  final moduleCount = qrcode.moduleCount;

  // var output = '';
  const whiteAll = '\u{2588}';
  const whiteBlack = '\u{2580}';
  const blackWhite = '\u{2584}';
  const blackAll = ' ';

  final oddRow = moduleCount.isOdd;

  final borderTop =
      Iterable<int>.generate(moduleCount + 2).map((e) => blackWhite).join();
  final borderBottom =
      Iterable<int>.generate(moduleCount + 2).map((e) => whiteBlack).join();

  final output = StringBuffer('$borderTop\n');

  for (var row = 0; row < moduleCount; row += 2) {
    output.write(whiteAll);

    for (var col = 0; col < moduleCount; col++) {
      if (!qri.isDark(row, col) &&
          (_checkRow(oddRow, moduleCount, row) || !qri.isDark(row + 1, col))) {
        output.write(whiteAll);
      } else if (!qri.isDark(row, col) &&
          (_checkRow(oddRow, moduleCount, row) || qri.isDark(row + 1, col))) {
        output.write(whiteBlack);
      } else if (qri.isDark(row, col) &&
          (_checkRow(oddRow, moduleCount, row) || !qri.isDark(row + 1, col))) {
        output.write(blackWhite);
      } else {
        output.write(blackAll);
      }
    }

    output.write('$whiteAll\n');
  }

  if (!oddRow) output.write(borderBottom);

  return output.toString();
}

/// Check whether it's possible to check row next to [row] based on [oddRow]
/// and current [moduleCount]
bool _checkRow(bool oddRow, int moduleCount, int row) {
  return !oddRow || (row + 1) >= moduleCount;
}
