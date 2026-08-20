import '../localization/locale_service.dart';

/// جميع نصوص التطبيق — ثنائية اللغة (عربي/إنجليزي) حسب [LocaleService].
class AppStrings {
  static LocaleService get _l => LocaleService.instance;

  // App
  static String get appName => _l.t('نداء', en: 'Nidaa');
  static String get appTagline => _l.t('لأجلي ولأجل السلامة', en: 'For me and for safety');

  // Auth
  static String get phoneNumber => _l.t('رقم الهاتف', en: 'Phone number');
  static String get phoneHint => _l.t('09.....', en: '09.....');
  static String get continueBtn => _l.t('متابعة', en: 'Continue');
  static String get termsNote => _l.t(
      'بالنقر على متابعة، أنت توافق على شروط الاستخدام المخصصة للطوارئ.',
      en: 'By tapping continue, you agree to the emergency use terms.');
  static String get loginSubtitle => _l.t(
      'أدخل رقم هاتفك للوصول السريع لخدمات الطوارئ.',
      en: 'Enter your phone number for quick access to emergency services.');

  // OTP
  static String get otpTitle => _l.t('رمز التحقق', en: 'Verification code');
  static String get otpSubtitle => _l.t(
      'الرجاء إدخال الرمز المكون من 6 أرقام الذي تم إرساله إلى رقم هاتفك.',
      en: 'Enter the 6-digit code sent to your phone number.');
  static String get verifyBtn => _l.t('التحقق', en: 'Verify');
  static String get noCode => _l.t('لم تستلم الرمز؟', en: "Didn't receive the code?");
  static String get resend => _l.t('إعادة الإرسال', en: 'Resend');
  static String get welcomeNameTitle => _l.t('مرحباً بك في نداء', en: 'Welcome to Nidaa');
  static String get welcomeNameBody => _l.t(
      'أدخل اسمك ليظهر في البلاغات وجهات الاستجابة — يمكنك تخطي هذه الخطوة الآن.',
      en: 'Enter your name to show on reports and responders — you can skip this for now.');
  static String get skip => _l.t('تخطي', en: 'Skip');

  // Auth — كلمة المرور (متطلب 4.1)
  static String get loginTab => _l.t('تسجيل الدخول', en: 'Sign in');
  static String get registerTab => _l.t('حساب جديد', en: 'New account');
  static String get username => _l.t('اسم المستخدم', en: 'Username');
  static String get emailOrPhone => _l.t(
      'البريد الإلكتروني أو رقم الهاتف', en: 'Email or phone number');
  static String get password => _l.t('كلمة المرور', en: 'Password');
  static String get confirmPassword =>
      _l.t('تأكيد كلمة المرور', en: 'Confirm password');
  static String get forgotPassword =>
      _l.t('نسيت كلمة المرور؟', en: 'Forgot password?');
  static String get loginBtn => _l.t('دخول', en: 'Sign in');
  static String get registerBtn => _l.t('إنشاء الحساب', en: 'Create account');
  static String get registerSubtitle => _l.t(
      'أنشئ حسابك باسم مستخدم وجوال وكلمة مرور — بياناتك تُشفّر ولا تُشارك.',
      en: 'Create your account with a username, phone and password — your data is encrypted.');
  static String get loginSubtitle2 => _l.t(
      'ادخل باستخدام بريدك الإلكتروني أو رقم هاتفك وكلمة المرور.',
      en: 'Sign in with your email, phone number and password.');
  static String get registrationSuccess => _l.t(
      'تم إنشاء الحساب — سجّل دخولك الآن',
      en: 'Account created — sign in now');
  static String get passwordResetTitle =>
      _l.t('استعادة كلمة المرور', en: 'Reset password');
  static String get passwordResetSubtitle => _l.t(
      'أدخل رقم هاتفك وسنرسل رمز تحقق لإعادة تعيين كلمة المرور.',
      en: 'Enter your phone number and we will send a code to reset your password.');
  static String get newPassword => _l.t('كلمة المرور الجديدة', en: 'New password');
  static String get resetBtn => _l.t('تعيين كلمة المرور', en: 'Reset password');
  static String get passwordResetSuccess => _l.t(
      'تم تغيير كلمة المرور — سجّل دخولك الآن',
      en: 'Password changed — sign in now');
  static String get twoFactorTitle =>
      _l.t('التحقق من الهوية', en: 'Identity verification');
  static String get twoFactorSubtitle => _l.t(
      'أدخل رمز التحقق المرسل إلى هاتفك لتأكيد هويتك.',
      en: 'Enter the code sent to your phone to confirm your identity.');

