import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../qcf_theme_data.dart';
import '../riwayah.dart';
import 'warsh_mushaf.dart';

typedef WarshPagePictureBuilder =
    Widget Function(BuildContext context, WarshPageData page);

/// A fixed printed page with its original per-ayah polygons as hit targets.
/// The artwork and hit targets scale together, including negative viewBox
/// origins on the opening pages. Text never reflows on a narrower screen.
class WarshPage extends StatefulWidget {
  final int pageNumber;
  final WarshMushaf? mushaf;
  final QcfThemeData theme;
  final WarshPagePictureBuilder? pictureBuilder;

  /// Optional placeholder while page geometry and SVG artwork are loading.
  final WidgetBuilder? loadingBuilder;
  final ValueChanged<QuranAyahReference>? onAyahTap;
  final ValueChanged<QuranAyahReference>? onAyahLongPress;
  final ValueChanged<QuranAyahReference>? onAyahLongPressUp;
  final ValueChanged<QuranAyahReference>? onAyahLongPressCancel;
  final void Function(QuranAyahReference, LongPressStartDetails)?
  onAyahLongPressStart;
  final Color? Function(int, int)? verseBackgroundColor;

  const WarshPage({
    super.key,
    required this.pageNumber,
    this.mushaf,
    this.theme = const QcfThemeData(),
    this.pictureBuilder,
    this.loadingBuilder,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onAyahLongPressUp,
    this.onAyahLongPressCancel,
    this.onAyahLongPressStart,
    this.verseBackgroundColor,
  });

  @override
  State<WarshPage> createState() => _WarshPageState();
}

class _WarshPageState extends State<WarshPage> {
  late Future<_LoadedWarshPage?> _page;
  PictureInfo? _pictureInfo;
  int _loadGeneration = 0;
  QuranAyahReference? _pressed;

