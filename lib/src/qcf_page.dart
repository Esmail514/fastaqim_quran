import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'qcf_theme_data.dart';
import 'data/fastaqim_quran.dart';
import 'header_widget.dart';
import 'riwayah.dart';
import 'warsh/warsh_mushaf.dart';
import 'warsh/warsh_page.dart';

/// A widget that renders a single page of the Quran.
///
/// Use this if you want to build your own [PageView] or layout
/// and need granular control over each page's state and rendering.
class QcfPage extends StatefulWidget {
  /// The 1-based page number (1..604).
  final int pageNumber;

  /// Hafs is the existing default; Warsh retains its own page numbering.
  final QuranRiwayah riwayah;
  final WarshMushaf? warshMushaf;
  final WarshPagePictureBuilder? warshPagePictureBuilder;
  final WidgetBuilder? warshLoadingBuilder;
  final ValueChanged<QuranAyahReference>? onAyahTap;

  /// Theme configuration for styling the page.
  final QcfThemeData theme;

  /// Optional font size override.
  final double? fontSize;

  /// Scaling factor for screen width/pixel density (default 1.0).
  /// Used for responsive sizing of fonts and layout.
  final double sp;

  /// Scaling factor for screen height (default 1.0).
  /// Used for responsive vertical spacing.
  final double h;

  /// Gently use spare portrait height without scaling Hafs glyphs or changing
  /// their line breaks. Short pages and overflowing content retain their layout.
  final bool fitPageHeight;

  /// Callback when a verse is long-pressed.
  final void Function(int surahNumber, int verseNumber)? onLongPress;

  /// Callback when long-press ends.
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;

  /// Callback when long-press is cancelled.
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;

  /// Callback when long-press starts (includes details).
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;

  /// Callback when a verse is tapped.
  /// Can be used together with the long-press callbacks in either riwayah.
  final void Function(int surahNumber, int verseNumber)? onTap;

  /// Optional callback to customize verse background color dynamically.
  /// This takes precedence over [QcfThemeData.verseBackgroundColor] if provided.
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;

  /// Hide only the ayah text, retaining its layout, marker and gestures.
  final bool Function(int surahNumber, int verseNumber)? isVerseHidden;

  /// The current page the user is viewing (1-based). Used for windowed caching.
  /// Pages outside `currentPage ± windowSize` are released from memory.
  final int currentPage;

  /// Number of pages to keep alive on each side of the current page.
  /// Default matches [PageviewQuran.windowSize] default of 5.
  final int windowSize;

  const QcfPage({
    super.key,
    required this.pageNumber,
    this.riwayah = QuranRiwayah.hafs,
    this.warshMushaf,
    this.warshPagePictureBuilder,
    this.warshLoadingBuilder,
    this.onAyahTap,
    this.currentPage = 1,
    this.windowSize = 5,
    this.theme = const QcfThemeData(),
    this.fontSize,
    this.sp = 1.0,
    this.h = 1.0,
    this.fitPageHeight = false,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.onTap,
    this.verseBackgroundColor,
    this.isVerseHidden,
  });

  @override
  State<QcfPage> createState() => _QcfPageState();
}

class _QcfPageState extends State<QcfPage> with AutomaticKeepAliveClientMixin {
  final _recognizers = <(int, int), GestureRecognizer>{};
  final _textKey = GlobalKey();
  final _tapRanges = <(int, int, int, int)>[];
  Object? _heightFitInputs;
  double? _baselineTextHeight;
  double? _fittedLineHeight;

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  void _fontsChanged() {
    if (!mounted || !widget.fitPageHeight) return;
    setState(() => _heightFitInputs = null);
  }