  // Home
  static String get helpButton => _l.t('مساعدة', en: 'HELP');
  static String get holdToHelp => _l.t('اضغط مطولاً لطلب المساعدة الفورية',
      en: 'Hold to request immediate help');
  static String get tapOrHoldToHelp => _l.t(
      'ضغطة واحدة للاستغاثة الفورية — أو اضغط مطولاً لتقديم بلاغ كامل',
      en: 'One tap to send an SOS — or press and hold for a full report');
  static String get latestReports => _l.t('آخر البلاغات', en: 'Latest reports');
  static String get viewAll => _l.t('عرض الكل', en: 'View all');
  static String get safetyTipTitle => _l.t('نصيحة أمان', en: 'Safety tip');
  static String get safetyTipBody => _l.t(
      'تأكد من تفعيل خدمة تحديد الموقع (GPS) لضمان سرعة وصول المساعدة في حالات الطوارئ.',
      en: 'Make sure location (GPS) is enabled so help can reach you faster in emergencies.');

  // SOS
  static String get sosTitle => _l.t('إرسال الاستغاثة', en: 'Send SOS');
  static String get sosSubtitle => _l.t(
      'سيتم إرسال موقعك الحالي إلى الجهات المختصة وجهات اتصالك',
      en: 'Your current location will be sent to authorities and your emergency contacts.');
  static String get gettingLocation => _l.t('جاري تحديد موقعك...', en: 'Getting your location...');
  static String get locationReady => _l.t('تم تحديد موقعك', en: 'Location ready');
  static String get sendingSos => _l.t('جاري إرسال الاستغاثة...', en: 'Sending SOS...');
  static String get sosSentTitle => _l.t('تم إرسال الاستغاثة', en: 'SOS sent');
  static String get sosSentBody => _l.t('تم إشعار الجهات المختصة وجهات الاتصال',
      en: 'Authorities and your contacts have been notified');
  static String get sosNoLocation => _l.t('تعذر تحديد موقعك — لم يتم إرسال الاستغاثة',
      en: 'Could not get your location — SOS was not sent');
  static String get enableLocationTitle => _l.t('خدمة الموقع معطلة', en: 'Location service is off');
  static String get enableLocationBody => _l.t(
      'فعّل خدمة تحديد الموقع (GPS) لضمان وصول موقعك أثناء الاستغاثة',
      en: 'Enable GPS to share your location during an SOS');
  static String get enableNow => _l.t('تفعيل الآن', en: 'Enable now');
  static String get locationPermissionTitle => _l.t('صلاحية الموقع مطلوبة', en: 'Location permission needed');
  static String get locationPermissionBody => _l.t(
      'اسمح بالوصول إلى الموقع لتتمكن من إرسال الاستغاثة',
      en: 'Allow location access so you can send an SOS');

  // Reports
  static String get allReports => _l.t('الكل', en: 'All');
  static String get processing => _l.t('قيد المعالجة', en: 'Processing');
  static String get closed => _l.t('مغلق', en: 'Closed');
  static String get urgent => _l.t('طارئ', en: 'Urgent');
  static String get now => _l.t('الآن', en: 'Now');
  static String get twoHoursAgo => _l.t('منذ ساعتين', en: '2 hours ago');
  static String get yesterday => _l.t('أمس', en: 'Yesterday');
  static String get relevantAuthorities => _l.t('الجهات المختصة في الطريق',
      en: 'Response teams on the way');

