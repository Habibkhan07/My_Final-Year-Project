// Loads the tech-qualified sub-services for a parent service id. Read
// by `QuoteBuilderSheet` so the dropdown populates with only the items
// THIS tech can legally charge for.
//
// `keepAlive: true` — once a tech opens the sheet for a given parent
// service, subsequent opens (same session) re-render instantly. The
// dataset is small (typically 2–10 rows per service) and rarely
// changes; refetching would just delay the sheet for no benefit.
//
// `family<int>` keyed on `serviceId`. Two bookings under the same
// parent service share the cache.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/quotable_sub_service_model.dart';
import 'dependency_injection.dart';

part 'quotable_sub_services_notifier.g.dart';

@Riverpod(keepAlive: true)
class QuotableSubServicesNotifier extends _$QuotableSubServicesNotifier {
  @override
  Future<List<QuotableSubServiceModel>> build(int serviceId) async {
    final dataSource = ref.watch(quotableSubServicesRemoteDataSourceProvider);
    return dataSource.fetchForService(serviceId);
  }
}
