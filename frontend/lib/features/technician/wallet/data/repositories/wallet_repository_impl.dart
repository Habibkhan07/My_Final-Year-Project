import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/wallet_state.dart';
import '../../domain/entities/wallet_transaction_page.dart';
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
      throw _mapHttpFailure(e);
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

  @override
  Future<WalletTransactionPage> listTransactions({String? cursor}) async {
    try {
      final model = await remoteDataSource.listTransactions(cursor: cursor);
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException catch (_) {
      // No cache fallback for the transactions list either — a stale
      // ledger view shown next to a live balance is a usability bug.
      // Explicit offline error → empty-state shows the offline copy.
      throw const WalletNetworkFailure();
    } on FormatException catch (_) {
      throw const WalletServerFailure('Could not parse transactions response.');
    } catch (e) {
      throw WalletServerFailure('Unexpected error: $e');
    }
  }

  WalletFailure _mapHttpFailure(HttpFailure e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return const WalletPermissionFailure();
    }
    return WalletServerFailure(e.message);
  }
}