  // Report Category — الأنواع السبعة المطلوبة (4.2)
  static String get categoryTitle => _l.t('عن ماذا تود التبليغ؟', en: 'What do you want to report?');
  static String get categorySubtitle => _l.t(
      'الرجاء اختيار الفئة المناسبة لضمان سرعة الاستجابة.',
      en: 'Choose the right category for a faster response.');
  static String get catAmbulance => _l.t('إسعاف', en: 'Ambulance');
  static String get catFire => _l.t('حريق', en: 'Fire');
  static String get catPolice => _l.t('شرطة', en: 'Police');
  static String get catRescue => _l.t('إنقاذ', en: 'Rescue');
  static String get catNaturalDisaster => _l.t('كارثة طبيعية', en: 'Natural disaster');
  static String get catBuildingCollapse => _l.t('انهيار مبنى', en: 'Building collapse');
  static String get catRoadClosure => _l.t('ازدحام أو إغلاق طرق', en: 'Congestion / Road closure');

  // Report Details
  static String get severityLevel => _l.t('مستوى الخطورة', en: 'Severity level');
  static String get severityCritical => _l.t('حرج', en: 'Critical');
  static String get severityHigh => _l.t('مرتفع', en: 'High');
  static String get severityMedium => _l.t('متوسط', en: 'Medium');
  static String get severityLow => _l.t('منخفض', en: 'Low');
  static String get reportDetails => _l.t('تفاصيل البلاغ', en: 'Report details');
  static String get descriptionHint => _l.t('الرجاء وصف الحالة بدقة...', en: 'Describe the situation accurately...');
  static String get attachments => _l.t('المرفقات', en: 'Attachments');
  static String get attachImage => _l.t('إرفاق صورة', en: 'Attach image');
  static String get submitReport => _l.t('رفع التقرير', en: 'Submit report');
  static String get reportSent => _l.t('تم إرسال بلاغك بنجاح', en: 'Report sent successfully');
  static String get reportSendFailed => _l.t('تعذر الإرسال', en: 'Send failed');
  static String get liveUpdate => _l.t('تحديث فوري', en: 'Live update');
  static String get reportClosed => _l.t('تم إغلاق البلاغ: {title}', en: 'Report closed: {title}');
  static String get gallery => _l.t('المعرض', en: 'Gallery');
  static String get camera => _l.t('الكاميرا', en: 'Camera');
  static String get validationTitle => _l.t('حقل مطلوب', en: 'Required field');
  static String get requiredDescription => _l.t('يرجى كتابة وصف الحالة قبل الإرسال',
      en: 'Please write a description before sending');

  // Victims (4.2)
  static String get victimsCount => _l.t('عدد المصابين / المتضررين (تقريباً)',
      en: 'Number of injured / affected (approx.)');
  static String get victimsHint => _l.t('اختياري', en: 'Optional');
  static String get victimsUnknown => _l.t('غير محدد', en: 'Unknown');
  static String get peopleCount => _l.t('{n} أشخاص', en: '{n} people');

  // Voice report (4.3)
  static String get voiceReport => _l.t('بلاغ صوتي', en: 'Voice report');
  static String get micHint => _l.t('اضغط لتسجيل وصف صوتي', en: 'Tap to record a voice description');
  static String get voiceHint => _l.t(
      'سجّل وصفاً صوتياً وسيُحول تلقائياً إلى نص للمراجعة قبل الإرسال',
      en: 'Record a voice description — it will be transcribed for review before sending');
  static String get recording => _l.t('جاري التسجيل...', en: 'Recording...');
  static String get stopRecording => _l.t('إيقاف', en: 'Stop');
  static String get transcribing => _l.t('جاري تحويل الصوت إلى نص...', en: 'Transcribing audio...');
  static String get transcriptionFailed => _l.t(
      'تعذر تحويل الصوت — يمكنك كتابة الوصف يدوياً وسيُرسل الملف الصوتي مع البلاغ.',
      en: 'Could not transcribe — you can type the description manually; the audio will be attached.');
  static String get audioAttached => _l.t('ملف صوتي مرفق', en: 'Audio attached');
  static String get recordedAudio => _l.t('تسجيل صوتي', en: 'Voice recording');
  static String get removeAudio => _l.t('إزالة التسجيل', en: 'Remove recording');

