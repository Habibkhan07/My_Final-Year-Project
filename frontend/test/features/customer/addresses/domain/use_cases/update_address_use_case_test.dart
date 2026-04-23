import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/domain/repositories/i_address_repository.dart';
import 'package:frontend/features/customer/addresses/domain/use_cases/update_address_use_case.dart';

class MockAddressRepository extends Mock implements IAddressRepository {}

void main() {
  late UpdateAddressUseCase useCase;
  late MockAddressRepository mockRepository;

  setUp(() {
    mockRepository = MockAddressRepository();
    useCase = UpdateAddressUseCase(mockRepository);
  });

  const tEntity = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: '123 St',
    latitude: 31.0,
    longitude: 74.0,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  test('should call repository.updateAddress and return the entity', () async {
    when(() => mockRepository.updateAddress(
          id: any(named: 'id'),
          isDefault: any(named: 'isDefault'),
        )).thenAnswer((_) async => tEntity);

    final result = await useCase(id: 1, isDefault: true);

    expect(result, tEntity);
    verify(() => mockRepository.updateAddress(id: 1, isDefault: true)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