  void _measureHeightFit(
    Object inputs,
    double availableHeight,
    double baseLineHeight,
    double scaledFontSize,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _heightFitInputs != inputs) return;
      final paragraph = _textKey.currentContext?.findRenderObject();
      if (paragraph is! RenderParagraph || !paragraph.hasSize) return;
      final textHeight = paragraph.textSize.height;
      _baselineTextHeight ??= textHeight;
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset:
              paragraph.text.toPlainText(includeSemanticsLabels: false).length,
        ),
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      final lineTops = <double>[];
      for (final box in boxes) {
        if (box.bottom <= box.top) continue;
        if (!lineTops.any((top) => (top - box.top).abs() < 0.5)) {
          lineTops.add(box.top);
        }
      }
      if (lineTops.isEmpty || scaledFontSize <= 0) return;
      final spareHeight = math.max(0.0, availableHeight - _baselineTextHeight!);
      // Only a small increase: at most 12% or 6 logical pixels per line.
      final extraPerLine = math.min(
        spareHeight / lineTops.length,
        math.min(scaledFontSize * baseLineHeight * 0.12, 6.0),
      );
      var fittedHeight =
          _fittedLineHeight ?? baseLineHeight + extraPerLine / scaledFontSize;
      final currentHeight = _fittedLineHeight ?? baseLineHeight;
      if (textHeight > availableHeight && currentHeight > baseLineHeight) {
        // Real inline widgets can dominate a line. Back off using the actual
        // paragraph height instead of assuming that every line is plain text.
        fittedHeight = math.max(
          baseLineHeight,
          currentHeight -
              (textHeight - availableHeight) /
                  (lineTops.length * scaledFontSize),
        );
      }
      if ((fittedHeight - currentHeight).abs() > 0.0001) {
        setState(() => _fittedLineHeight = fittedHeight);
      }
    });
  }

  void _tapAt(Offset position) {
    final paragraph = _textKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) return;
    for (final (start, end, surah, verse) in _tapRanges) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (boxes.any((box) => box.toRect().contains(position))) {
        widget.onTap?.call(surah, verse);
        widget.onAyahTap?.call(
          QuranAyahReference(
            riwayah: QuranRiwayah.hafs,
            surahNumber: surah,
            verseNumber: verse,
          ),
        );
        return;
      }
    }
  }

  bool _hasLongPress(QcfPage page) =>
      page.onLongPress != null ||
      page.onLongPressDown != null ||
      page.onLongPressUp != null ||
      page.onLongPressCancel != null;

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  GestureRecognizer? _recognizerFor(int surah, int verse) {
    if (_hasLongPress(widget)) {
      final recognizer =
          _recognizers.putIfAbsent((
                surah,
                verse,
              ), () => LongPressGestureRecognizer())
              as LongPressGestureRecognizer;
      recognizer.onLongPress = () => widget.onLongPress?.call(surah, verse);
      recognizer.onLongPressStart =
          (d) => widget.onLongPressDown?.call(surah, verse, d);
      recognizer.onLongPressUp = () => widget.onLongPressUp?.call(surah, verse);
      recognizer.onLongPressCancel =
          () => widget.onLongPressCancel?.call(surah, verse);
      return recognizer;
    }
    if (widget.onTap != null || widget.onAyahTap != null) {
      final recognizer =
          _recognizers.putIfAbsent((surah, verse), () => TapGestureRecognizer())
              as TapGestureRecognizer;
      recognizer.onTap = () {
        widget.onTap?.call(surah, verse);
        widget.onAyahTap?.call(
          QuranAyahReference(
            riwayah: widget.riwayah,
            surahNumber: surah,
            verseNumber: verse,
          ),
        );
      };
      return recognizer;
    }
    return null;
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    _disposeRecognizers();
    super.dispose();
  }

  @override
  bool get wantKeepAlive =>
      (widget.pageNumber - widget.currentPage).abs() <= widget.windowSize;

  @override
  void didUpdateWidget(QcfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.riwayah != widget.riwayah ||
        _hasLongPress(oldWidget) != _hasLongPress(widget) ||
        (oldWidget.onTap != null || oldWidget.onAyahTap != null) !=
            (widget.onTap != null || widget.onAyahTap != null)) {
      _disposeRecognizers();
    }
    // Notify the keep-alive system whenever currentPage changes so pages
    // that drift outside the window are freed without a full rebuild.
    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.windowSize != widget.windowSize) {
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // Validate page number
    if (widget.pageNumber < 1 || widget.pageNumber > 604) {
      return Center(child: Text('Invalid page number: ${widget.pageNumber}'));
    }

    if (widget.riwayah == QuranRiwayah.warsh) {
      return WarshPage(
        pageNumber: widget.pageNumber,
        mushaf: widget.warshMushaf,
        pictureBuilder: widget.warshPagePictureBuilder,
        loadingBuilder: widget.warshLoadingBuilder,
        theme: widget.theme,
        verseBackgroundColor: widget.verseBackgroundColor,
        isVerseHidden: widget.isVerseHidden,
        onAyahTap:
            widget.onTap == null && widget.onAyahTap == null
                ? null
                : (ref) {
                  widget.onTap?.call(ref.surahNumber, ref.verseNumber);
                  widget.onAyahTap?.call(ref);
                },
        onAyahLongPress:
            widget.onLongPress == null
                ? null
                : (ref) =>
                    widget.onLongPress!(ref.surahNumber, ref.verseNumber),
        onAyahLongPressUp:
            widget.onLongPressUp == null
                ? null
                : (ref) =>
                    widget.onLongPressUp!(ref.surahNumber, ref.verseNumber),
        onAyahLongPressCancel:
            widget.onLongPressCancel == null
                ? null
                : (ref) =>
                    widget.onLongPressCancel!(ref.surahNumber, ref.verseNumber),
        onAyahLongPressStart:
            widget.onLongPressDown == null
                ? null
                : (ref, details) => widget.onLongPressDown!(
                  ref.surahNumber,
                  ref.verseNumber,
                  details,
                ),
      );
    }

    final ranges = getPageData(widget.pageNumber);
    final pageFont = "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";
    // Note: User preferred multiplication logic for scaling
    final baseFontSize = getFontSize(widget.pageNumber, context) * widget.sp;
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    final verseSpans = <InlineSpan>[];
    final spanReferences = <InlineSpan, (int, int)>{};
    if (widget.pageNumber == 2 || widget.pageNumber == 1) {
      verseSpans.add(
        WidgetSpan(child: SizedBox(height: screenSize.height * .175)),
      );
    }
    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (int v = start; v <= end; v++) {
        if (v == start && v == 1) {
          if (widget.theme.showHeader) {
            verseSpans.add(
              WidgetSpan(
                child: HeaderWidget(suraNumber: surah, theme: widget.theme),
              ),
            );
          }
          if (widget.theme.showBasmala &&
              widget.pageNumber != 1 &&
              widget.pageNumber != 187) {
            // Check for custom Basmala builder
            if (widget.theme.basmalaBuilder != null) {
              verseSpans.add(
                WidgetSpan(
                  child: widget.theme.basmalaBuilder!(surah),
                  alignment: PlaceholderAlignment.middle,
                ),
              );
              // Add a newline after custom builder to maintain layout flow if needed
              // or let the builder handle it. Usually basmala is a block.
              // We'll add a newline ensuring separation.
              verseSpans.add(const TextSpan(text: "\n"));
            } else {
              verseSpans.add(
                TextSpan(
                  text: " ﱁ  ﱂﱃﱄ\n",
                  style: TextStyle(
                    fontFamily: "QCF_P001",
                    package: 'fastaqim_quran',
                    fontSize:
                        getScreenType(context) == ScreenType.large
                            ? widget.theme.basmalaFontSizeLarge * widget.sp
                            : widget.theme.basmalaFontSizeSmall * widget.sp,
                    color: widget.theme.basmalaColor,
                  ),
                ),
              );
            }
          }
        }

        // Gesture Handling
        // The span keeps long-press recognition. A wrapping detector uses
        // glyph selection boxes for short taps when both gestures are enabled.
        final recognizer = _recognizerFor(surah, v);

        final verseBgColor =
            widget.theme.verseBackgroundColor?.call(surah, v) ??
            widget.verseBackgroundColor?.call(surah, v);
        final hidden = widget.isVerseHidden?.call(surah, v) ?? false;

        // Verse Number Logic
        InlineSpan verseNumberSpan;
        if (widget.theme.verseNumberBuilder != null) {
          final customMarker = widget.theme.verseNumberBuilder!(
            surah,
            v,
            getVerseNumberQCF(surah, v),
          );
          verseNumberSpan =
              hidden
                  ? TextSpan(
                    style: TextStyle(color: widget.theme.verseNumberColor),
                    children: [customMarker],
                  )
                  : customMarker;
        } else {
          verseNumberSpan = TextSpan(
            text: getVerseNumberQCF(surah, v),
            recognizer: recognizer,
            style: TextStyle(
              fontFamily: pageFont,
              package: 'fastaqim_quran',
              color: widget.theme.verseNumberColor,
              height: widget.theme.verseNumberHeight * widget.h,
              backgroundColor:
                  widget.theme.verseNumberBackgroundColor ?? verseBgColor,
            ),
          );
        }

        final verseText = getVerseQCF(surah, v, verseEndSymbol: false);
        final span = TextSpan(
          text:
              surah == ranges[0]['surah'] && v == ranges[0]['start']
                  ? "${verseText.substring(0, 1)}\u200A${verseText.substring(1)}"
                  : verseText,
          recognizer: recognizer,
          semanticsLabel: hidden ? '' : null,
          style:
              hidden || verseBgColor != null
                  ? TextStyle(
                    color: hidden ? Colors.transparent : null,
                    backgroundColor: verseBgColor,
                  )
                  : null,
          children: [verseNumberSpan],
        );
        verseSpans.add(span);
        spanReferences[span] = (surah, v);
      }
    }

    _tapRanges.clear();
    var offset = 0;
    for (final span in verseSpans) {
      final end =
          offset + span.toPlainText(includeSemanticsLabels: false).length;
      final reference = spanReferences[span];
      if (reference != null) {
        _tapRanges.add((offset, end, reference.$1, reference.$2));
      }
      offset = end;
    }

    final fontSize =
        widget.fontSize ??
        widget.theme.fontSize ??
        (isPortrait
            ? baseFontSize
            : (widget.pageNumber == 1 || widget.pageNumber == 2)
            ? 20 * widget.sp
            : baseFontSize - (17 * widget.sp));
    final baseLineHeight =
        isPortrait
            ? (widget.pageNumber == 1 || widget.pageNumber == 2)
                ? 2.2 * widget.h
                : widget.theme.verseHeight * widget.h
            : (widget.pageNumber == 1 || widget.pageNumber == 2)
            ? 4 *
                widget
                    .h // simplified based on user's manual edit evaluation
            : 4 * widget.h; // simplified based on user's manual edit evaluation
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitHeight =
            widget.fitPageHeight &&
            isPortrait &&
            widget.pageNumber > 2 &&
            constraints.hasBoundedHeight;
        if (fitHeight) {
          final scaledFontSize = MediaQuery.textScalerOf(
            context,
          ).scale(fontSize);
          final inputs = (
            constraints.maxWidth,
            constraints.maxHeight,
            widget.pageNumber,
            fontSize,
            scaledFontSize,
            baseLineHeight,
            widget.theme.verseNumberHeight,
            widget.theme.showHeader,
            widget.theme.showBasmala,
            widget.theme.customHeaderBuilder,
            widget.theme.basmalaBuilder,
            widget.theme.verseNumberBuilder,
            widget.theme.headerFontSizeLarge,
            widget.theme.headerFontSizeSmall,
            widget.theme.basmalaFontSizeLarge,
            widget.theme.basmalaFontSizeSmall,
          );
          if (_heightFitInputs != inputs) {
            _heightFitInputs = inputs;
            _baselineTextHeight = null;
            _fittedLineHeight = null;
          }
          _measureHeightFit(
            inputs,
            constraints.maxHeight,
            baseLineHeight,
            scaledFontSize,
          );
        } else {
          _heightFitInputs = null;
        }
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: fitHeight ? constraints.maxHeight : 0,
            ),
            child: Align(
              alignment: Alignment.center,
              heightFactor: 1,
              child: SizedBox(
                width: screenSize.width,
                child: GestureDetector(
                  onTapUp:
                      _hasLongPress(widget) &&
                              (widget.onTap != null || widget.onAyahTap != null)
                          ? (details) => _tapAt(details.localPosition)
                          : null,
                  child: Text.rich(
                    key: _textKey,
                    TextSpan(children: verseSpans),
                    locale: const Locale("ar"),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: pageFont,
                      package: 'fastaqim_quran',
                      fontSize: fontSize,
                      color: widget.theme.verseTextColor,
                      height:
                          fitHeight
                              ? _fittedLineHeight ?? baseLineHeight
                              : baseLineHeight,
                      letterSpacing: widget.theme.letterSpacing,
                      wordSpacing: widget.theme.wordSpacing,
                    ),
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
