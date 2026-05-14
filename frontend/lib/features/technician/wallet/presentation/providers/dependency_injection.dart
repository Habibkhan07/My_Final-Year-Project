import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../auth/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/wallet_remote_data_source.dart';
import '../../data/data_sources/withdrawal_remote_data_source.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../data/repositories/withdrawal_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/repositories/withdrawal_repository.dart';

part 'dependency_injection.g.dart';

/// Wallet-feature HTTP client. Distinct provider so widget tests can
/// override JUST this dependency with a ``MockClient`` without affecting
/// other features.
@Riverpod(keepAlive: true)
http.Client walletHttpClient(Ref ref) => http.Client();

@Riverpod(keepAlive: true)
IWalletRemoteDataSource walletRemoteDataSource(Ref ref) {
  return WalletRemoteDataSource(
    client: ref.watch(walletHttpClientProvider),
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) {
  return WalletRepositoryImpl(
    remoteDataSource: ref.watch(walletRemoteDataSourceProvider),
  );
}

/// Withdrawal-flow data source. Reuses [walletHttpClientProvider] so
/// widget tests overriding the wallet client get withdrawal stubs for
/// free, and so the two features share a connection pool.
@Riverpod(keepAlive: true)
IWithdrawalRemoteDataSource withdrawalRemoteDataSource(Ref ref) {
  return WithdrawalRemoteDataSource(
    client: ref.watch(walletHttpClientProvider),
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  );
}

/// Withdrawal repository — step 2 of the 4-step error pipeline. Maps
/// HttpFailure / SocketException / FormatException to the sealed
/// [WithdrawalFailure] family.
@Riverpod(keepAlive: true)
WithdrawalRepository withdrawalRepository(Ref ref) {
  return WithdrawalRepositoryImpl(
    remoteDataSource: ref.watch(withdrawalRemoteDataSourceProvider),
  );
}
