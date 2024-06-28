# adb_wifi

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

A command-line application for attaching adb over wifi using a qr-code.

## Install

```bash
pub global activate adb_wifi
```

## Usage

```bash
adb_wifi
```

A qr-code is displayed in the terminal. Scan the qr-code with your phone in the adb-wifi options and you are connected to adb over wifi.

## Shoutout

This packages is heavily inspired by the npm cli [adb-wifi](https://www.npmjs.com/package/adb-wifi). The goal is to provide a similar experience for dart and flutter developers without switching ecosystems.
