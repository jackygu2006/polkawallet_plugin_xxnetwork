import 'package:get_storage/get_storage.dart';

const String plugin_protonet_storage_key = 'plugin_protonet';
const String plugin_xxnetwork_storage_key = 'plugin_xxnetwork';

abstract class StoreCache {
  static final _storage = () => GetStorage(plugin_protonet_storage_key);

  /// staking network state
  final stakingOverview = {}.val('stakingOverview', getBox: _storage);
  final validatorsInfo = {}.val('validatorsInfo', getBox: _storage);

  /// governance network state
  final councilInfo = {}.val('councilInfo', getBox: _storage);

  /// account staking data
  final stakingOwnStash = {}.val('stakingOwnStash', getBox: _storage);
  final stakingTxs = {}.val('stakingTxs', getBox: _storage);
  final stakingRewardTxs = {}.val('stakingRewardTxs', getBox: _storage);
}

class StoreCacheProtonet extends StoreCache {
  static final _storage = () => GetStorage(plugin_protonet_storage_key);

  /// staking network state
  final stakingOverview = {}.val('stakingOverview', getBox: _storage);
  final validatorsInfo = {}.val('validatorsInfo', getBox: _storage);

  /// governance network state
  final councilInfo = {}.val('councilInfo', getBox: _storage);

  /// account staking data
  final stakingOwnStash = {}.val('stakingOwnStash', getBox: _storage);
  final stakingTxs = {}.val('stakingTxs', getBox: _storage);
  final stakingRewardTxs = {}.val('stakingRewardTxs', getBox: _storage);
}

class StoreCacheXxnetwork extends StoreCache {
  static final _storage = () => GetStorage(plugin_xxnetwork_storage_key);

  /// staking network state
  final stakingOverview = {}.val('stakingOverview', getBox: _storage);
  final validatorsInfo = {}.val('validatorsInfo', getBox: _storage);

  /// governance network state
  final councilInfo = {}.val('councilInfo', getBox: _storage);

  /// account staking data
  final stakingOwnStash = {}.val('stakingOwnStash', getBox: _storage);
  final stakingTxs = {}.val('stakingTxs', getBox: _storage);
  final stakingRewardTxs = {}.val('stakingRewardTxs', getBox: _storage);
}
