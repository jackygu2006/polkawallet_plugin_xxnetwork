import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/validatorDetailPage.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/validatorListFilter.dart';
import 'package:polkawallet_plugin_xxnetwork/polkawallet_plugin_xxnetwork.dart';
import 'package:polkawallet_plugin_xxnetwork/store/staking/types/validatorData.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/format.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/i18n/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/utils/index.dart';

class NominateForm extends StatefulWidget {
  NominateForm(this.plugin, this.keyring, {this.onNext});
  final PluginXxnetwork plugin;
  final Keyring keyring;
  final Function(TxConfirmParams) onNext;
  @override
  _NominateFormState createState() => _NominateFormState();
}

const MAX_NOMINATION = 16;

class _NominateFormState extends State<NominateForm> {
  final List<ValidatorData> _selected = List<ValidatorData>();
  final List<ValidatorData> _notSelected = List<ValidatorData>();
  Map<String, bool> _selectedMap = Map<String, bool>();

  String _search = '';
  List<bool> _filters = [true, false];

  void _setNominee() {
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final targets = _selected.map((i) => i.accountId).toList();
    widget.onNext(TxConfirmParams(
      txTitle: dicStaking['action.nominate'] + "-1",
      module: 'staking',
      call: 'nominate',
      txDisplay: {'targets': targets.join(', ')},
      params: [targets],
    ));
  }

  Widget _buildListItem(BuildContext context, ValidatorData validator) {
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final Map accInfo =
        widget.plugin.store.accounts.addressIndexMap[validator.accountId];
    final accIcon =
        widget.plugin.store.accounts.addressIconsMap[validator.accountId];
    final bool isWaiting = validator.total == BigInt.zero;
    final nominations = !isWaiting
        ? validator.nominators
        : widget.plugin.store.staking.nominationsMap[validator.accountId] ?? [];

    final textStyle = TextStyle(
      color: Theme.of(context).unselectedWidgetColor,
      fontSize: 12,
    );
    final comm = NumberFormat('0.00%').format(validator.commission / 100);
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        color: Theme.of(context).cardColor,
        child: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 16),
              child: AddressIcon(validator.accountId, svg: accIcon),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UI.accountDisplayName(
                    validator.accountId,
                    accInfo,
                  ),
                  Text(
                    '${dicStaking['commission']}: $comm',
                    style: textStyle,
                  ),
                  Row(
                    children: [
                      Text(
                        '${dicStaking['nominators']}: ${nominations.length}',
                        style: textStyle,
                      ),
                    ],
                  ),
                  Text(
                    isWaiting
                        ? dicStaking['waiting']
                        : '${dicStaking['reward']}: ${validator.stakedReturnCmp.toStringAsFixed(2)}%',
                    style: textStyle,
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _selectedMap[validator.accountId],
              onChanged: (bool value) {
                if (value && _selected.length >= MAX_NOMINATION) {
                  showCupertinoDialog(
                      context: context,
                      builder: (_) {
                        return CupertinoAlertDialog(
                          title: Container(),
                          content: Text(dicStaking['nominate.max']),
                          actions: [
                            CupertinoButton(
                              child: Text(I18n.of(context).getDic(
                                  i18n_full_dic_protonet, 'common')['ok']),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      });
                  return;
                }
                setState(() {
                  _selectedMap[validator.accountId] = value;
                });
                Timer(Duration(milliseconds: 300), () {
                  setState(() {
                    if (value) {
                      _selected.add(validator);
                      _notSelected.removeWhere(
                          (item) => item.accountId == validator.accountId);
                    } else {
                      _selected.removeWhere(
                          (item) => item.accountId == validator.accountId);
                      _notSelected.add(validator);
                    }
                  });
                });
              },
            ),
          ],
        ),
      ),
      onTap: () => Navigator.of(context)
          .pushNamed(ValidatorDetailPage.route, arguments: validator),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        widget.plugin.store.staking.validatorsInfo.forEach((i) {
          _notSelected.add(i);
          _selectedMap[i.accountId] = false;
        });
        widget.plugin.store.staking.nominatingList.forEach((i) {
          _selected.add(i);
          _notSelected.removeWhere((item) => item.accountId == i.accountId);
          _selectedMap[i.accountId] = true;
        });

        // set recommended selected
        final List recommendList = widget.plugin.store.staking
            .recommendedValidators[widget.plugin.basic.name];
        if (recommendList != null && recommendList.length > 0) {
          List<ValidatorData> recommended = _notSelected.toList();
          recommended
              .retainWhere((i) => recommendList.indexOf(i.accountId) > -1);
          recommended.forEach((i) {
            _selected.add(i);
            _notSelected.removeWhere((item) => item.accountId == i.accountId);
            _selectedMap[i.accountId] = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var dicStaking = I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');

    List<ValidatorData> list = [];
    list.addAll(_selected);
    // add recommended
    final List recommendList = widget
        .plugin.store.staking.recommendedValidators[widget.plugin.basic.name];
    if (recommendList != null && recommendList.length > 0) {
      List<ValidatorData> recommended = _notSelected.toList();
      recommended.retainWhere((i) => recommendList.indexOf(i.accountId) > -1);
      list.addAll(recommended);
    }

    // add validators
    // filter the _notSelected list
    List<ValidatorData> retained = List.of(_notSelected);
    // filter the blocking validators
    retained.removeWhere((e) => e.isBlocking);
    retained = PluginFmt.filterValidatorList(retained, _filters, _search,
        widget.plugin.store.accounts.addressIndexMap);
    // and sort it
    retained.sort((a, b) => a.rankReward < b.rankReward ? 1 : -1);
    list.addAll(retained);

    return Column(
      children: <Widget>[
        Container(
          color: Theme.of(context).cardColor,
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: ValidatorListFilter(
            filters: _filters,
            onSearchChange: (v) {
              if (_search != v) {
                setState(() {
                  _search = v;
                });
              }
            },
            onFilterChange: (v) {
              if (_filters != v) {
                setState(() {
                  _filters = v;
                });
              }
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              return _buildListItem(context, list[i]);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: RoundedButton(
            text: dicStaking['action.nominate'] + "-2", 
            onPressed: _selected.length > 0 ? _setNominee : null,
          ),
        ),
      ],
    );
  }
}
