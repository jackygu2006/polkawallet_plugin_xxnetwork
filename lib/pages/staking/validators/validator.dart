import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/validatorDetailPage.dart';
import 'package:polkawallet_plugin_xxnetwork/store/staking/types/validatorData.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class Validator extends StatelessWidget {
  Validator(
    this.validator,
    this.accInfo,
    this.icon,
    this.decimals,
    this.nominations,
  ) : isWaiting = validator.total == BigInt.zero;

  final ValidatorData validator;
  final Map accInfo;
  final String icon;
  final int decimals;
  final bool isWaiting;
  final List nominations;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final cmixRoot = validator.cmixRoot != null && validator.cmixRoot != ''
        ? validator.cmixRoot
        : '';
    final points =
        validator.points != null && validator.points > 0 ? validator.points : 0;
    var currentPoints =
        validator.currentPoints != null && validator.currentPoints > 0
            ? validator.currentPoints
            : 0;
    return GestureDetector(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: AddressIcon(validator.accountId, svg: icon),
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
                    !isWaiting
                        ? '${dic['total']}: ${validator.total != null ? Fmt.token(validator.total, decimals) : '~'}'
                        : '${dic['nominators']}: ${nominations.length}',
                    style: TextStyle(
                      color: Theme.of(context).unselectedWidgetColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${dic['commission']}: ${NumberFormat('0.00%').format(validator.commission / 100)}',
                    style: TextStyle(
                      color: Theme.of(context).unselectedWidgetColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${dic['points']}: ${dic['current']} ${currentPoints.toString()}, ${dic['last']} ${points.toString()}',
                    style: TextStyle(
                      color: Theme.of(context).unselectedWidgetColor,
                      fontSize: 12,
                    ),
                  ),
                  cmixRoot != ''
                      ? Text(
                          '${dic['cmix_root']}: ${validator.cmixId.substring(0, 8) + '...' + validator.cmixId.substring(validator.cmixId.length - 8, validator.cmixId.length)}',
                          style: TextStyle(
                            color: Theme.of(context).unselectedWidgetColor,
                            fontSize: 12,
                          ),
                        )
                      : '',
                ],
              ),
            ),
            !isWaiting
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // ######
                      // Text("节点收益",
                      //     style: TextStyle(
                      //         fontSize: 12,
                      //         color: Theme.of(context).unselectedWidgetColor)),
                      // Text("320xx"),
                      // Text("", style: TextStyle(fontSize: 6)),
                      Text(dic['reward'],
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).unselectedWidgetColor)),
                      Text(validator.isActive
                          ? '${validator.stakedReturnCmp.toStringAsFixed(2)}%'
                          : '~'),
                    ],
                  )
                : Container()
          ],
        ),
      ),
      onTap: validator.isActive
          ? () {
              // webApi.staking.queryValidatorRewards(validator.accountId);
              Navigator.of(context)
                  .pushNamed(ValidatorDetailPage.route, arguments: validator);
            }
          : null,
    );
  }
}
