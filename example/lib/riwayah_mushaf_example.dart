import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran/qcf_quran.dart';

/// Demonstrates the existing Hafs package's two mushafs and online audio URLs.
/// An audio player can consume the returned URLs; this example fetches no MP3s.
class RiwayahMushafExample extends StatefulWidget {
  const RiwayahMushafExample({super.key, this.audioApiFactory});

  /// Optional factory for an app-specific catalog client or an offline test.
  /// Each created provider belongs to its ayah sheet and is closed with it.
  final Mp3QuranApi Function()? audioApiFactory;

  @override
  State<RiwayahMushafExample> createState() => _RiwayahMushafExampleState();
}

class _RiwayahMushafExampleState extends State<RiwayahMushafExample> {
  QuranRiwayah _riwayah = QuranRiwayah.hafs;
  PageController _pages = PageController();
  final TextEditingController _pageInput = TextEditingController(text: '1');
  Future<WarshMushaf>? _warshLoad;
  QuranAyahReference? _selectedAyah;
  int _pageNumber = 1;

  @override
  void dispose() {
    _pages.dispose();
    _pageInput.dispose();
    super.dispose();
  }

  void _selectRiwayah(QuranRiwayah riwayah) {
    if (riwayah == _riwayah) return;
    final oldController = _pages;
    setState(() {
      _riwayah = riwayah;
      _pages = PageController();
      _pageNumber = 1;
      _pageInput.text = '1';
      _selectedAyah = null;
      if (riwayah == QuranRiwayah.warsh) {
        _warshLoad ??= WarshMushaf.load();
      }
    });
    // The previous PageView detaches during this frame's rebuild.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => oldController.dispose(),
    );
  }

  void _jumpToPage() {
    final page = int.tryParse(_pageInput.text.trim());
    if (page == null || page < 1 || page > totalPagesCount) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أدخل رقم صفحة بين 1 و604')));
      return;
    }
    if (_pages.hasClients) {
      _pages.jumpToPage(page - 1);
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _openAyah(
    QuranAyahReference reference, {
    WarshMushaf? warshMushaf,
  }) async {
    setState(() => _selectedAyah = reference);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => _AyahActionsSheet(
            reference: reference,
            warshMushaf: warshMushaf,
            audioApiFactory: widget.audioApiFactory,
          ),
    );
    if (mounted) setState(() => _selectedAyah = null);
  }

  Widget _mushaf({WarshMushaf? warshMushaf}) => PageviewQuran(
    key: ValueKey(_riwayah),
    riwayah: _riwayah,
    warshMushaf: warshMushaf,
    controller: _pages,
    initialPageNumber: 1,
    windowSize: 1,
    onPageChanged: (page) {
      setState(() {
        _pageNumber = page;
        _pageInput.text = '$page';
      });
    },
    verseBackgroundColor:
        (surah, verse) =>
            _selectedAyah?.surahNumber == surah &&
                    _selectedAyah?.verseNumber == verse
                ? const Color(0x35ffca28)
                : null,
    onAyahTap: (reference) => _openAyah(reference, warshMushaf: warshMushaf),
  );

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مصحف حفص وورش')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<QuranRiwayah>(
                segments: const [
                  ButtonSegment(value: QuranRiwayah.hafs, label: Text('حفص')),
                  ButtonSegment(value: QuranRiwayah.warsh, label: Text('ورش')),
                ],
                selected: {_riwayah},
                onSelectionChanged: (values) => _selectRiwayah(values.single),
              ),
            ),
            const Text('انقر على الآية لعرض نصها وروابط تلاوتها'),
            Expanded(
              child:
                  _riwayah == QuranRiwayah.hafs
                      ? _mushaf()
                      : FutureBuilder<WarshMushaf>(
                        future: _warshLoad,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('تعذر فتح بيانات مصحف ورش'),
                                  TextButton(
                                    onPressed:
                                        () => setState(
                                          () => _warshLoad = WarshMushaf.load(),
                                        ),
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return _mushaf(warshMushaf: snapshot.requireData);
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(child: Text('الصفحة $_pageNumber من 604')),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      key: const ValueKey('mushaf-page-input'),
                      controller: _pageInput,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'الصفحة',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _jumpToPage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'انتقل إلى الصفحة',
                    onPressed: _jumpToPage,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AyahActionsSheet extends StatefulWidget {
  const _AyahActionsSheet({
    required this.reference,
    required this.warshMushaf,
    this.audioApiFactory,
  });

  final QuranAyahReference reference;
  final WarshMushaf? warshMushaf;
  final Mp3QuranApi Function()? audioApiFactory;

  @override
  State<_AyahActionsSheet> createState() => _AyahActionsSheetState();
}

class _AyahActionsSheetState extends State<_AyahActionsSheet> {
  late final Mp3QuranApi _api;
  late EveryAyahReciter _ayahReciter;
  List<EveryAyahAudioSegment> _ayahSegments = [];
  List<_SurahRecordingChoice> _surahChoices = [];
  _SurahRecordingChoice? _surahChoice;
  String? _ayahError;
  String? _catalogError;
  bool _loadingReaders = false;

  @override
  void initState() {
    super.initState();
    _api = widget.audioApiFactory?.call() ?? Mp3QuranApi();
    _ayahReciter =
        widget.reference.riwayah == QuranRiwayah.hafs
            ? EveryAyahReciters.hafsAlafasy
            : EveryAyahReciters.warshAbdulBasit;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  void _resolveAyah() {
    try {
      final segments = EveryAyahProvider().resolveAyah(
        widget.reference,
        reciter: _ayahReciter,
      );
      setState(() {
        _ayahSegments = segments;
        _ayahError = null;
      });
    } on EveryAyahMappingRequiredException {
      setState(() {
        _ayahSegments = [];
        _ayahError =
            'ترقيم مقاطع هذا المصدر يحتاج ربطًا موثقًا بهذه الآية. '
            'يمكنك استخدام تلاوة السورة كاملة أدناه.';
      });
    } catch (_) {
      setState(() {
        _ayahSegments = [];
        _ayahError = 'تعذر تجهيز رابط تلاوة الآية.';
      });
    }
  }

  Future<void> _fetchReaders() async {
    setState(() {
      _loadingReaders = true;
      _catalogError = null;
    });
    try {
      final readers = await _api.getReciters(
        riwayahId: widget.reference.riwayah == QuranRiwayah.hafs ? 1 : 2,
        surahNumber: widget.reference.surahNumber,
      );
      final choices = [
        for (final reader in readers)
          for (final collection in reader.moshafs)
            _SurahRecordingChoice(reader.name, collection),
      ];
      if (!mounted) return;
      setState(() {
        _loadingReaders = false;
        _surahChoices = choices;
        _surahChoice = choices.isEmpty ? null : choices.first;
        if (choices.isEmpty) _catalogError = 'لا توجد تلاوة متاحة لهذه السورة.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingReaders = false;
        _catalogError = 'تعذر جلب القراء. تحقق من الاتصال ثم أعد المحاولة.';
      });
    }
  }

  Future<void> _copyUri(Uri uri) async {
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ رابط التلاوة')));
  }

  Widget _uriCard(Uri uri) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              uri.toString(),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'نسخ رابط التلاوة',
            onPressed: () => _copyUri(uri),
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reference = widget.reference;
    final isWarsh = reference.riwayah == QuranRiwayah.warsh;
    final text =
        isWarsh
            ? widget.warshMushaf!
                .getVerse(reference.surahNumber, reference.verseNumber)
                .text
            : getVerse(reference.surahNumber, reference.verseNumber);
    final readers = EveryAyahReciters.forRiwayah(reference.riwayah);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isWarsh ? 'ورش' : 'حفص'} · '
                  '${getSurahNameArabic(reference.surahNumber)} · '
                  'الآية ${reference.verseNumber}',
                  key: const ValueKey('selected-ayah-reference'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  text,
                  key: const ValueKey('selected-ayah-text'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.8,
                    fontFamily:
                        isWarsh
                            ? widget.warshMushaf!.fontFamily
                            : HafsText.fontFamily,
                    package: 'qcf_quran',
                  ),
                ),
                const Divider(height: 28),
                Text(
                  'تلاوة الآية — EveryAyah',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                DropdownButton<EveryAyahReciter>(
                  isExpanded: true,
                  value: _ayahReciter,
                  items: [
                    for (final reader in readers)
                      DropdownMenuItem(value: reader, child: Text(reader.name)),
                  ],
                  onChanged: (reader) {
                    if (reader == null) return;
                    setState(() {
                      _ayahReciter = reader;
                      _ayahSegments = [];
                      _ayahError = null;
                    });
                  },
                ),
                FilledButton.icon(
                  onPressed: _resolveAyah,
                  icon: const Icon(Icons.link),
                  label: const Text('رابط تلاوة الآية'),
                ),
                if (_ayahError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_ayahError!),
                  ),
                for (final segment in _ayahSegments) _uriCard(segment.uri),
                const Divider(height: 28),
                Text(
                  'تلاوة السورة — MP3Quran',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _loadingReaders ? null : _fetchReaders,
                  icon:
                      _loadingReaders
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.people_outline),
                  label: const Text('جلب القراء للسورة'),
                ),
                if (_catalogError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_catalogError!),
                  ),
                if (_surahChoices.isNotEmpty) ...[
                  DropdownButton<_SurahRecordingChoice>(
                    isExpanded: true,
                    value: _surahChoice,
                    items: [
                      for (final choice in _surahChoices)
                        DropdownMenuItem(
                          value: choice,
                          child: Text(
                            '${choice.readerName} · ${choice.collection.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged:
                        (choice) => setState(() => _surahChoice = choice),
                  ),
                  if (_surahChoice != null)
                    _uriCard(
                      _surahChoice!.collection.surahUri(reference.surahNumber),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahRecordingChoice {
  const _SurahRecordingChoice(this.readerName, this.collection);

  final String readerName;
  final Mp3QuranMoshaf collection;
}