  // Report tracking (4.4)
  static String get trackingTitle => _l.t('تتبع البلاغ', en: 'Report tracking');
  static String get liveMap => _l.t('الخريطة الحية', en: 'Live map');
  static String get stageAssessing => _l.t('جاري تقييم البلاغ', en: 'Assessing the report');
  static String get stageClosed => _l.t('تم إغلاق البلاغ', en: 'Report closed');
  static String get autoUpdateNote => _l.t('يتم تحديث الحالة تلقائياً عند تغيّرها',
      en: 'Status updates automatically when it changes');
  static String get locationNotAvailable => _l.t('الموقع الجغرافي غير متوفر لهذا البلاغ',
      en: 'Location is not available for this report');
  static String get respondingAgency => _l.t('الجهة المستجيبة', en: 'Responding agency');
  static String get etaMinutes => _l.t('الزمن المتوقع لوصول فرق الإنقاذ',
      en: 'Estimated arrival time of rescue teams');
  static String get etaInMinutes => _l.t('خلال ~{m} دقيقة', en: 'In ~{m} min');
  static String get etaSoon => _l.t('وصلت الفرق إلى الموقع', en: 'Teams arrived on site');
  static String get credibility => _l.t('مصداقية البلاغ', en: 'Report credibility');
  static String get noAgencyYet => _l.t('بانتظار تخصيص جهة استجابة',
      en: 'Awaiting assignment of a response team');
  static String get witnessBadge => _l.t('بلاغ شاهد', en: 'Witness report');

  // Alerts (4.5)
  static String get alertsTitle => _l.t('التنبيهات', en: 'Alerts');
  static String get alertsSubtitle => _l.t(
      'تحذيرات وتحليلات فورية من الجهات المختصة — تُحدَّث تلقائياً.',
      en: 'Immediate warnings and notices from authorities — updated automatically.');
  static String get noAlerts => _l.t('لا توجد تنبيهات حالياً', en: 'No alerts right now');
  static String get newAlert => _l.t('تنبيه جديد', en: 'New alert');
  static String get minutesAgo => _l.t('منذ {n} دقيقة', en: '{n} min ago');
  static String get hoursAgo => _l.t('منذ {n} ساعة', en: '{n} h ago');
  static String get daysAgo => _l.t('منذ {n} يوم', en: '{n} d ago');

  // Map (4.6)
  static String get dangerZone => _l.t('منطقة خطر', en: 'Danger zone');
  static String get hospital => _l.t('مشفى', en: 'Hospital');
  static String get shelters => _l.t('مراكز الإيواء', en: 'Shelters');
  static String get safePoints => _l.t('نقاط التجمع الآمنة', en: 'Safe gathering points');
  static String get shelter => _l.t('مركز إيواء', en: 'Shelter');
  static String get safePoint => _l.t('نقطة تجمع آمنة', en: 'Safe point');
  static String get capacity => _l.t('السعة', en: 'Capacity');
  static String get directions => _l.t('المسار', en: 'Directions');
  static String get directionsToHospital => _l.t('المسار إلى أقرب مشفى ({name})',
      en: 'Directions to nearest hospital ({name})');
  static String get directionsToHospitalShort => _l.t('المسار إلى المشفى', en: 'Directions to hospital');
  static String get directionsToCenter => _l.t('المسار إلى المركز', en: 'Directions to center');
  static String get directionsToShelter => _l.t('المسار إلى مركز الإيواء', en: 'Directions to shelter');
  static String get directionsToSafePoint => _l.t('المسار إلى نقطة التجمع', en: 'Directions to safe point');
  static String get myLocation => _l.t('موقعي الحالي', en: 'My location');
  static String get retry => _l.t('إعادة المحاولة', en: 'Retry');
  static String get mapLocationMissing => _l.t('تعذر تحديد موقعك', en: 'Could not get your location');
  static String get mapLocationHint => _l.t('فعّل خدمة تحديد الموقع ثم أعد المحاولة',
      en: 'Enable location services and try again');

