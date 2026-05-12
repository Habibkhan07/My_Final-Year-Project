import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/wallet_state.dart';
import '../../domain/failures/wallet_failure.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../data_sources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final IWalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WalletState> getBalance() async {
    try {
      final model = await remoteDataSource.getBalance();
      return model.toEntity();
    } on HttpFailure catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw const WalletPermissionFailure();
      }
      throw WalletServerFailure(e.message);
    } on SocketException catch (_) {
      // **No cache fallback for the wallet balance.** Per CLAUDE.md
      // Tier 3 storage rule and Fix #9: balance is a financial-truth
      // field; a stale read could let the tech accept jobs they no
      // longer have the deposit to cover. Surface the offline error
      // explicitly so the screen prompts reconnect instead of lying.
      throw const WalletNetworkFailure();
    } on FormatException catch (_) {
      throw const WalletServerFailure('Could not parse wallet response.');
    } catch (e) {
      throw WalletServerFailure('Unexpected error: $e');
    }
  }
}
