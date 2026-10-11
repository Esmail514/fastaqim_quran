# الانتقال إلى mushaf_riwayat

أصبح اسم الباكج `mushaf_riwayat` ومجلده `custom_packages/mushaf_riwayat`.
نُقل سجل Git المحلي مع المجلد. هذه النسخة محلية ولم تُنشر على pub.dev بعد.

في `pubspec.yaml` لتطبيق بجانب مجلد `custom_packages`:

```yaml
dependencies:
  mushaf_riwayat:
    path: ../custom_packages/mushaf_riwayat
```

حدّث الاستيرادات إلى:

```dart
import 'package:mushaf_riwayat/mushaf_riwayat.dart';
```

عند استخدام خط أو صورة من الباكج مباشرةً، استخدم
`package: 'mushaf_riwayat'` في `TextStyle` و`AssetImage`، أو
`packageName: 'mushaf_riwayat'` في `SvgAssetLoader`. المفاتيح المباشرة تبدأ
بـ`packages/mushaf_riwayat/`؛ مثل `packages/mushaf_riwayat/QCF_HafsUnicode`.
بقيت عائلات خطوط QCF وأسماء الواجهات مثل `QcfPage` و`QcfVerse` كما هي.

نفّذ `flutter pub get` في الباكج والمثال والتطبيق المستهلك، ثم أعد تشغيل
التطبيق بالكامل؛ إعادة التحميل الساخن وحدها لا تعيد تسجيل خطوط الباكج.
ملف البيانات الداخلي انتقل إلى `lib/src/data/mushaf_riwayat.dart`؛ يفضّل
استخدام نقطة الاستيراد العامة في التطبيقات.

لا يتطلب النقل تغيير النص القرآني أو أرقام الآيات أو إعدادات المستخدم
أو قواعد بيانات المحفوظات. تبقى حقوق المؤلف الأصلي وروابطه في الترخيص
والتوثيق، فهي توثّق أصل المشروع ولا تحدد اسم الباكج الحالي.
