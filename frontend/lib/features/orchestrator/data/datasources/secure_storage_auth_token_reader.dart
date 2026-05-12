import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/ports/auth_token_reader.dart';

/// Default [IAuthTokenReader] implementation backed by
/// `flutter_secure_storage`. The token-key literal is owned here (not
/// duplicated in every reader) so changing the storage key requires a
/// single edit.
class SecureStorageAuthTokenReader implements IAuthTokenReader {
  SecureStorageAuthTokenReader(this._storage);

  final FlutterSecureStorage _storage;

  // Wire-string shared with `auth_local_data_source.dart` — the auth
  // feature writes the same key on login. A typo here silently strips
  // the Authorization header from every orchestrator POST and the
  // backend returns 401, so the literal is centralised in the data
  // layer rather than scattered across executors.
  static const _kAuthTokenKey = 'auth_token';

  @override
  Future<String?> read() => _storage.read(key: _kAuthTokenKey);
}
