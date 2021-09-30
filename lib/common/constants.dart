import 'package:flutter/material.dart';

const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60; // seconds of one year

const node_list_protonet = [
  {
    'name': 'Protonet(Testnet)',
    'ss58': 42,
    'endpoint': 'wss://protonet.xxlabs.net',
  }
];
const node_list_xxnetwork = [
  {
    'name': 'xx network(Mainnet)',
    'ss58': 42,
    'endpoint': 'wss://polkadot.api.onfinality.io/public-ws',
  }
];

const home_nav_items = ['staking', 'governance'];

const MaterialColor protonet_black = const MaterialColor(
  0xFF222222,
  const <int, Color>{
    50: const Color(0xFF555555),
    100: const Color(0xFF444444),
    200: const Color(0xFF444444),
    300: const Color(0xFF333333),
    400: const Color(0xFF333333),
    500: const Color(0xFF222222),
    600: const Color(0xFF111111),
    700: const Color(0xFF111111),
    800: const Color(0xFF000000),
    900: const Color(0xFF000000),
  },
);

const String genesis_hash_protonet =
    '0x895af51ef894d3b96df443714028c4f72f86ba929ae9530f689ebe212d87082f';
const String genesis_hash_xxnetwork =
    '0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3';
const String network_name_protonet = 'protonet';
const String network_name_xxnetwork = 'xxnetwork';

