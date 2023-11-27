import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

void runAppWithoutImplicitView(Widget app) {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  assert(binding.debugCheckZone('runApp'));
  binding
    ..scheduleAttachRootWidget(app) // ignore: invalid_use_of_protected_member
    ..scheduleWarmUpFrame();
}

void main() {
  runAppWithoutImplicitView(MultiViewApp(
    viewBuilder: (BuildContext context) => const SpinningSquare(),
  ));
}

class SpinningSquare extends StatefulWidget {
  const SpinningSquare({super.key});

  @override
  State<SpinningSquare> createState() => _SpinningSquareState();
}

class _SpinningSquareState extends State<SpinningSquare>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    duration: const Duration(milliseconds: 3600),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int viewId = View.of(context).viewId;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RotationTransition(
          turns: _animation,
          child: Container(
              width: 200.0,
              height: 200.0,
              color: _colors[viewId % _colors.length],
              child: Center(
                child: Text('View#$viewId'),
              )),
        ),
      ),
    );
  }
}

const List<Color> _colors = <Color>[
  Color(0xFFC70039),
  Color(0xFF581845),
  Color(0xFFFFC305),
  Color(0xFFFF5733),
  Color(0xFF900C3F),
];

/// Calls [viewBuilder] for every view added to the app to obtain the widget to
/// render into that view. The current view can be looked up with [View.of].
class MultiViewApp extends StatefulWidget {
  const MultiViewApp({super.key, required this.viewBuilder});

  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewApp> createState() => _MultiViewAppState();
}

class _MultiViewAppState extends State<MultiViewApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didUpdateWidget(MultiViewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Need to re-evaluate the viewBuilder callback for all views.
    _views.clear();
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  Map<Object, Widget> _views = <Object, Widget>{};

  void _updateViews() {
    final Map<Object, Widget> newViews = <Object, Widget>{};
    for (final FlutterView view
        in WidgetsBinding.instance.platformDispatcher.views) {
      if (view.viewId == 0) {
        // skip the implicit view
        continue;
      }
      final Widget viewWidget = _views[view.viewId] ?? _createViewWidget(view);
      newViews[view.viewId] = viewWidget;
    }
    setState(() {
      _views = newViews;
    });
  }

  Widget _createViewWidget(FlutterView view) {
    return View(
      view: view,
      child: Builder(
        builder: widget.viewBuilder,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewCollection(views: _views.values.toList(growable: false));
  }
}
