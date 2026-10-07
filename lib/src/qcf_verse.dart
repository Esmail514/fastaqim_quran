import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'qcf_theme_data.dart';
import 'data/mushaf_riwayat.dart';
import 'riwayah.dart';
import 'warsh/warsh_mushaf.dart';
import 'warsh/warsh_verse_text.dart';

class QcfVerse extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final QuranRiwayah riwayah;
  final WarshMushaf? warshMushaf;
  final VoidCallback? onTap;
  final double? fontSize;

  /// Optional theme configuration for customizing all visual aspects.
  /// If null, uses default theme values.
  final QcfThemeData? theme;

  /// Verse text color.
  /// DEPRECATED: Use theme.verseTextColor instead.
  final Color textColor;

  /// Background color for verse.
  /// DEPRECATED: Use theme.verseBackgroundColor instead.
  final Color backgroundColor;

  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressUp;

  final VoidCallback? onLongPressCancel;
  final Function(LongPressDownDetails)? onLongPressDown;
  //sp (adding 1.sp to get the ratio of screen size for responsive font design)
  final double sp;

  //h (adding 1.h to get the ratio of screen size for responsive font design)
  final double h;

  final TextAlign textAlign;

  const QcfVerse({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    this.riwayah = QuranRiwayah.hafs,
    this.warshMushaf,
    this.onTap,
    this.fontSize,
    this.theme,
    this.textColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0x00000000),
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.sp = 1,
    this.h = 1,
    this.textAlign = TextAlign.center,
  });

  @override
  State<QcfVerse> createState() => _QcfVerseState();
}

class _QcfVerseState extends State<QcfVerse> {
  LongPressGestureRecognizer? _recognizer;

  @override
  void initState() {
    super.initState();
    _updateRecognizer();
  }

  @override
  void didUpdateWidget(QcfVerse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateRecognizer();
  }

  void _updateRecognizer() {
    final hasListener =
        widget.onLongPress != null ||
        widget.onLongPressDown != null ||
        widget.onLongPressUp != null ||
        widget.onLongPressCancel != null;

    if (hasListener) {
      _recognizer ??= LongPressGestureRecognizer();
      _recognizer!
        ..onLongPress = widget.onLongPress
        ..onLongPressDown = widget.onLongPressDown
        ..onLongPressUp = widget.onLongPressUp
        ..onLongPressCancel = widget.onLongPressCancel;
    } else {
      _recognizer?.dispose();
      _recognizer = null;
    }
  }

  @override
  void dispose() {
    _recognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? const QcfThemeData();
    if (widget.riwayah == QuranRiwayah.warsh) {
      return WarshVerseText(
        surahNumber: widget.surahNumber,
        firstVerse: widget.verseNumber,
        lastVerse: widget.verseNumber,
        mushaf: widget.warshMushaf,
        fontSize: widget.fontSize ?? effectiveTheme.fontSize ?? 28 * widget.sp,
        theme: effectiveTheme.copyWith(
          verseTextColor: widget.theme?.verseTextColor ?? widget.textColor,
          verseBackgroundColor:
              (s, v) =>
                  widget.theme?.verseBackgroundColor?.call(s, v) ??
                  ((widget.backgroundColor.toARGB32() >> 24) > 0
                      ? widget.backgroundColor
                      : null),
        ),
        textAlign: widget.textAlign,
        onTap: widget.onTap == null ? null : (_, _) => widget.onTap!(),
        onLongPress:
            widget.onLongPress == null ? null : (_, _) => widget.onLongPress!(),
        onLongPressUp:
            widget.onLongPressUp == null
                ? null
                : (_, _) => widget.onLongPressUp!(),
        onLongPressCancel:
            widget.onLongPressCancel == null
                ? null
                : (_, _) => widget.onLongPressCancel!(),
        onLongPressDown:
            widget.onLongPressDown == null
                ? null
                : (_, _, details) => widget.onLongPressDown!(details),
      );
    }
    var pageNumber = getPageNumber(widget.surahNumber, widget.verseNumber);
    var pageFontSize = getFontSize(pageNumber, context);

    final verseTextColor = widget.theme?.verseTextColor ?? widget.textColor;
    final verseBgColor =
        widget.theme?.verseBackgroundColor?.call(
          widget.surahNumber,
          widget.verseNumber,
        ) ??
        ((widget.backgroundColor.toARGB32() >> 24) > 0
            ? widget.backgroundColor
            : null);

    final String fontFamily = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    final double effectiveFontSize =
        widget.fontSize ?? pageFontSize / widget.sp;

    // getVerseQCF(verseEndSymbol: false) now correctly strips both the glyph
    // and trailing '\n' (if any), returning pure verse text.
    final String textWithoutSymbol = getVerseQCF(
      widget.surahNumber,
      widget.verseNumber,
      verseEndSymbol: false,
    );

    // getVerseNumberQCF now correctly returns the glyph even when followed by '\n'.
    final String verseNumberGlyph = getVerseNumberQCF(
      widget.surahNumber,
      widget.verseNumber,
    );

    // Check if the original string had a trailing newline so we can append it
    // after the colored glyph span without it affecting the background color box.
    final String fullVerseText = getVerseQCF(
      widget.surahNumber,
      widget.verseNumber,
      verseEndSymbol: true,
    );
    final bool hasTrailingNewline = fullVerseText.endsWith('\n');

    final content = RichText(
      textDirection: TextDirection.rtl,
      textAlign: widget.textAlign,
      textScaler: MediaQuery.of(context).textScaler,
      text: TextSpan(
        recognizer: _recognizer,
        text: textWithoutSymbol,
        locale: const Locale("ar"),
        children: [
          TextSpan(
            text: verseNumberGlyph,
            recognizer: _recognizer,
            style: TextStyle(
              fontFamily: fontFamily,
              package: 'mushaf_riwayat',
              color: effectiveTheme.verseNumberColor,
              height: effectiveTheme.verseNumberHeight / widget.h,
              fontSize: effectiveFontSize,
              backgroundColor:
                  effectiveTheme.verseNumberBackgroundColor ?? verseBgColor,
            ),
          ),
          if (hasTrailingNewline) const TextSpan(text: '\n'),
        ],
        style: TextStyle(
          color: verseTextColor,
          height: effectiveTheme.verseHeight / widget.h,
          letterSpacing: effectiveTheme.letterSpacing,
          package: 'mushaf_riwayat',
          wordSpacing: effectiveTheme.wordSpacing,
          fontFamily: fontFamily,
          fontSize: effectiveFontSize,
          backgroundColor: verseBgColor,
        ),
      ),
    );
    return widget.onTap == null
        ? content
        : GestureDetector(onTap: widget.onTap, child: content);
  }
}
