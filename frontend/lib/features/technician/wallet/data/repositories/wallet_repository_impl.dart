import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/topup_session.dart';
import '../../domain/entities/topup_status.dart';
import '../../domain/entities/wallet_state.dart';
import '../../domain/entities/wallet_transaction_page.dart';
import '../../domain/failures/topup_failure.dart';
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
      throw _mapWalletHttpFailure(e);
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
      throw _mapWalletHttpFailure(e);
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

  @override
  Future<TopupSession> startTopup({required int amountRs}) async {
    try {
      final model = await remoteDataSource.startTopup(amountRs: amountRs);
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapTopupHttpFailure(e);
    } on SocketException catch (_) {
      throw const TopupNetworkFailure();
    } on FormatException catch (_) {
      throw const TopupServerFailure();
    } on TopupFailure {
      rethrow;
    } catch (e) {
      throw TopupServerFailure('Unexpected error: $e');
    }
  }

  @override
  Future<TopupStatus> pollTopupStatus({required int topupId}) async {
    try {
      final model = await remoteDataSource.getTopupStatus(topupId: topupId);
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapTopupHttpFailure(e);
    } on SocketException catch (_) {
      throw const TopupNetworkFailure();
    } on FormatException catch (_) {
      throw const TopupServerFailure();
    } on TopupFailure {
      rethrow;
    } catch (e) {
      throw TopupServerFailure('Unexpected error: $e');
    }
  }

  WalletFailure _mapWalletHttpFailure(HttpFailure e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return const WalletPermissionFailure();
    }
    return WalletServerFailure(e.message);
  }

  /// Maps the topup-flow HTTP error codes (per WALLET_API.md) to the
  /// sealed [TopupFailure] family. Order matters: amount range is
  /// 400 + structured ``code`` so we inspect ``code`` before falling
  /// back to a generic server failure.
  TopupFailure _mapTopupHttpFailure(HttpFailure e) {
    if (e.statusCode == 401 || e.statusCode == 403 || e.statusCode == 404) {
      // 404 on the status endpoint = IDOR (someone else's topup id).
      // Same failure surface as 401/403 — the user is not authorised.
      return const TopupPermissionFailure();
    }
    if (e.statusCode == 503 && e.code == 'gateway_unavailable') {
      return const TopupGatewayUnavailable();
    }
    if (e.statusCode == 400) {
      // The backend's ``errors`` map contains amount-specific copy;
      // the WALLET_API.md contract pins ``code='validation_error'``
      // for both bad-int and out-of-range. Use sentinel min/max
      // matching the server-side constants in topup_service.
      return const TopupInvalidAmount(minimum: 100, maximum: 25000);
    }
    return TopupServerFailure(e.message);
  }
}
