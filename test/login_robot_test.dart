import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_rive_animation/screens/login_screen.dart';
import 'package:login_rive_animation/widgets/login_robot.dart';
import 'package:rive/rive.dart' as rive;

// Rive 0.13 needs its native library for Linux rendering tests. On this host:
// LD_PRELOAD=/tmp/robot-native/build/librive_text.so flutter test
Future<void> loadRobot(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    if (find.byType(rive.Rive).evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail('El asset del robot no se dibujó; revisa el runtime nativo de Rive.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Asset real: dimensiones, animaciones y máquina sin inputs heredados',
    () async {
      await rive.RiveFile.initialize();
      final data = await rootBundle.load(LoginRobot.asset);
      final file = rive.RiveFile.import(data);
      final board = file.mainArtboard;
      expect(board.width, 500);
      expect(board.height, 500);
      expect(
        board.animations.map((animation) => animation.name),
        containsAll([
          'Idle',
          'greeting',
          'happy',
          'sad',
          'joystick_mouth',
          'joystick_eyes',
        ]),
      );
      final machine = rive.StateMachineController.fromArtboard(
        board,
        'main_sm',
      );
      expect(machine, isNotNull);
      expect(machine!.inputs, isEmpty);
      machine.dispose();
      // The previous character remains packaged as a backup.
      expect(
        (await rootBundle.load('assets/login-bear-animation.riv'))
            .lengthInBytes,
        greaterThan(0),
      );
    },
  );

  for (final width in [240.0, 360.0, 768.0]) {
    testWidgets('Robot completo con ancho $width, sin errores de pintura', (
      tester,
    ) async {
      final controller = LoginRobotController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 250,
                child: LoginRobot(controller: controller),
              ),
            ),
          ),
        ),
      );
      await loadRobot(tester);
      await tester.pump(const Duration(milliseconds: 100));
      final widget = tester.widget<rive.Rive>(find.byType(rive.Rive));
      expect(widget.fit, BoxFit.contain);
      expect(widget.alignment, Alignment.center);
      widget.artboard.forEachComponent((component) {
        if (component is rive.Fill) {
          expect(component.fillRule, inInclusiveRange(0, 1));
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }

  testWidgets(
    'Saludo, éxito y error usan las pistas reales sin duplicar controladores',
    (tester) async {
      final controller = LoginRobotController();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 250,
            child: LoginRobot(controller: controller),
          ),
        ),
      );
      await loadRobot(tester);
      final board = tester.widget<rive.Rive>(find.byType(rive.Rive)).artboard;
      expect(board.animationControllers.length, 4);
      for (final event in [
        (controller.focusEmail, 'greeting'),
        (controller.succeed, 'happy'),
        (controller.fail, 'sad'),
        (controller.fail, 'sad'),
      ]) {
        event.$1();
        await tester.pump(const Duration(milliseconds: 100));
        expect(board.animationControllers.where((c) => c.isActive).length, 1);
        final active =
            board.animationControllers.where((c) => c.isActive).single
                as rive.SimpleAnimation;
        expect(active.animationName, event.$2);
        expect(board.animationControllers.length, 4);
        expect(tester.takeException(), isNull);
      }
      controller.reset();
      await tester.pump();
      expect(
        (board.animationControllers.where((c) => c.isActive).single
                as rive.SimpleAnimation)
            .animationName,
        'Idle',
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Correo y contraseña visible/oculta conservan sus señales visuales',
    (tester) async {
      final controller = LoginRobotController();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 250,
            child: LoginRobot(controller: controller),
          ),
        ),
      );
      await loadRobot(tester);
      controller.trackEmail(200);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.emailProgress, 1);
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset.dx,
        greaterThan(0),
      );
      controller.focusPassword(hidden: true);
      await tester.pump();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      controller.focusPassword(hidden: false);
      await tester.pump();
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login valida campos completos con un único mensaje global', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await loadRobot(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '');
    await tester.enterText(fields.at(1), '');
    await tester.ensureVisible(find.byType(MaterialButton));
    await tester.tap(find.byType(MaterialButton));
    await tester.pump();
    expect(find.text('Completa el correo y la contraseña.'), findsOneWidget);
    expect(find.text('Email inválido'), findsNothing);
    expect(find.text('Contraseña inválida'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });
}
