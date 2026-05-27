import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:splitmarket/services/auth_service.dart';
import 'package:splitmarket/controller/login_controller.dart';

class MockAuthService extends Mock
    implements AuthService {}

void main() {

  late MockAuthService mockAuthService;

  late LoginController controller;

  setUp(() {

    mockAuthService =
        MockAuthService();

    controller =
        LoginController(
          mockAuthService,
        );
  });

  test(
    'deve retornar true quando login for válido',
    () {

      when(
        () => mockAuthService.login(
          'admin',
          '123',
        ),
      ).thenReturn(true);

      final resultado =
          controller.fazerLogin(
            'admin',
            '123',
          );

      expect(resultado, true);

      verify(
        () => mockAuthService.login(
          'admin',
          '123',
        ),
      ).called(1);
    },
  );
}