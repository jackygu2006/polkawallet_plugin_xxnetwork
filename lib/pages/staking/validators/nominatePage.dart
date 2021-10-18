import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/actions/nominateForm.dart';
import 'package:polkawallet_plugin_xxnetwork/polkawallet_plugin_xxnetwork.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';

class NominatePage extends StatefulWidget {
  NominatePage(this.plugin, this.keyring);
  static final String route = '/staking/nominate';
  final PluginXxnetwork plugin;
  final Keyring keyring;
  @override
  _NominatePageState createState() => _NominatePageState();
}

class _NominatePageState extends State<NominatePage> {
  Future<void> _setNominee(TxConfirmParams params) async {
    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    var dicStaking = I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');

    return Scaffold(
      appBar: AppBar(
        title: Text(dicStaking['action.nominate']),
        centerTitle: true,
      ),
      body: Builder(builder: (BuildContext context) {
        return SafeArea(
          child: NominateForm(
            widget.plugin,
            widget.keyring,
            onNext: (TxConfirmParams params) => _setNominee(params),
          ),
        );
      }),
    );
  }
}