  // Witness mode (4.8)
  static String get witnessMode => _l.t('أنا شاهد', en: 'I am a witness');
  static String get witnessModeSubtitle => _l.t(
      'أبلغ كشاهد عن حادث رصدته — سيتم إرسال موقعك فوراً بضغطة واحدة.',
      en: 'Report an incident as a witness — your location will be sent in one tap.');
  static String get sendWitness => _l.t('إرسال بلاغ الشاهد', en: 'Send witness report');
  static String get witnessSent => _l.t('تم إرسال بلاغ الشاهد', en: 'Witness report sent');
  static String get sendNow => _l.t('إرسال الآن', en: 'Send now');
  static String get witnessAddPhoto => _l.t('إضافة صورة من الموقع', en: 'Add a photo from the scene');
  static String get witness => _l.t('شاهد', en: 'Witness');
  static String get witnessReport => _l.t('أنا شاهد — إبلاغ سريع',
      en: 'I am a witness — quick report');
  static String get witnessPhotoHint => _l.t('أضف صورة من الموقع (اختياري)',
      en: 'Add a photo from the scene (optional)');

  // Medical card (4.7)
  static String get medicalCard => _l.t('البطاقة الطبية الطارئة', en: 'Emergency medical card');
  static String get medicalCardHint => _l.t(
      'معلومات اختيارية تظهر للمشغّل والمسعف فقط عند تفعيل بلاغ طبي.',
      en: 'Optional info visible to operators and medics only when a medical report is active.');
  static String get bloodType => _l.t('فصيلة الدم', en: 'Blood type');
  static String get allergies => _l.t('الحساسيات (الدوائية والغذائية)', en: 'Allergies (drugs & food)');
  static String get chronicDiseases => _l.t('الأمراض المزمنة', en: 'Chronic diseases');
  static String get medications => _l.t('الأدوية الدائمة', en: 'Regular medications');
  static String get medicalContactName => _l.t('اسم جهة الاتصال الطارئة', en: 'Emergency contact name');
  static String get medicalContactPhone => _l.t('هاتف جهة الاتصال الطارئة', en: 'Emergency contact phone');
  static String get emergencyContactName => medicalContactName;
  static String get emergencyContactPhone => medicalContactPhone;
  static String get save => _l.t('حفظ', en: 'Save');
  static String get medicalCardSaved => _l.t('تم حفظ البطاقة الطبية', en: 'Medical card saved');
  static String get noMedicalCard => _l.t('لا توجد بطاقة طبية بعد', en: 'No medical card yet');
  static String get addMedicalCard => _l.t('إضافة بطاقة طبية', en: 'Add medical card');
  static String get listSeparatorHint => _l.t('افصل بين العناصر بفاصلة', en: 'Separate items with commas');

  // Offline (4.9)
  static String get offlineMode => _l.t('وضع الطوارئ — بدون اتصال', en: 'Emergency mode — offline');
  static String get offlineModeBody => _l.t(
      'سيتم حفظ بلاغاتك محلياً وإرسالها تلقائياً عند عودة الاتصال.',
      en: 'Your reports are saved locally and will be sent automatically when connection returns.');
  static String get pendingSync => _l.t('بلاغات بانتظار الإرسال: {count}',
      en: 'Reports pending sync: {count}');
  static String get syncedNow => _l.t('تمت مزامنة البلاغات المحفوظة', en: 'Saved reports synced');

  // Map offline download (4.9)
  static String get mapDownload => _l.t('تحميل خريطة منطقتي', en: 'Download my area map');
  static String get mapDownloadHint => _l.t(
      'حمّل الخريطة مسبقاً للعمل دون إنترنت أثناء الطوارئ (حتى 300MB).',
      en: 'Pre-download the map for offline use in emergencies (up to 300MB).');
  static String get mapDownloadStart => _l.t('ابدأ التحميل', en: 'Start download');
  static String get mapDownloadCancel => _l.t('إيقاف', en: 'Stop');
  static String get mapDownloadNeedLocation => _l.t(
      'حدّد موقعك أولاً من شاشة الخريطة ثم أعد المحاولة',
      en: 'Get your location from the map screen first, then retry');
  static String get mapDownloadProgress => _l.t('التحميل: {percent}%', en: 'Downloading: {percent}%');
  static String get mapCacheSize => _l.t('الخريطة المخزنة: {size}MB', en: 'Cached map: {size}MB');
  static String get mapNoCache => _l.t('لا توجد خريطة مخزنة بعد', en: 'No cached map yet');

