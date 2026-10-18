# الانتقال من mushaf_riwayat إلى fastaqim_quran

الاسم الجديد هو **`fastaqim_quran`**، ومجلد النسخة المحلية
`custom_packages/fastaqim_quran`. هذه إعادة تسمية للحزمة؛ تبقى الواجهات
العامة مثل `QcfPage` و`QcfVerse` و`PageviewQuran` وعائلات خطوط QCF كما هي.
بيانات نشر الاسم السابق محفوظة في [سجل النشر](../doc/PUBLISHED_RELEASE.md).

## 1. تغيير الاعتماد

احذف اعتماد `mushaf_riwayat` من `pubspec.yaml` وأضف الإصدار المستضاف
بالاسم الجديد:

```yaml
dependencies:
  fastaqim_quran: ^0.1.0
```

لتطبيق بجانب مجلد `custom_packages` عند استخدام المصدر المحلي:

```yaml
dependencies:
  fastaqim_quran:
    path: ../custom_packages/fastaqim_quran
```

تحقق من إزالة أي `dependency_overrides` ما زالت تشير إلى الاسم أو المسار القديم.

## 2. تغيير الاستيرادات

استبدل:

```dart
import 'package:mushaf_riwayat/mushaf_riwayat.dart';
```

بـ:

```dart
import 'package:fastaqim_quran/fastaqim_quran.dart';
```

استخدم نقطة الاستيراد العامة بدل الاعتماد على ملفات `lib/src/` الداخلية.

## 3. تغيير مفاتيح الخطوط والأصول

| الموضع | السابق | الجديد |
| --- | --- | --- |
| `TextStyle` و`AssetImage` | `package: 'mushaf_riwayat'` | `package: 'fastaqim_quran'` |
| `SvgAssetLoader` | `packageName: 'mushaf_riwayat'` | `packageName: 'fastaqim_quran'` |
| عائلة خط مؤهلة أو مفتاح أصل | `packages/mushaf_riwayat/…` | `packages/fastaqim_quran/…` |

مثلًا: تصبح عائلة الخط المؤهلة `packages/fastaqim_quran/QCF_HafsUnicode`.
لا تغيّر أسماء عائلات الخطوط نفسها أو محتوى ملفاتها.

## 4. إعادة المزامنة والتشغيل

نفّذ `flutter pub get` في الباكج والمثال والتطبيق المستهلك، ثم أعد تشغيل
التطبيق بالكامل؛ إعادة التحميل الساخن وحدها لا تعيد تسجيل خطوط الباكج.
تحقق من تسجيل `fastaqim_quran` في `pubspec.lock` و`.dart_tool/package_config.json`،
ثم شغّل التحليل واختبارات تطبيقك وتحقق من عرض حفص وورش وتحميل الأصول.

لا يتطلب النقل تغيير النص القرآني أو أرقام الآيات أو معرّف تطبيق Android
أو إعدادات المستخدم أو قواعد بيانات المحفوظات. تبقى حقوق المؤلف الأصلي
وتراخيص المكونات وروابط المصادر محفوظة.
