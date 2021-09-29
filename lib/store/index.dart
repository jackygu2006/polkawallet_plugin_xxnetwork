import 'package:polkawallet_plugin_xxnetwork/store/accounts.dart';
import 'package:polkawallet_plugin_xxnetwork/store/cache/storeCache.dart';
import 'package:polkawallet_plugin_xxnetwork/store/gov/governance.dart';
import 'package:polkawallet_plugin_xxnetwork/store/staking/staking.dart';

class PluginStore {
  PluginStore(StoreCache cache)
      : staking = StakingStore(cache),
        gov = GovernanceStore(cache);
  final StakingStore staking;
  final GovernanceStore gov;
  final AccountsStore accounts = AccountsStore();
}
