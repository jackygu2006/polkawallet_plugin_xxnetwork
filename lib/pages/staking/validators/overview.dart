import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/actions/bondExtraPage.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/actions/stakePage.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/nominatePage.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/validator.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/validatorDetailPage.dart';
import 'package:polkawallet_plugin_xxnetwork/pages/staking/validators/validatorListFilter.dart';
import 'package:polkawallet_plugin_xxnetwork/polkawallet_plugin_xxnetwork.dart';
import 'package:polkawallet_plugin_xxnetwork/service/walletApi.dart';
import 'package:polkawallet_plugin_xxnetwork/store/staking/types/validatorData.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/format.dart';
import 'package:polkawallet_plugin_xxnetwork/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/staking/ownStashInfo.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/MainTabBar.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/outlinedCircle.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

const validator_list_page_size = 100;
const official_nodes_count = 8;

class StakingOverviewPage extends StatefulWidget {
  StakingOverviewPage(this.plugin, this.keyring);
  final PluginXxnetwork plugin;
  final Keyring keyring;
  @override
  _StakingOverviewPageState createState() => _StakingOverviewPageState();
}

class _StakingOverviewPageState extends State<StakingOverviewPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  bool _expanded = false;

  bool _loading = false;
  List<bool> _filters = [true, false];
  String _orderBy = 'current_point'; //'stake_return';
  String _search = '';

  int _tab = 0;
  BigInt nextEraReward;
  BigInt electedCount;
  BigInt avgPoints;

  Future<void> _refreshData() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
    });

    _fetchRecommendedValidators();
    widget.plugin.service.staking.queryElectedInfo();
    await widget.plugin.service.staking.queryOwnStashInfo();
  }

  Future<void> _fetchRecommendedValidators() async {
    Map res = await WalletApi.getRecommended();
    if (res != null && res['validators'] != null) {
      widget.plugin.store.staking
          .setRecommendedValidatorList(res['validators']);
    }
  }

  void _onAction(Future<dynamic> Function() doAction) {
    doAction().then((res) {
      if (res != null) {
        _refreshKey.currentState.show();
      }
    });
  }

  void _goToBond({bondExtra = false}) {
    if (widget.plugin.store.staking.ownStashInfo == null) return;

    final dic = I18n.of(context).getDic(i18n_full_dic_protonet, 'common');
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: Text(dicStaking['action.nominate']),
          content: Text(dicStaking['action.nominate.bond']),
          actions: <Widget>[
            CupertinoButton(
              child: Text(dic['cancel']),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoButton(
              child: Text(dic['ok']),
              onPressed: () async {
                Navigator.of(context).pop();
                _onAction(() => Navigator.pushNamed(context,
                    bondExtra ? BondExtraPage.route : StakePage.route));
              },
            ),
          ],
        );
      },
    );
  }

  void _onSetNomination() {
    if (widget.plugin.store.staking.ownStashInfo == null) return;

    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final hasNomination =
        widget.plugin.store.staking.ownStashInfo.nominating.length > 0;
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Text(
              dicStaking['action.nominee'],
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _onAction(
                  () => Navigator.of(context).pushNamed(NominatePage.route));
            },
          ),
          CupertinoActionSheetAction(
            child: Text(
              dicStaking['action.chill'],
              style: TextStyle(
                  color: hasNomination
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor),
            ),
            onPressed: hasNomination
                ? () {
                    Navigator.of(context).pop();
                    _chill();
                  }
                : () => null,
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(I18n.of(context)
              .getDic(i18n_full_dic_protonet, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _chill() async {
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final params = TxConfirmParams(
      txTitle: dicStaking['action.chill'],
      module: 'staking',
      call: 'chill',
      txDisplay: {'action': 'chill'},
      params: [],
    );
    _onAction(() => Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params));
  }

  Widget _buildTopCard(BuildContext context) {
    // Head卡片
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    final symbol = (widget.plugin.networkState.tokenSymbol ?? ['XX'])[0];
    final decimals = (widget.plugin.networkState.tokenDecimals ?? [12])[0];
    final stashInfo = widget.plugin.store.staking.ownStashInfo;
    final overview = widget.plugin.store.staking.overview;
    final hashData = stashInfo != null && stashInfo.stakingLedger != null;

    int bonded = 0;
    List nominators = [];
    double nominatorListHeight = 48;
    bool isController = false;
    bool isStash = true;
    if (hashData) {
      bonded = int.parse(stashInfo.stakingLedger['active'].toString());
      nominators = stashInfo.nominating.toList();
      if (nominators.length > 0) {
        nominatorListHeight = double.parse((nominators.length * 56).toString());
      }
      isController = stashInfo.isOwnController;
      isStash = stashInfo.isOwnStash ||
          (!stashInfo.isOwnStash && !stashInfo.isOwnController);
    }

    double stakedRatio = 0;
    BigInt totalStaked = BigInt.zero;
    if (overview['totalStaked'] != null) {
      // If sdk return back BN type, use '0x'
      totalStaked = Fmt.balanceInt('0x${overview['totalStaked']}');
      stakedRatio = totalStaked / Fmt.balanceInt(overview['totalIssuance']);
    }

    BigInt avgStaked = BigInt.zero;
    if (overview['avgStaked'] != null) {
      avgStaked = Fmt.balanceInt('0x${overview['avgStaked']}');
    }

    BigInt totalIssuance = BigInt.zero;
    if (overview['totalIssuance'] != null) {
      totalIssuance = Fmt.balanceInt(overview['totalIssuance']);
    }

    BigInt nextEraRewardExceptOfficial = BigInt.zero;
    nextEraReward = BigInt.zero;
    electedCount = Fmt.balanceInt(
        widget.plugin.store.staking.electedInfo.length.toString());
    if (overview['nextEraReward'] != null && electedCount > BigInt.zero) {
      nextEraReward = Fmt.balanceInt('0x${overview['nextEraReward']}');
      nextEraRewardExceptOfficial = BigInt.from(nextEraReward *
          (electedCount - BigInt.from(official_nodes_count)) /
          electedCount);
    }

    avgPoints = overview['avgPoints'] == null
        ? BigInt.zero
        : Fmt.balanceInt(overview['avgPoints'].toString());

    Color actionButtonColor = Theme.of(context).primaryColor;
    Color disabledColor = Theme.of(context).disabledColor;

    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Column(
              children: [
                Text(
                  '${dicStaking['overview.total']}/${dicStaking['overview.totalStakable']} (${(stakedRatio * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 12),
                ),
                Text('', style: TextStyle(fontSize: 8)),
                Text(
                  Fmt.priceFloorBigInt(totalStaked, decimals, lengthFixed: 0) +
                      ' / ' +
                      Fmt.priceFloorBigInt(totalIssuance, decimals,
                          lengthFixed: 0) +
                      ' ' +
                      symbol.toUpperCase(),
                  style: Theme.of(context).textTheme.headline4,
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Row(
              children: [
                InfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: dicStaking['overview.reward'],
                  content: Fmt.ratio(overview['stakedReturn'] == null
                      ? 0
                      : overview['stakedReturn'] / 100),
                ),
                InfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: dicStaking['overview.min'],
                  content: Fmt.balance(overview['minNominated'], decimals) +
                      ' / ' +
                      Fmt.balance(overview['minNominatorBond'], decimals),
                ),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Row(children: [
                InfoItem(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    title: dicStaking['current.avgStaked'],
                    content: Fmt.priceFloorBigInt(avgStaked, decimals,
                            lengthFixed: 0) +
                        ' ' +
                        symbol.toUpperCase()),
                InfoItem(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    title: dicStaking['current.nextReward'],
                    content: Fmt.priceFloorBigInt(
                            nextEraRewardExceptOfficial, decimals,
                            lengthFixed: 0) +
                        ' ' +
                        symbol.toUpperCase())
              ])),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Row(
              children: [
                InfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: dicStaking['current.era'],
                  content: overview['currentEra'].toString(),
                ),
                InfoItem(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  title: dicStaking['everage.points'],
                  content: overview['avgPoints'].toString(),
                ),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Container(
              width: 32,
              child: IconButton(
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
            ),
            title: Text(
              hashData ? stashInfo.nominating.length.toString() : '0',
              style: Theme.of(context).textTheme.headline4,
            ),
            subtitle: Text(
              dicStaking['nominating'],
              style: TextStyle(fontSize: 12),
            ),
            trailing: Container(
              width: 100,
              child: stashInfo?.controllerId == null && isStash
                  ? GestureDetector(
                      child: Column(
                        children: <Widget>[
                          OutlinedCircle(
                            icon: Icons.add,
                            color: actionButtonColor,
                          ),
                          Text(
                            dicStaking['action.nominate'],
                            style: TextStyle(
                                color: actionButtonColor, fontSize: 12),
                          )
                        ],
                      ),
                      onTap: _goToBond,
                    )
                  : isStash && !isController
                      ? Column(
                          children: <Widget>[
                            OutlinedCircle(
                              icon: Icons.add,
                              color: disabledColor,
                            ),
                            Text(
                              dicStaking['action.nominate'],
                              style:
                                  TextStyle(color: disabledColor, fontSize: 12),
                            )
                          ],
                        )
                      : GestureDetector(
                          child: Column(
                            children: <Widget>[
                              OutlinedCircle(
                                icon: Icons.people_alt_outlined,
                                color: actionButtonColor,
                              ),
                              Text(
                                dicStaking[nominators.length > 0
                                    ? 'action.nominee'
                                    : 'action.nominate'],
                                style: TextStyle(
                                    color: actionButtonColor, fontSize: 12),
                              )
                            ],
                          ),
                          onTap: bonded > 0
                              ? _onSetNomination
                              : () => _goToBond(bondExtra: true),
                        ),
            ),
          ),
          AnimatedContainer(
            height: _expanded ? nominatorListHeight : 0,
            duration: Duration(seconds: 1),
            curve: Curves.fastOutSlowIn,
            child: AnimatedOpacity(
              opacity: _expanded ? 1.0 : 0.0,
              duration: Duration(seconds: 1),
              curve: Curves.fastLinearToSlowEaseIn,
              child: nominators.length > 0
                  ? _buildNominatingList()
                  : Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        I18n.of(context)
                            .getDic(i18n_full_dic_ui, 'common')['list.empty'],
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNominatingList() {
    if (widget.plugin.store.staking.ownStashInfo == null ||
        widget.plugin.store.staking.validatorsInfo.length == 0) {
      return Container();
    }

    final stashId = widget.plugin.store.staking.ownStashInfo.stashId;
    final NomineesInfoData nomineesInfo =
        widget.plugin.store.staking.ownStashInfo.inactives;
    List<Widget> list = [];
    if (nomineesInfo != null) {
      list.addAll(nomineesInfo.nomsActive.map((id) {
        return Expanded(
          child: _NomineeItem(
            id,
            widget.plugin.store.staking.validatorsInfo,
            stashId,
            NomStatus.active,
            widget.plugin.networkState.tokenDecimals[0],
            widget.plugin.store.accounts.addressIndexMap,
            widget.plugin.store.accounts.addressIconsMap,
          ),
        );
      }));

      list.addAll(nomineesInfo.nomsOver.map((id) {
        return Expanded(
          child: _NomineeItem(
            id,
            widget.plugin.store.staking.validatorsInfo,
            stashId,
            NomStatus.over,
            widget.plugin.networkState.tokenDecimals[0],
            widget.plugin.store.accounts.addressIndexMap,
            widget.plugin.store.accounts.addressIconsMap,
          ),
        );
      }).toList());

      list.addAll(nomineesInfo.nomsInactive.map((id) {
        return Expanded(
          child: _NomineeItem(
            id,
            widget.plugin.store.staking.validatorsInfo,
            stashId,
            NomStatus.inactive,
            widget.plugin.networkState.tokenDecimals[0],
            widget.plugin.store.accounts.addressIndexMap,
            widget.plugin.store.accounts.addressIconsMap,
          ),
        );
      }).toList());

      list.addAll(nomineesInfo.nomsWaiting.map((id) {
        return Expanded(
          child: _NomineeItem(
            id,
            widget.plugin.store.staking.validatorsInfo,
            stashId,
            NomStatus.waiting,
            widget.plugin.networkState.tokenDecimals[0],
            widget.plugin.store.accounts.addressIndexMap,
            widget.plugin.store.accounts.addressIconsMap,
          ),
        );
      }).toList());
    }
    return Container(
      padding: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: list,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');
    return Observer(
      builder: (_) {
        final int decimals = widget.plugin.networkState.tokenDecimals[0];
        final List<Tab> _listTabs = <Tab>[
          Tab(
            text:
                '${dicStaking['elected']} (${widget.plugin.store.staking.electedInfo.length})',
          ),
          Tab(
            text:
                '${dicStaking['waiting']} (${widget.plugin.store.staking.nextUpsInfo.length})',
          ),
        ];
        List list = [
          // index_0: the overview card
          _buildTopCard(context),
          // index_1: the 'Validators' label
          Container(
            color: Theme.of(context).cardColor,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MainTabBar(
              tabs: [
                '${dicStaking['elected']} (${widget.plugin.store.staking.electedInfo.length})',
                '${dicStaking['waiting']} (${widget.plugin.store.staking.nextUpsInfo.length})'
              ],
              activeTab: _tab,
              fontSize: 18,
              lineWidth: 6,
              onTap: (i) {
                setState(() {
                  _tab = i;
                });
              },
            ),
          ),
        ];
        if (widget.plugin.store.staking.validatorsInfo.length > 0) {
          // index_2: the filter Widget
          list.add(Container(
            color: Colors.white,
            padding: EdgeInsets.only(top: 8),
            child: ValidatorListFilter(
              filters: _filters,
              onFilterChange: (value) {
                if (value != _filters) {
                  setState(() {
                    _filters = value;
                  });
                }
              },
              onOrderBy: (value) {
                if (value != _orderBy) {
                  setState(() {
                    _orderBy = value;
                  });
                }
              },
              onSearchChange: (value) {
                if (value != _search) {
                  setState(() {
                    _search = value;
                  });
                }
              },
            ),
          ));
          // index_3: the recommended validators
          // add recommended
          List<ValidatorData> recommended = [];
          final recommendList = widget.plugin.store.staking
              .recommendedValidators[widget.plugin.basic.name];
          if (recommendList != null) {
            recommended = _tab == 0
                ? widget.plugin.store.staking.electedInfo.toList()
                : widget.plugin.store.staking.nextUpsInfo.toList();
            recommended.retainWhere((i) =>
                widget.plugin.store.staking
                    .recommendedValidators[widget.plugin.basic.name]
                    .indexOf(i.accountId) >
                -1);
          }
          list.add(Container(
            color: Theme.of(context).cardColor,
            child: recommended.length > 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextTag(
                        dicStaking['recommend'],
                        color: Colors.green,
                        fontSize: 12,
                        margin: EdgeInsets.only(left: 16, top: 8),
                      ),
                      Column(
                        children: recommended.map((acc) {
                          Map accInfo = widget.plugin.store.accounts
                              .addressIndexMap[acc.accountId];
                          final icon = widget.plugin.store.accounts
                              .addressIconsMap[acc.accountId];
                          return Validator(
                            acc,
                            accInfo,
                            icon,
                            decimals,
                            widget.plugin.store.staking
                                    .nominationsMap[acc.accountId] ??
                                [],
                          );
                        }).toList(),
                      ),
                      Divider()
                    ],
                  )
                : Container(),
          ));
          // add validators
          List<ValidatorData> ls = _tab == 0
              ? widget.plugin.store.staking.electedInfo.toList()
              : widget.plugin.store.staking.nextUpsInfo.toList();

          // Update nodeReward // ######
          for (int i = 0; i < ls.length; i++) {
            BigInt currentPoints = ls[i].currentPoints == null
                ? BigInt.zero
                : BigInt.from(ls[i].currentPoints);
            ls[i].nodeReward = avgPoints == BigInt.zero
                ? BigInt.zero
                : BigInt.from(
                    nextEraReward * currentPoints / (electedCount * avgPoints));
          }

          // filter list
          ls = PluginFmt.filterValidatorList(ls, _filters, _search,
              widget.plugin.store.accounts.addressIndexMap);
          // sort list
          if (_orderBy == 'stake_return')
            ls.sort((a, b) => a.rankReward < b.rankReward ? 1 : -1);
          else if (_orderBy == 'current_point' || _orderBy == '') {
            try {
              ls.sort(
                  (a, b) => a.currentPoints == null || b.currentPoints == null
                      ? 1
                      : a.currentPoints < b.currentPoints
                          ? 1
                          : -1);
            } catch (e) {
              print(e);
            }
          }

          if (_tab == 1) {
            ls.sort((a, b) {
              final aLength = widget.plugin.store.staking
                      .nominationsMap[a.accountId]?.length ??
                  0;
              final bLength = widget.plugin.store.staking
                      .nominationsMap[b.accountId]?.length ??
                  0;
              return 0 - aLength.compareTo(bLength);
            });
          }
          list.addAll(ls);
        } else {
          list.add(Container(
            height: 160,
            child: CupertinoActivityIndicator(),
          ));
        }
        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _refreshData,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (BuildContext context, int i) {
              // we already have the index_0 - index_3 Widget
              if (i < 4) {
                return list[i];
              }
              ValidatorData acc = list[i];
              Map accInfo =
                  widget.plugin.store.accounts.addressIndexMap[acc.accountId];
              final icon =
                  widget.plugin.store.accounts.addressIconsMap[acc.accountId];
              return Validator(
                acc,
                accInfo,
                icon,
                decimals,
                widget.plugin.store.staking.nominationsMap[acc.accountId] ?? [],
              );
            },
          ),
        );
      },
    );
  }

  validator(ValidatorData e) {}
}

enum NomStatus { active, over, inactive, waiting }

class _NomineeItem extends StatelessWidget {
  _NomineeItem(
    this.id,
    this.validators,
    this.stashId,
    this.nomStatus,
    this.decimals,
    this.accInfoMap,
    this.accIconMap,
  );

  final String id;
  final List<ValidatorData> validators;
  final String stashId;
  final NomStatus nomStatus;
  final int decimals;
  final Map<String, Map> accInfoMap;
  final Map<String, String> accIconMap;

  @override
  Widget build(BuildContext context) {
    final dicStaking =
        I18n.of(context).getDic(i18n_full_dic_protonet, 'staking');

    final validatorIndex = validators.indexWhere((i) => i.accountId == id);
    final validator = validatorIndex < 0
        ? ValidatorData.fromJson({'accountId': id})
        : validators[validatorIndex];

    final accInfo = accInfoMap[validator.accountId];
    final icon = accIconMap[validator.accountId];
    final status = nomStatus.toString().split('.')[1];

    BigInt meStaked;
    int meIndex = validator.nominators.indexWhere((i) => i['who'] == stashId);
    if (meIndex >= 0) {
      meStaked =
          BigInt.parse(validator.nominators[meIndex]['value'].toString());
    }
    String subtitle = dicStaking['nominate.$status'];
    if (nomStatus == NomStatus.active) {
      subtitle += ' ${Fmt.token(meStaked ?? BigInt.zero, decimals)}';
    }

    return ListTile(
      dense: true,
      leading: AddressIcon(validator.accountId, svg: icon, size: 32),
      title: UI.accountDisplayName(validator.accountId, accInfo),
      subtitle: Text(subtitle),
      trailing: Container(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: Container(height: 4),
            ),
            Expanded(
              child: Text(
                  NumberFormat('0.00%').format(validator.commission / 100)),
            ),
            Expanded(
              child: Text(dicStaking['commission'],
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context)
            .pushNamed(ValidatorDetailPage.route, arguments: validator);
      },
    );
  }
}
