import 'dart:math' show min, max;
import 'dart:ui' show FlutterWindow;
import 'dart:async' show Completer;

import 'package:flutter/widgets.dart';

class ScreenUtil {
  static const Size defaultSize = Size(360, 690);
  static ScreenUtil _instance = ScreenUtil._();

  /// UI设计中手机尺寸 , dp
  /// Size of the phone in UI Design , dp
  late Size _uiSize;

  ///屏幕方向
  late Orientation _orientation;

  late double _screenWidth;
  late double _screenHeight;
  late bool _minTextAdapt;
  BuildContext? _context;
  late bool _splitScreenMode;

  ScreenUtil._();

  factory ScreenUtil() {
    return _instance;
  }

  static Future<void> ensureScreenSize([
    FlutterWindow? window,
    Duration duration = const Duration(milliseconds: 10),
  ]) async {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    window ??= binding.window;

    if (window.viewConfiguration.geometry.isEmpty) {
      return Future.delayed(duration, () async {
        binding.deferFirstFrame();
        await ensureScreenSize(window, duration);
        return binding.allowFirstFrame();
      });
    }
  }

  Set<Element>? _elementsToRebuild;

  static void registerToBuild(
    BuildContext context, [
    bool withDescendants = false,
  ]) {
    (_instance._elementsToRebuild ??= {}).add(context as Element);

    if (withDescendants) {
      context.visitChildren((element) {
        registerToBuild(element, true);
      });
    }
  }

  /// Initializing the library.
  static Future<void> init(
    BuildContext context, {
    Size designSize = defaultSize,
    bool splitScreenMode = false,
    bool minTextAdapt = false,
  }) async {
    final navigatorContext = Navigator.maybeOf(context)?.context as Element?;
    final mediaQueryContext =
        navigatorContext?.getElementForInheritedWidgetOfExactType<MediaQuery>();

    final initCompleter = Completer<void>();

    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
      mediaQueryContext?.visitChildElements((el) => _instance._context = el);
      if (_instance._context != null) initCompleter.complete();
    });

    final deviceData = MediaQuery.maybeOf(context).nonEmptySizeOrNull();

    final deviceSize = deviceData?.size ?? designSize;
    final orientation = deviceData?.orientation ??
        (deviceSize.width > deviceSize.height
            ? Orientation.landscape
            : Orientation.portrait);

    _instance
      .._context = context
      .._uiSize = designSize
      .._splitScreenMode = splitScreenMode
      .._minTextAdapt = minTextAdapt
      .._orientation = orientation
      .._screenWidth = deviceSize.width
      .._screenHeight = deviceSize.height;

    _instance._elementsToRebuild?.forEach((el) => el.markNeedsBuild());

    return initCompleter.future;
  }

  ///Get screen orientation
  Orientation get orientation => _orientation;

  /// The number of font pixels for each logical pixel.
  double get textScaleFactor =>
      _context != null ? MediaQuery.of(_context!).textScaleFactor : 1;

  /// The size of the media in logical pixels (e.g, the size of the screen).
  double? get pixelRatio =>
      _context != null ? MediaQuery.of(_context!).devicePixelRatio : 1;

  /// The horizontal extent of this size.
  double get screenWidth =>
      _context != null ? MediaQuery.of(_context!).size.width : _screenWidth;

  ///The vertical extent of this size. dp
  double get screenHeight =>
      _context != null ? MediaQuery.of(_context!).size.height : _screenHeight;

  /// The offset from the top, in dp
  double get statusBarHeight =>
      _context == null ? 0 : MediaQuery.of(_context!).padding.top;

  /// The offset from the bottom, in dp
  double get bottomBarHeight =>
      _context == null ? 0 : MediaQuery.of(_context!).padding.bottom;

  /// The ratio of actual width to UI design
  double get scaleWidth => screenWidth / _uiSize.width;

  ///  /// The ratio of actual height to UI design
  double get scaleHeight =>
      (_splitScreenMode ? max(screenHeight, 700) : screenHeight) /
      _uiSize.height;

  double get scaleText =>
      _minTextAdapt ? min(scaleWidth, scaleHeight) : scaleWidth;

  double setWidth(num width) => width * scaleWidth;

  double setHeight(num height) => height * scaleHeight;

  double radius(num r) => r * min(scaleWidth, scaleHeight);

  ///- [fontSize] The size of the font on the UI design, in dp.
  double setSp(num fontSize) => fontSize * scaleText;

  Widget setVerticalSpacing(num height) => SizedBox(height: setHeight(height));

  Widget setVerticalSpacingFromWidth(num height) =>
      SizedBox(height: setWidth(height));

  Widget setHorizontalSpacing(num width) => SizedBox(width: setWidth(width));

  Widget setHorizontalSpacingRadius(num width) =>
      SizedBox(width: radius(width));

  Widget setVerticalSpacingRadius(num height) =>
      SizedBox(height: radius(height));
}

extension on MediaQueryData? {
  MediaQueryData? nonEmptySizeOrNull() {
    if (this?.size.isEmpty ?? true)
      return null;
    else
      return this;
  }
}
