import 'package:flutter/material.dart';

import 'dart:async';

class TooltipArrowPainter extends CustomPainter {
  final Size size;
  final Color color;
  final bool isInverted;

  TooltipArrowPainter({
    required this.size,
    required this.color,
    required this.isInverted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isInverted) {
      path.moveTo(0.0, size.height);
      path.lineTo(size.width / 2, 0.0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0.0, 0.0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0.0);
    }
    
    path.close();

    canvas.drawShadow(path, Colors.black, 4.0, false);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TooltipArrow extends StatelessWidget {
  final Size size;
  final Color color;
  final bool isInverted;

  const TooltipArrow({
    super.key,
    this.size = const Size(16.0, 16.0),
    this.color = Colors.white,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-size.width / 2, 0.0),
      child: CustomPaint(
        size: size,
        painter: TooltipArrowPainter(
          size: size,
          color: color,
          isInverted: isInverted,
        ),
      ),
    );
  }
}

// A tooltip with text, action buttons, and an arrow pointing to the target.
class AnimatedTooltip extends StatefulWidget {
  final String message;
  final GlobalKey? target;
  final Duration? delay;
  final ThemeData? theme;
  final Widget? child;

  const AnimatedTooltip({
    super.key,
    required this.message,
    this.target,
    this.theme,
    this.delay,
    this.child,
  }) : assert(child != null || target != null);

  @override
  State<StatefulWidget> createState() => AnimatedTooltipState();
}

class AnimatedTooltipState extends State<AnimatedTooltip> with SingleTickerProviderStateMixin {
  late double? _tooltipTop;
  late double? _tooltipBottom;
  late Alignment _tooltipAlignment;
  late Alignment _transitionAlignment;
  late Alignment _arrowAlignment;
  bool _isInverted = false;
  Timer? _delayTimer;

  final _arrowSize = const Size(16.0, 16.0);
  final _tooltipMinimumHeight = 140;

  final _overlayController = OverlayPortalController();
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutBack,
  );

  _toggle() {
    _delayTimer?.cancel();
    _animationController.stop();
    if (_overlayController.isShowing) {
      _animationController.reverse().then((_) {
        _overlayController.hide();
      });
    } else {
      _updatePosition();
      _overlayController.show();
      _animationController.forward();
    }
  }

  _updatePosition() {
    final Size contextSize = MediaQuery.of(context).size;
    final BuildContext? targetContext = widget.target != null
      ? widget.target!.currentContext
      : context;
    final targetRenderBox = targetContext?.findRenderObject() as RenderBox;
    final targetOffset = targetRenderBox.localToGlobal(Offset.zero);
    final targetSize = targetRenderBox.size;
    // Try to position the tooltip above the target, otherwise try to position it below or in the middle.
    final tooltipFitsAboveTarget = targetOffset.dy - _tooltipMinimumHeight >= 0;
    final tooltipFitsBelowTarget = targetOffset.dy + targetSize.height + _tooltipMinimumHeight <= contextSize.height;
    _tooltipTop = tooltipFitsAboveTarget
        ? null
        : tooltipFitsBelowTarget
            ? targetOffset.dy + targetSize.height
            : null;
    _tooltipBottom = tooltipFitsAboveTarget
        ? contextSize.height - targetOffset.dy
        : tooltipFitsBelowTarget
            ? null
            : targetOffset.dy + targetSize.height / 2;
    _isInverted = _tooltipTop != null;
    // Align the tooltip relative to the target.
    _tooltipAlignment = Alignment(
      (targetOffset.dx) / (contextSize.width - targetSize.width) * 2 - 1.0,
      _isInverted ? 1.0 : -1.0,
    );
    // Make the tooltip appear from the point of the arrow.
    _transitionAlignment = Alignment(
      (targetOffset.dx + targetSize.width / 2) / contextSize.width * 2 - 1.0,
      _isInverted ? -1.0 : 1.0,
    );
    // Center the arrow on the target.
    _arrowAlignment = Alignment(
      (targetOffset.dx + targetSize.width / 2) / (contextSize.width - _arrowSize.width) * 2 - 1.0,
      _isInverted ? 1.0 : -1.0,
    );
  }

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.delay != null) {
        _toggle();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? ThemeData(
      useMaterial3: true,
      brightness: Theme.of(context).brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light,
    );

    return OverlayPortal.targetsRootOverlay(
      controller: _overlayController,
      child: widget.child != null
          ? GestureDetector(onTap: _toggle, child: widget.child)
          : null,
      overlayChildBuilder: (context) {
        return Positioned(
          top: _tooltipTop,
          bottom: _tooltipBottom,
          child: ScaleTransition(
            alignment: _transitionAlignment,
            scale: _scaleAnimation,
            child: TapRegion(
              onTapOutside: (PointerDownEvent event) {
                _toggle();
              },
              child: Theme(
                data: theme,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInverted)
                        Align(
                          alignment: _arrowAlignment,
                          child: TooltipArrow(
                            size: _arrowSize,
                            isInverted: true,
                            color: theme.canvasColor,
                          ),
                        ),
                      Align(
                        alignment: _tooltipAlignment,
                        child: IntrinsicWidth(
                          child: Material(
                            elevation: 4.0,
                            color: theme.canvasColor,
                            borderRadius: BorderRadius.circular(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(widget.message),
                                  const SizedBox(height: 16.0),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: _toggle,
                                      child: const Text('OK'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!_isInverted)
                        Align(
                          alignment: _arrowAlignment,
                          child: TooltipArrow(
                            size: _arrowSize,
                            isInverted: false,
                            color: theme.canvasColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