  bool get _hasLongPress =>
      widget.onAyahLongPress != null ||
      widget.onAyahLongPressStart != null ||
      widget.onAyahLongPressUp != null ||
      widget.onAyahLongPressCancel != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _pressed = null;
    _releasePicture();
    final generation = ++_loadGeneration;
    final mushaf = widget.mushaf;
    final pageNumber = widget.pageNumber;
    final customPicture = widget.pictureBuilder != null;
    _page = () async {
      try {
        final edition = mushaf ?? await WarshMushaf.load();
        final page = await edition.loadPage(pageNumber);
        if (customPicture) return _LoadedWarshPage(page, null);
        final BytesLoader loader;
        if (page.svgAsset != null) {
          loader = SvgAssetLoader(
            page.svgAsset!,
            packageName: 'mushaf_riwayat',
          );
        } else if (page.svgUri != null) {
          loader = SvgNetworkLoader(page.svgUri.toString());
        } else {
          throw StateError('No artwork source for Warsh page $pageNumber');
        }
        final picture = await vg.loadPicture(loader, null);
        if (!mounted || generation != _loadGeneration) {
          picture.picture.dispose();
          throw StateError('Warsh page was replaced while loading');
        }
        _pictureInfo = picture;
        return _LoadedWarshPage(page, picture);
      } catch (_) {
        // A retry can fail before FutureBuilder subscribes on the next frame.
        // Represent failure as data to avoid an unhandled future error.
        return null;
      }
    }();
  }

  void _releasePicture() {
    final previous = _pictureInfo;
    _pictureInfo = null;
    if (previous != null) {
      // A previous painter may still belong to the frame being replaced.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => previous.picture.dispose(),
      );
    }
  }

  @override
  void dispose() {
    ++_loadGeneration;
    _releasePicture();
    super.dispose();
  }

  @override
  void didUpdateWidget(WarshPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.mushaf != widget.mushaf ||
        oldWidget.pictureBuilder != widget.pictureBuilder) {
      _load();
    }
  }

  Widget _picture(BuildContext context, _LoadedWarshPage loaded) {
    if (widget.pictureBuilder != null) {
      return widget.pictureBuilder!(context, loaded.page);
    }
    return CustomPaint(
      painter: _WarshArtworkPainter(
        loaded.picture!,
        widget.theme.verseTextColor == const Color(0xff000000)
            ? null
            : ColorFilter.mode(widget.theme.verseTextColor, BlendMode.srcIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_LoadedWarshPage?>(
    future: _page,
    builder: (context, snapshot) {
      if (snapshot.hasError ||
          (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasData)) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعذر تحميل صفحة ورش',
                style: TextStyle(color: widget.theme.verseTextColor),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: widget.theme.verseTextColor,
                ),
                onPressed: () => setState(_load),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData ||
          snapshot.connectionState != ConnectionState.done) {
        return widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator());
      }
      final loaded = snapshot.requireData!;
      final page = loaded.page;
      return Semantics(
        label: 'صفحة ورش ${page.pageNumber} جاهزة للقراءة',
        // A full-page accessibility tap has no ayah coordinate. Expose its
        // readiness as a label rather than pretending the whole page is a button.
        excludeSemantics: true,
        child: ColoredBox(
          color: widget.theme.pageBackgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.theme.horizontalPadding,
              vertical: widget.theme.verticalPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : page.viewBox.width;
                final height =
                    constraints.hasBoundedHeight
                        ? constraints.maxHeight
                        : width * page.viewBox.height / page.viewBox.width;
                final fitted =
                    applyBoxFit(
                      BoxFit.contain,
                      page.viewBox.size,
                      Size(width, height),
                    ).destination;
                QuranAyahReference? hit(Offset local) => page.ayahAt(
                  Offset(
                    page.viewBox.left +
                        local.dx * page.viewBox.width / fitted.width,
                    page.viewBox.top +
                        local.dy * page.viewBox.height / fitted.height,
                  ),
                );
                return Center(
                  child: SizedBox(
                    width: fitted.width,
                    height: fitted.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp:
                          widget.onAyahTap == null
                              ? null
                              : (details) {
                                final ref = hit(details.localPosition);
                                if (ref != null) widget.onAyahTap!(ref);
                              },
                      onLongPressStart:
                          !_hasLongPress
                              ? null
                              : (details) {
                                _pressed = hit(details.localPosition);
                                if (_pressed != null) {
                                  widget.onAyahLongPressStart?.call(
                                    _pressed!,
                                    details,
                                  );
                                  widget.onAyahLongPress?.call(_pressed!);
                                }
                              },
                      onLongPressEnd:
                          !_hasLongPress
                              ? null
                              : (_) {
                                if (_pressed != null) {
                                  widget.onAyahLongPressUp?.call(_pressed!);
                                }
                                _pressed = null;
                              },
                      onLongPressCancel:
                          !_hasLongPress
                              ? null
                              : () {
                                if (_pressed != null) {
                                  widget.onAyahLongPressCancel?.call(_pressed!);
                                }
                                _pressed = null;
                              },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _AyahHighlightPainter(
                                page,
                                widget.verseBackgroundColor ??
                                    widget.theme.verseBackgroundColor,
                              ),
                            ),
                          ),
                          _picture(context, loaded),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _LoadedWarshPage {
  final WarshPageData page;
  final PictureInfo? picture;
  const _LoadedWarshPage(this.page, this.picture);
}

class _WarshArtworkPainter extends CustomPainter {
  final PictureInfo picture;
  final ColorFilter? colorFilter;
  const _WarshArtworkPainter(this.picture, this.colorFilter);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / picture.size.width,
      size.height / picture.size.height,
    );
    if (colorFilter != null) {
      canvas.saveLayer(
        Offset.zero & picture.size,
        Paint()..colorFilter = colorFilter,
      );
    }
    canvas.drawPicture(picture.picture);
    if (colorFilter != null) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WarshArtworkPainter oldDelegate) =>
      oldDelegate.picture != picture || oldDelegate.colorFilter != colorFilter;
}

class _AyahHighlightPainter extends CustomPainter {
  final WarshPageData page;
  final Color? Function(int, int)? colorForAyah;
  _AyahHighlightPainter(this.page, this.colorForAyah);

  @override
  void paint(Canvas canvas, Size size) {
    if (colorForAyah == null) return;
    canvas.save();
    canvas.scale(
      size.width / page.viewBox.width,
      size.height / page.viewBox.height,
    );
    canvas.translate(-page.viewBox.left, -page.viewBox.top);
    for (final region in page.regions) {
      final color = colorForAyah!(
        region.reference.surahNumber,
        region.reference.verseNumber,
      );
      if (color != null) canvas.drawPath(region.path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AyahHighlightPainter oldDelegate) =>
      oldDelegate.page != page || oldDelegate.colorForAyah != colorForAyah;
}
