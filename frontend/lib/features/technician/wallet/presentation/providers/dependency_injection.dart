import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../auth/presentation/providers/dependency_injection.dart';
import '../../data/data_sources/wallet_remote_data_source.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';

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
