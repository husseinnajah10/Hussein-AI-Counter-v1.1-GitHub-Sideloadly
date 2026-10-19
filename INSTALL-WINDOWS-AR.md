# Hussein AI Counter — نسخة iOS الأصلية، الإصدار 1.1

هذه **ملفات المصدر الكاملة** لمشروع تطبيق iOS أصلي، وليست ملف IPA موقّعاً وجاهزاً للضغط عليه في Windows. جهزنا الملف للعمل وفق الخطوات: GitHub Actions على Mac سحابي ➜ ملف IPA غير موقّع ➜ Sideloadly في Windows يوقّعه بحساب Apple ➜ تثبيت على iPhone 15 Pro Max.

## ماذا تغير في النسخة الجديدة؟

- نفس أيقونة HN الزرقاء/الفضية التي تم اختيارها، ضمن `Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- شاشة ترحيب تستخدم صورة الأيقونة نفسها وحركة ظهور وتكبير خفيفة فقط، بدون مؤثرات إضافية.
- واجهة داخلية أهدأ بالأزرق الرمادي، **دون تغيير أي نص من نصوص التطبيق الأصلي**.
- التحكم في **ارتفاع نافذة الكاميرا** من 240 إلى 560 نقطة، مع حفظ اختيارك، وإمكانية عرض كامل الإطار أو ملئه.
- التحكم بالتقريب من 1× إلى أقصى ما تسمح به الكاميرا ضمن حد 5×، وتقريب سلس.
- تحسين إعدادات جودة التقاط الصور: أولوية جودة مرتفعة وحدّ أقصى للدقة وفق إمكانات الجهاز وصيغة التصوير المستخدمة؛ لا نضمن 48MP دائماً.
- تحسين استجابة واجهة معاينة الأشخاص بإعادة استعمال طبقات المستطيلات وتخفيف تكرار تحليل Vision، على حساب عدد مرات تحديث العد.
- استمرار العد المباشر، التقاط الصور، تحليل صور الألبوم، سجل النتائج، والتصدير، والخصوصية المحلية.
- الحقوق كما كانت: `Designed By Hussein Najah` و `© 2026 Hussein Najah. All Rights Reserved.`

## الخطوة الأولى — إعداد المشروع على GitHub بواسطة Windows

1. نزّل ملف المشروع ZIP وفك ضغطه باستخدام **Extract All** في Windows. لازم تكون في جذر المجلد ملفات/مجلدات:
   - `HusseinAICounter.xcodeproj`
   - `HusseinAICounter`
   - `.github/workflows/build-ipa.yml` (مجلد .github مخفي أحياناً؛ من مستكشف الملفات فعّل View > Show > Hidden items)
   - `INSTALL-WINDOWS-AR.md`.
2. نزّل **GitHub Desktop** من https://desktop.github.com/، وسجّل حساب GitHub مجاني.
3. اختر `File > Add local repository` وحدد **المجلد المفكوك** الذي يحتوي على ملف `.xcodeproj`، وليس ملف ZIP.
4. لو ظهرت رسالة أن المجلد ليس Git repository، اختر `Create a repository here`، ثم `Create repository`.
5. في GitHub Desktop اكتب وصف Commit مثل `Hussein AI Counter v1.1` واضغط `Commit to main`.
6. اضغط `Publish repository` وارفعه إلى GitHub. يمكن استخدام Repository عام لتوفير دقائق macOS حسب سياسة GitHub، أو خاص مع احتساب دقائق التشغيل من حصة حسابك؛ تأكد من سياسة حسابك قبل التشغيل.
7. من المتصفح افتح المستودع ثم تبويب `Actions`. إذا طُلب تفعيل Actions، فعّلها.
8. اختر **Build Hussein AI Counter IPA (unsigned)** ثم **Run workflow** (أحياناً يظهر هذا الزر فقط بعد رفع workflow إلى الفرع الرئيسي).
9. انتظر علامة نجاح خضراء. افتح نتيجة التشغيل، ثم قسم `Artifacts` وحمّل `HusseinAICounter-unsigned-IPA`.
10. فك ضغط Artifact ZIP لتحصل على الملف **`HusseinAICounter-unsigned.ipa`**. **لا تفك ملف IPA نفسه**.

إذا ظهرت علامة X حمراء، افتح مرحلة `Build iPhone app without signing` وانسخ رسالة الخطأ. **فشل البناء يعني أنه ليس لديك IPA صالح بعد**؛ أرسل السجل للمساعدة في الإصلاح.

## الخطوة الثانية — تثبيت التطبيق الحقيقي باستخدام Sideloadly

1. من Windows نزّل Sideloadly الرسمي من https://sideloadly.io/.
2. اتبع تعليماته لتثبيت نسخ iTunes وiCloud المتوافقة مع Windows عند الحاجة، وإعادة تشغيل الجهاز إذا طلب ذلك.
3. وصّل الآيفون باللابتوب باستخدام **كيبل بيانات** USB، وافتح قفل الهاتف واضغط `Trust / الوثوق` لو ظهر السؤال.
4. افتح Sideloadly. تأكد من ظهور جهازك بقائمة الأجهزة.
5. اسحب **`HusseinAICounter-unsigned.ipa`** إلى البرنامج وحدد Apple ID الاعتيادي الخاص بك. استخدم الأداة الرسمية فقط ولا تعطِ بيانات حسابك لأي شخص.
6. اضغط `Start` واتبع مطالبات Apple المتعلقة بتسجيل الدخول والتحقق الثنائي.
7. إذا ثُبّت التطبيق وظهرت رسالة `Untrusted Developer`: افتح على iPhone: `Settings > General > VPN & Device Management` ووثق حساب المطور المرتبط بالتوقيع.
8. إذا طلب iOS تفعيل `Developer Mode`: `Settings > Privacy & Security > Developer Mode`، وفعّله، ثم أعد التشغيل حسب التعليمات الظاهرة.
9. شغّل **Hussein AI Counter** من الشاشة الرئيسية، وامنحه إذن الكاميرا، وتحقق من التعداد ومعاينة الكاميرا.

## ملاحظات مهمة جداً

- مشروع iOS أصلي **وليس موقع ويب**، لكن الملف الحالي مصدر + workflow وليس IPA مبنياً. لا أملك في هذه المحادثة Mac/Xcode ولا حساب GitHub الخاص بك، لذلك لم أشغّل البناء السحابي ولم أختبر النسخة على آيفون فعلي. لا يمكن ضمان نجاح التثبيت قبل المرور بالخطوات والتجربة.
- Sideloadly وحساب Apple المجاني يوقّعان التطبيق غالباً **7 أيام**؛ بعدها يحتاج تجديد التوقيع من Windows، ويمكن استكشاف خاصية التجديد التلقائي في Sideloadly.
- جودة التصوير النهائية تعتمد على الضوء، نوع العدسة، صيغة الصور وصلاحيات iOS، ولا يمكن ضمان دقة عد الأشخاص المحجوبين، أو الظاهرين جزئياً، أو خارج المشهد.
- `IPA` غير موقّع داخل GitHub Actions **ليس بحد ذاته قابل للتنصيب مباشرة**؛ يجب توقيعه باستخدام Sideloadly.
- من أجل الخصوصية: التطبيق لا يرفع الصور إلى خادم؛ التحليل باستخدام Vision على الجهاز. إذا أردت إبقاء كود المشروع خاصاً، اختَر Repository خاصاً وتحقق من دقائق GitHub Actions المتاحة.
- لا تُدخل كلمة مرور Apple ID أو رموز التحقق في ملفات المشروع أو GitHub.

## روابط المصدر الرسمي

- GitHub Desktop: https://desktop.github.com/
- GitHub Actions/macOS: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- تنزيل Artifact من GitHub: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts
- Sideloadly: https://sideloadly.io/
- Sideloadly FAQ: https://sideloadly.io/faq
