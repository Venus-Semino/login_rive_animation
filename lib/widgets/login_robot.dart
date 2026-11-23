import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

enum RobotReaction { idle, greeting, success, failure }

/// Visual events only: authentication remains owned by the login screen.
class LoginRobotController extends ChangeNotifier {
  RobotReaction reaction = RobotReaction.idle;
  int revision = 0;
  double emailProgress = 0;
  bool passwordHidden = false;

  void _react(RobotReaction value) {
    reaction = value;
    revision++;
    notifyListeners();
  }

  void focusEmail() {
    passwordHidden = false;
    emailProgress = 0;
    _react(RobotReaction.greeting);
  }

  void trackEmail(int length) {
    emailProgress = (length / 80).clamp(0.0, 1.0);
    passwordHidden = false;
    notifyListeners();
  }

  void focusPassword({required bool hidden}) {
    emailProgress = 0;
    passwordHidden = hidden;
    _react(RobotReaction.idle);
  }

  void clearFocus() {
    emailProgress = 0;
    passwordHidden = false;
    notifyListeners();
  }

  void reset() {
    emailProgress = 0;
    passwordHidden = false;
    _react(RobotReaction.idle);
  }

  void succeed() => _react(RobotReaction.success);
  void fail() => _react(RobotReaction.failure);
}

class LoginRobot extends StatefulWidget {
  const LoginRobot({required this.controller, super.key});

  static const asset = 'assets/Login_robot.riv';
  final LoginRobotController controller;

  @override
  State<LoginRobot> createState() => _LoginRobotState();
}

class _LoginRobotState extends State<LoginRobot> {
  rive.Artboard? _artboard;
  rive.SimpleAnimation? _idle;
  final _reactions = <RobotReaction, rive.OneShotAnimation>{};
  int _lastRevision = -1;
  bool _loadFailed = false;
  bool _disposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVisualEvent);
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await rive.RiveFile.asset(LoginRobot.asset);
      if (!mounted) return;
      final artboard = file.mainArtboard.instance();
      // Rive 0.13 indexes Flutter's two fill rules directly. This asset also
      // contains clockwise (2). Use the same winding fallback as Rive's Skia
      // renderer, without altering the original .riv or the package runtime:
      // https://github.com/rive-app/rive-runtime/blob/main/skia/renderer/include/to_skia.hpp
      artboard.forEachComponent((component) {
        if (component is rive.Fill && component.fillRule == 2) {
          component.fillType = PathFillType.nonZero;
        }
      });
      // These are timelines verified in this asset, not Yeti state inputs.
      if (artboard.animationByName('Idle') != null) {
        _idle = rive.SimpleAnimation('Idle');
        artboard.addController(_idle!);
      }
      for (final entry in {
        RobotReaction.greeting: 'greeting',
        RobotReaction.success: 'happy',
        RobotReaction.failure: 'sad',
      }.entries) {
        if (artboard.animationByName(entry.value) == null) continue;
        final animation = rive.OneShotAnimation(
          entry.value,
          autoplay: false,
          onStop: () {
            if (!_disposing &&
                mounted &&
                !_reactions.values.any((value) => value.isActive)) {
              _idle?.isActive = true;
            }
          },
        );
        artboard.addController(animation);
        _reactions[entry.key] = animation;
      }
      setState(() => _artboard = artboard);
      _onVisualEvent();
    } catch (error) {
      if (!mounted) return;
      debugPrint('No se pudo cargar la animación del robot: $error');
      setState(() => _loadFailed = true);
    }
  }

  void _onVisualEvent() {
    if (!mounted || _disposing) return;
    final controller = widget.controller;
    if (_artboard != null && controller.revision != _lastRevision) {
      _lastRevision = controller.revision;
      for (final animation in _reactions.values) {
        animation.isActive = false;
      }
      final selected = _reactions[controller.reaction];
      _idle?.isActive = selected == null;
      if (selected != null) {
        selected.reset();
        selected.isActive = true;
      }
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant LoginRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onVisualEvent);
      widget.controller.addListener(_onVisualEvent);
      _lastRevision = -1;
      _onVisualEvent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Robot del inicio de sesión',
      image: true,
      child: Padding(
        // Leave room for the optional movement without clipping the artboard.
        padding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: Offset(widget.controller.emailProgress * 0.025, 0),
                child: _artboard == null
                    ? Center(
                        child: Icon(
                          _loadFailed
                              ? Icons.smart_toy_outlined
                              : Icons.smart_toy,
                          size: 64,
                        ),
                      )
                    : rive.Rive(
                        key: const ValueKey('login-robot-artwork'),
                        artboard: _artboard!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
              ),
            ),
            // This file has no hands-up input: use an explicit visual cue.
            if (widget.controller.passwordHidden)
              const Positioned(
                bottom: 0,
                right: 0,
                child: Icon(Icons.lock_outline, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposing = true;
    widget.controller.removeListener(_onVisualEvent);
    for (final controller in [?_idle, ..._reactions.values]) {
      _artboard?.removeController(controller);
    }
    _reactions.clear();
    super.dispose();
  }
}
