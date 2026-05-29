import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:splitmarket/core/services/auth_service.dart';
import 'package:splitmarket/features/auth/controllers/login_controller.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;
  late LoginController controller;

  setUp(() {
    mockAuthService = MockAuthService();
    controller = LoginController(mockAuthService);
  });

  test('deve retornar true quando login for válido', () async {
    when(
      () => mockAuthService.signIn(
        'admin',
        '123',
      ),
    ).thenAnswer((_) async => MockUser());

    final resultado = await controller.fazerLogin(
      'admin',
      '123',
    );

    expect(resultado, true);

    verify(
      () => mockAuthService.signIn(
        'admin',
        '123',
      ),
    ).called(1);
  });
}