  // Profile
  static String get profile => _l.t('حسابي', en: 'My account');
  static String get emergencyContacts => _l.t('جهات اتصال الطوارئ المفضلة', en: 'Favorite emergency contacts');
  static String get contactsNote => _l.t('سيتم إعلامهم تلقائياً عند طلب المساعدة',
      en: 'They will be notified automatically when you ask for help');
  static String get addContact => _l.t('إضافة جهة اتصال', en: 'Add contact');
  static String get noContacts => _l.t('لا توجد جهات اتصال طوارئ بعد', en: 'No emergency contacts yet');
  static String get noContactsHint => _l.t(
      'أضف جهة اتصالك الأولى وسيتم إشعارها عند طلب المساعدة',
      en: 'Add your first contact and they will be notified when you ask for help');
  static String get publicEmergency => _l.t('أرقام الطوارئ العامة', en: 'Public emergency numbers');
  static String get police => _l.t('الشرطة', en: 'Police');
  static String get ambulance => _l.t('الإسعاف', en: 'Ambulance');
  static String get firefighters => _l.t('الإطفاء', en: 'Firefighters');
  static String get logout => _l.t('تسجيل الخروج', en: 'Log out');
  static String get language => _l.t('اللغة', en: 'Language');
  static String get arabic => _l.t('العربية', en: 'Arabic');
  static String get english => _l.t('English', en: 'English');

  // Accessibility (7.4)
  static String get accessibility => _l.t('الإتاحة', en: 'Accessibility');
  static String get accessibilityHint => _l.t(
      'خيارات لذوي الاحتياجات الخاصة لتحسين وضوح العرض والقراءة.',
      en: 'Options for people with special needs to improve display clarity.');
  static String get largeText => _l.t('تكبير الخط', en: 'Large text');
  static String get highContrast => _l.t('تباين عالٍ', en: 'High contrast');
  static String get lowDataMode => _l.t('وضع توفير البيانات', en: 'Low data mode');
  static String get lowDataModeHint => _l.t(
      'يقلل استهلاك البيانات في الطوارئ: ضغط الصور والصوت وتقليل وتيرة التحديث.',
      en: 'Reduces data use in emergencies: compress images/audio and slow down updates.');

  // Nav
  static String get navHome => _l.t('الرئيسية', en: 'Home');
  static String get navReports => _l.t('بلاغاتي', en: 'My reports');
  static String get navMap => _l.t('الخريطة', en: 'Map');
  static String get navProfile => _l.t('حسابي', en: 'Account');

  // Reports list
  static String get noReports => _l.t('لا توجد بلاغات', en: 'No reports');
  static String get noReportsList => _l.t('لا توجد بلاغات مسجلة حالياً', en: 'No reports yet');

  // Add contact dialog
  static String get addContactTitle => _l.t('إضافة جهة اتصال', en: 'Add emergency contact');
  static String get editContactTitle => _l.t('تعديل جهة اتصال', en: 'Edit emergency contact');
  static String get contactName => _l.t('الاسم', en: 'Name');
  static String get contactRelation => _l.t('صلة القرابة', en: 'Relation');
  static String get contactPhone => _l.t('رقم الهاتف', en: 'Phone number');
  static String get cancel => _l.t('إلغاء', en: 'Cancel');
  static String get add => _l.t('إضافة', en: 'Add');

  // Profile editing
  static String get editProfile => _l.t('تعديل الملف الشخصي', en: 'Edit profile');
  static String get deleteConfirmTitle => _l.t('حذف جهة الاتصال', en: 'Delete contact');
  static String get deleteConfirmBody => _l.t('هل أنت متأكد من حذف جهة الاتصال هذه؟',
      en: 'Are you sure you want to delete this contact?');
  static String get delete => _l.t('حذف', en: 'Delete');
  static String get noNotifications => _l.t('لا توجد إشعارات جديدة', en: 'No new notifications');
}