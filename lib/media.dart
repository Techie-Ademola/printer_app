import 'package:flutter/material.dart';

dynamic height;
dynamic width;

// This functions are responsible to make UI responsive across all the mobile devices.
Size size = WidgetsBinding.instance.window.physicalSize /
    WidgetsBinding.instance.window.devicePixelRatio;

// Caution! If you think these are static values and are used to build a static UI,  you must not.
// These are the Viewport values of your Design.
// These are used in the code as a reference to create your UI Responsively.
const num designWidth = 375;
const num designHeight = 812;
const num designStatusBar = 44;

///get device viewport width.
get getWidth {
  return size.width;
}

///get device viewport height.
double get getHeight {
  EdgeInsets padding =
      MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;
  double statusBar = padding.top;
  double bottomBar = padding.bottom;
  double screenHeight = size.height - statusBar - bottomBar;
  return screenHeight;
}

///set padding/margin (for the left and Right side) & width of the screen or widget according to the Viewport width.
double getHorizontalSize(double px) {
  return ((px * getWidth) / designWidth);
}

///set padding/margin (for the top and bottom side) & height of the screen or widget according to the Viewport height.
double getVerticalSize(double px) {
  return ((px * getHeight) / (designHeight - designStatusBar));
}

///set smallest px in image height and width
double getSize(double px) {
  var height = getVerticalSize(px);
  var width = getHorizontalSize(px);
  if (height < width) {
    return height.toInt().toDouble();
  } else {
    return width.toInt().toDouble();
  }
}

///set text font size according to Viewport
double getFontSize(double px) {
  return getSize(px);
}

///set padding responsively
EdgeInsetsGeometry getPadding({
  double? all,
  double? left,
  double? top,
  double? right,
  double? bottom,
}) {
  return getMarginOrPadding(
    all: all,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}

///set margin responsively
EdgeInsetsGeometry getMargin({
  double? all,
  double? left,
  double? top,
  double? right,
  double? bottom,
}) {
  return getMarginOrPadding(
    all: all,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}

///get padding or margin responsively
EdgeInsetsGeometry getMarginOrPadding({
  double? all,
  double? left,
  double? top,
  double? right,
  double? bottom,
}) {
  if (all != null) {
    left = all;
    top = all;
    right = all;
    bottom = all;
  }
  return EdgeInsets.only(
    left: getHorizontalSize(
      left ?? 0,
    ),
    top: getVerticalSize(
      top ?? 0,
    ),
    right: getHorizontalSize(
      right ?? 0,
    ),
    bottom: getVerticalSize(
      bottom ?? 0,
    ),
  );
}
