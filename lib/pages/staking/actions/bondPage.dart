import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/actions/setPayeePage.dart';
import 'package:polkawallet_plugin_xxnetwork/polkawallet_plugin_xxnetwork.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class BondPage extends StatefulWidget {
  BondPage(this.plugin, this.keyring, {this.onNext});
  final PluginXxnetwork plugin;
  final Keyring keyring;
  final Function(TxConfirmParams) onNext;
  @override
  _BondPageState createState() => _BondPageState();
}

class _BondPageState extends State<BondPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = new TextEditingController();

  final _rewardToOptions = ['Staked', 'Stash', 'Controller'];

  KeyPairData _controller;

  int _rewardTo = 0;
  String _rewardAccount;

  Future<void> _changeControllerId(BuildContext context) async {
    final accounts = widget.keyring.keyPairs.toList();
    accounts.addAll(widget.keyring.externals);
    final acc = await Navigator.of(context).pushNamed(
      AccountListPage.route,
      arguments: AccountListPageParams(list: accounts),
    );
    if (acc != null) {
      setState(() {
        _controller = acc;
      });
    }
  }

  void _onPayeeChanged(int to, String address) {
    setState(() {
      _rewardTo = to;
      _rewardAccount = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_protonet, 'common');
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final symbol = widget.plugin.networkState.tokenSymbol[0];
    final decimals = widget.plugin.networkState.tokenDecimals[0];

    double available = 0;
    if (widget.plugin.balances.native != null) {
      available = Fmt.balanceDouble(
          widget.plugin.balances.native.availableBalance.toString(), decimals);
    }

    final rewardToOptions =
        _rewardToOptions.map((i) => dicStaking['reward.$i']).toList();

    List<KeyPairData> accounts;
    if (_rewardTo == 3) {
      accounts = widget.keyring.keyPairs;
      accounts.addAll(widget.keyring.externals);
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextTag(
                        I18n.of(context).getDic(
                            i18n_full_dic_protonet, 'staking')['stake.warn'],
                        color: Colors.deepOrange,
                        fontSize: 12,
                        margin: EdgeInsets.all(0),
                        padding: EdgeInsets.all(8),
                      ))
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: AddressFormItem(
                    widget.keyring.current,
                    label: dicStaking['stash'],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: AddressFormItem(
                    _controller ?? widget.keyring.current,
                    label: dicStaking['controller'],
                    // do not allow change controller here.
                    // onTap: () => _changeControllerId(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: dic['amount'],
                      labelText:
                          '${dic['amount']} (${dicStaking['available']}: ${Fmt.priceFloor(
                        available,
                        lengthMax: 4,
                      )} $symbol)',
                    ),
                    inputFormatters: [UI.decimalInputFormatter(decimals)],
                    controller: _amountCtrl,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v.isEmpty) {
                        return dic['amount.error'];
                      }
                      final amount = double.parse(v.trim());
                      // if (amount >= available) {
                      //   return dic['amount.low'];
                      // }
                      final minBond = Fmt.balanceInt(widget
                          .plugin.store.staking.overview['minNominatorBond']);
                      if (amount < Fmt.bigIntToDouble(minBond, decimals)) {
                        return '${dicStaking['stake.bond.min']} ${Fmt.priceCeilBigInt(minBond, decimals)}';
                      }
                      return null;
                    },
                  ),
                ),
                PayeeSelector(
                  widget.plugin,
                  widget.keyring,
                  initialValue: widget.plugin.store.staking.ownStashInfo,
                  onChange: _onPayeeChanged,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: RoundedButton(
            text: dicStaking['action.bond'],
            onPressed: () {
              if (_formKey.currentState.validate()) {
                final inputAmount = _amountCtrl.text.trim();
                String controllerId = widget.keyring.current.address;
                if (_controller != null) {
                  controllerId = _controller.address;
                }
                widget.onNext(TxConfirmParams(
                  txTitle: dicStaking['action.bond'],
                  module: 'staking',
                  call: 'bond',
                  txDisplay: {
                    "amount": '$inputAmount $symbol',
                    "reward_destination": _rewardTo == 3
                        ? {'Account': _rewardAccount}
                        : rewardToOptions[_rewardTo],
                  },
                  params: [
                    // "controllerId":
                    controllerId,
                    // "amount"
                    Fmt.tokenInt(inputAmount, decimals).toString(),
                    // "to"
                    _rewardTo == 3 ? {'Account': _rewardAccount} : _rewardTo,
                  ],
                ));
              }
            },
          ),
        ),
      ],
    );
  }
}
