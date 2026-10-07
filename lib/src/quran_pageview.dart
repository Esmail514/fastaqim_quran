import 'package:flutter/material.dart';
import 'qcf_theme_data.dart';
import 'qcf_page.dart';
import 'data/qcf_quran.dart';
import 'riwayah.dart';
import 'warsh/warsh_mushaf.dart';
import 'warsh/warsh_page.dart';

/// A horizontally swipeable Quran mushaf using internal QCF fonts.
///
/// - Uses `pageData` to determine surah/verse ranges for each page.
/// - Renders each verse with `QcfVerse`, which applies the correct per-page font.
/// - Supports RTL page order via `reverse: true` and `Directionality.rtl`.
/// - Memory-efficient: only the [±windowSize] pages around the current page
///   are kept alive in the widget tree; all others are freed automatically.
class PageviewQuran extends StatefulWidget {
  /// 1-based initial page number (1..604)
  final int initialPageNumber;
  final QuranRiwayah riwayah;
  final WarshMushaf? warshMushaf;
  final WarshPagePictureBuilder? warshPagePictureBuilder;

  /// Optional placeholder for each Warsh page until its artwork is ready.
  final WidgetBuilder? warshLoadingBuilder;
  final ValueChanged<QuranAyahReference>? onAyahTap;

  /// Optional external controller. If not provided, an internal one is created.
  final PageController? controller;

  //sp (adding 1.sp to get the ratio of screen size for responsive font design)
  final double sp;

  //h (adding 1.h to get the ratio of screen size for responsive font design)
  final double h;

  /// Optional callback when page changes. Provides 1-based page number.
  final ValueChanged<int>? onPageChanged;

  /// Optional override font size passed to each `QcfVerse`.
  final double? fontSize;

  /// Optional theme configuration for customizing all visual aspects.
  /// If null, uses default theme values.
  final QcfThemeData? theme;

  /// Verse text color.
  /// DEPRECATED: Use theme.verseTextColor instead.
  final Color textColor;

  /// Background color for the whole page container.
  /// DEPRECATED: Use theme.pageBackgroundColor instead.
  final Color pageBackgroundColor;

  /// Optional callback to get background color for individual verses.
  /// DEPRECATED: Use theme.verseBackgroundColor instead.
  /// Returns a Color for the verse, or null for no background color.
  /// Useful for highlighting selected verses.
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;

  /// Long-press callbacks that include the pressed verse info.
  final void Function(int surahNumber, int verseNumber)? onLongPress;
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;

  /// Callback when a verse is tapped.
  final void Function(int surahNumber, int verseNumber)? onTap;

  /// Custom scroll physics for the PageView (e.g., BouncingScrollPhysics, ClampingScrollPhysics).
  final ScrollPhysics? physics;

  /// Number of pages to keep alive on each side of the current page.
  /// Total cached window = 2 * windowSize + 1.
  /// Default is 5 (keeps 11 pages in memory at most).
  final int windowSize;

  const PageviewQuran({
    super.key,
    this.initialPageNumber = 1,
    this.riwayah = QuranRiwayah.hafs,
    this.warshMushaf,
    this.warshPagePictureBuilder,
    this.warshLoadingBuilder,
    this.onAyahTap,
    this.controller,
    this.onPageChanged,
    this.fontSize,
    this.sp = 1,
    this.h = 1,
    this.theme,
    this.textColor = const Color(0xFF000000),
    this.pageBackgroundColor = const Color(0xFFFFFFFF),
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.onTap,
    this.physics,
    this.windowSize = 5,
  }) : assert(initialPageNumber >= 1 && initialPageNumber <= totalPagesCount);

  @override
  State<PageviewQuran> createState() => _PageviewQuranState();
}

class _PageviewQuranState extends State<PageviewQuran> {
  PageController? _internalController;
  late int _currentPage;

  PageController get _controller => widget.controller ?? _internalController!;

  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPageNumber;
    if (_ownsController) {
      _internalController = PageController(
        initialPage: widget.initialPageNumber - 1,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? const QcfThemeData();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: widget.theme?.pageBackgroundColor ?? widget.pageBackgroundColor,
        child: PageView.builder(
          physics: widget.physics,
          controller: _controller,
          reverse: false, // right-to-left paging order
          // Disable implicit preloading — we manage the cache window ourselves.
          allowImplicitScrolling: false,
          itemCount:
              widget.riwayah == QuranRiwayah.warsh
                  ? widget.warshMushaf?.pageCount ?? totalPagesCount
                  : totalPagesCount,
          onPageChanged: (index) {
            final newPage = index + 1; // 1-based
            // Rebuild so QcfPage widgets outside the new window release memory.
            setState(() => _currentPage = newPage);
            widget.onPageChanged?.call(newPage);
          },
          itemBuilder: (context, index) {
            final pageNumber = index + 1; // 1-based page
            return RepaintBoundary(
              child: QcfPage(
                pageNumber: pageNumber,
                riwayah: widget.riwayah,
                warshMushaf: widget.warshMushaf,
                warshPagePictureBuilder: widget.warshPagePictureBuilder,
                warshLoadingBuilder: widget.warshLoadingBuilder,
                onAyahTap: widget.onAyahTap,
                currentPage: _currentPage,
                windowSize: widget.windowSize,
                fontSize: widget.fontSize,
                verseBackgroundColor: widget.verseBackgroundColor,
                onLongPress: widget.onLongPress,
                onLongPressUp: widget.onLongPressUp,
                onLongPressCancel: widget.onLongPressCancel,
                onLongPressDown: widget.onLongPressDown,
                onTap: widget.onTap,
                sp: widget.sp,
                h: widget.h,
                theme: effectiveTheme,
              ),
            );
          },
        ),
      ),
    );
  }
}
