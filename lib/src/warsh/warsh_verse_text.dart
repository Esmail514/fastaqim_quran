import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import '../qcf_theme_data.dart';
import 'warsh_mushaf.dart';

/// Flowing ayah text using Warsh's unchanged source and paired Unicode font.
/// Printed page layout is provided by WarshPage instead.
class WarshVerseText extends StatefulWidget {
  final int surahNumber;
  final int firstVerse;
  final int lastVerse;
  final WarshMushaf? mushaf;
  final QcfThemeData theme;
  final double fontSize;
  final TextAlign textAlign;
  final bool showVerseNumbers;
  final String Function(int)? verseNumberFormatter;
  final void Function(int, int)? onTap;
  final void Function(int, int)? onLongPress;
  final void Function(int, int)? onLongPressUp;
  final void Function(int, int)? onLongPressCancel;
  final void Function(int, int, LongPressDownDetails)? onLongPressDown;

  const WarshVerseText({
    super.key,
    required this.surahNumber,
    required this.firstVerse,
    required this.lastVerse,
    this.mushaf,
    this.theme = const QcfThemeData(),
    this.fontSize = 28,
    this.textAlign = TextAlign.center,
    this.showVerseNumbers = true,
    this.verseNumberFormatter,
    this.onTap,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
  });

  @override
  State<WarshVerseText> createState() => _WarshVerseTextState();
}

class _WarshVerseTextState extends State<WarshVerseText> {
  final _textKey = GlobalKey();
  late Future<WarshMushaf> _source;
  final _ranges = <(int, int, int)>[];
  int? _pressed;

  bool get _hasLongPress =>
      widget.onLongPress != null ||
      widget.onLongPressUp != null ||
      widget.onLongPressCancel != null ||
      widget.onLongPressDown != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _source =
          widget.mushaf == null
              ? WarshMushaf.load()
              : Future.value(widget.mushaf!);

  @override
  void didUpdateWidget(WarshVerseText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mushaf != widget.mushaf) _load();
    _pressed = null;
  }

  int? _hit(Offset point) {
    final paragraph = _textKey.currentContext?.findRenderObject();
    if (paragraph is! RenderParagraph) return null;
    for (final (start, end, verse) in _ranges) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (boxes.any((box) => box.toRect().contains(point))) return verse;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WarshMushaf>(
    future: _source,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('تعذر تحميل نص ورش');
      if (!snapshot.hasData ||
          snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final mushaf = snapshot.requireData;
      if (widget.surahNumber < 1 ||
          widget.surahNumber > 114 ||
          widget.firstVerse < 1 ||
          widget.lastVerse < widget.firstVerse ||
          widget.lastVerse > mushaf.getVerseCount(widget.surahNumber)) {
        return const Text('رقم الآية غير صالح في رواية ورش');
      }
      final spans = <InlineSpan>[];
      _ranges.clear();
      var offset = 0;
      for (var v = widget.firstVerse; v <= widget.lastVerse; v++) {
        final verse = mushaf.getVerse(widget.surahNumber, v);
        final content = verse.textWithoutEndMarker;
        final marker =
            widget.showVerseNumbers
                ? ' ${widget.verseNumberFormatter?.call(v) ?? verse.endMarker}'
                : '';
        final color = widget.theme.verseBackgroundColor?.call(
          widget.surahNumber,
          v,
        );
        spans.add(
          TextSpan(
            text: content,
            style: TextStyle(backgroundColor: color),
            children: [
              if (marker.isNotEmpty)
                TextSpan(
                  text: marker,
                  style: TextStyle(
                    color: widget.theme.verseNumberColor,
                    backgroundColor:
                        widget.theme.verseNumberBackgroundColor ?? color,
                  ),
                ),
            ],
          ),
        );
        _ranges.add((offset, offset + content.length + marker.length, v));
        offset += content.length + marker.length + 1;
        spans.add(const TextSpan(text: ' '));
      }
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapUp:
            widget.onTap == null
                ? null
                : (details) {
                  final verse = _hit(details.localPosition);
                  if (verse != null) widget.onTap!(widget.surahNumber, verse);
                },
        onLongPressDown:
            !_hasLongPress
                ? null
                : (details) {
                  _pressed = _hit(details.localPosition);
                  if (_pressed != null) {
                    widget.onLongPressDown?.call(
                      widget.surahNumber,
                      _pressed!,
                      details,
                    );
                  }
                },
        onLongPress:
            !_hasLongPress
                ? null
                : () {
                  if (_pressed != null) {
                    widget.onLongPress?.call(widget.surahNumber, _pressed!);
                  }
                },
        onLongPressEnd:
            !_hasLongPress
                ? null
                : (_) {
                  if (_pressed != null) {
                    widget.onLongPressUp?.call(widget.surahNumber, _pressed!);
                  }
                  _pressed = null;
                },
        onLongPressCancel:
            !_hasLongPress
                ? null
                : () {
                  if (_pressed != null) {
                    widget.onLongPressCancel?.call(
                      widget.surahNumber,
                      _pressed!,
                    );
                  }
                  _pressed = null;
                },
        child: RichText(
          key: _textKey,
          textDirection: TextDirection.rtl,
          textAlign: widget.textAlign,
          textScaler: MediaQuery.textScalerOf(context),
          locale: const Locale('ar'),
          text: TextSpan(
            children: spans,
            style: TextStyle(
              fontFamily: mushaf.fontFamily,
              package: 'qcf_quran',
              fontSize: widget.fontSize,
              color: widget.theme.verseTextColor,
              height: widget.theme.verseHeight,
            ),
          ),
        ),
      );
    },
  );
}
