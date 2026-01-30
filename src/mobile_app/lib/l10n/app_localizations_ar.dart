// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تشيلاكس';

  @override
  String get cafeAndGaming => 'كافيه وألعاب';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get register => 'تسجيل';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameOrEmail => 'اسم المستخدم أو البريد';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get name => 'الاسم';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get enterUsernameOrEmail => 'أدخل اسم المستخدم أو البريد';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get createPassword => 'أنشئ كلمة مرور';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get chooseUsername => 'اختر اسم مستخدم';

  @override
  String get yourDisplayName => 'اسمك المعروض';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get google => 'جوجل';

  @override
  String get facebook => 'فيسبوك';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get guestUser => 'زائر';

  @override
  String get enterBothUsernamePassword =>
      'الرجاء إدخال اسم المستخدم وكلمة المرور.';

  @override
  String get invalidCredentials =>
      'اسم المستخدم أو كلمة المرور غير صحيحة. حاول مرة أخرى.';

  @override
  String anErrorOccurred(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get socialSignInFailed => 'فشل تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get fillAllFields => 'الرجاء ملء جميع الحقول.';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get passwordTooShort => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';

  @override
  String get registrationSuccessful => 'تم التسجيل بنجاح! قم بتسجيل الدخول.';

  @override
  String get registrationFailed =>
      'فشل التسجيل. اسم المستخدم أو البريد موجود مسبقاً.';

  @override
  String get success => 'نجاح';

  @override
  String get error => 'خطأ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get clear => 'مسح';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get join => 'انضمام';

  @override
  String get close => 'إغلاق';

  @override
  String get menu => 'القائمة';

  @override
  String get orders => 'الطلبات';

  @override
  String get rooms => 'الغرف';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get cart => 'السلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get searchMenu => 'البحث في القائمة...';

  @override
  String get noItemsAvailable => 'لا توجد عناصر متاحة';

  @override
  String failedToLoadMenu(String error) {
    return 'فشل تحميل القائمة: $error';
  }

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get addToCart => 'أضف للسلة';

  @override
  String get yourCartIsEmpty => 'السلة فارغة';

  @override
  String get addItemsFromMenu => 'أضف عناصر من القائمة';

  @override
  String get orderNoteOptional => 'ملاحظة الطلب (اختياري)';

  @override
  String get anySpecialRequests => 'أي طلبات خاصة';

  @override
  String get useLoyaltyPoints => 'استخدم نقاط الولاء';

  @override
  String get pts => 'نقطة';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get pointsDiscount => 'خصم النقاط';

  @override
  String get total => 'الإجمالي';

  @override
  String get placeOrder => 'تأكيد الطلب';

  @override
  String get clearCart => 'إفراغ السلة';

  @override
  String get removeAllItemsFromCart => 'حذف جميع العناصر من السلة؟';

  @override
  String get orderPlacedSuccessfully => 'تم تأكيد الطلب بنجاح!';

  @override
  String get failedToPlaceOrder => 'فشل تأكيد الطلب';

  @override
  String noteWithText(String notes) {
    return 'ملاحظة: $notes';
  }

  @override
  String get failedToLoadOrders => 'فشل تحميل الطلبات';

  @override
  String get pullDownToRetry => 'اسحب للأسفل للمحاولة مجدداً';

  @override
  String get noOrdersYet => 'لا توجد طلبات بعد';

  @override
  String get orderHistoryWillAppearHere => 'سيظهر سجل طلباتك هنا';

  @override
  String orderNumber(String id) {
    return 'طلب #$id';
  }

  @override
  String get noItems => 'لا توجد عناصر';

  @override
  String get yourRating => 'تقييمك: ';

  @override
  String get rateThisOrder => 'قيّم هذا الطلب';

  @override
  String get failedToLoadDetails => 'فشل تحميل التفاصيل';

  @override
  String get enterSixDigitCode => 'أدخل كود من 6 أرقام';

  @override
  String get enterCode => 'أدخل الكود';

  @override
  String get invalidCode => 'كود غير صحيح';

  @override
  String get joinedSession => 'تم الانضمام للجلسة!';

  @override
  String get failedToLoadRooms => 'فشل تحميل الغرف';

  @override
  String get sessionActive => 'الجلسة نشطة';

  @override
  String get shareCodeWithFriends => 'شارك الكود مع أصدقائك';

  @override
  String get codeCopied => 'تم نسخ الكود!';

  @override
  String get needSomething => 'تحتاج شيء؟';

  @override
  String get callWaiter => 'استدعاء النادل';

  @override
  String get controller => 'يد تحكم';

  @override
  String get getBill => 'الحساب';

  @override
  String get waiterNotified => 'تم إبلاغ النادل';

  @override
  String get controllerRequestSent => 'تم إرسال طلب يد التحكم';

  @override
  String get billRequestSent => 'تم إرسال طلب الحساب';

  @override
  String get reserved => 'محجوز';

  @override
  String get cancelReservation => 'إلغاء الحجز';

  @override
  String get cancelReservationQuestion => 'إلغاء الحجز؟';

  @override
  String get confirmCancelReservation => 'هل أنت متأكد من إلغاء الحجز؟';

  @override
  String get noKeep => 'لا، احتفظ';

  @override
  String get yesCancel => 'نعم، إلغاء';

  @override
  String get reservationCancelled => 'تم إلغاء الحجز';

  @override
  String get failedToCancelReservation => 'فشل إلغاء الحجز';

  @override
  String get allRoomsBusy => 'جميع الغرف مشغولة حالياً';

  @override
  String get getNotifiedWhenAvailable => 'احصل على إشعار عند توفر غرفة';

  @override
  String get willBeNotifiedWhenAvailable => 'سيتم إشعارك عند توفر غرفة';

  @override
  String get unsubscribedFromNotifications => 'تم إلغاء الاشتراك في الإشعارات';

  @override
  String get youWillBeNotified => 'سيتم إشعارك!';

  @override
  String get failedToSubscribe => 'فشل الاشتراك';

  @override
  String get notifyMe => 'أبلغني';

  @override
  String get fifteenMinutesToArrive => '15 دقيقة للوصول';

  @override
  String get reservationCancelledIfNoCheckIn =>
      'سيتم إلغاء حجزك تلقائياً إذا لم تصل خلال 15 دقيقة.';

  @override
  String reserveRoomName(String roomName) {
    return 'احجز $roomName';
  }

  @override
  String get perHour => '/ساعة';

  @override
  String get reserveNow => 'احجز الآن';

  @override
  String get roomReservedSuccess => 'تم الحجز! لديك 15 دقيقة للوصول.';

  @override
  String get failedToReserveRoom => 'فشل حجز الغرفة';

  @override
  String get available => 'متاح';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get sessionHistory => 'سجل الجلسات';

  @override
  String get favorites => 'المفضلة';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get about => 'حول التطبيق';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get signOutConfirmation => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get needHelpContactUs => 'تحتاج مساعدة؟ تواصل معنا:';

  @override
  String get supportHours => 'يومياً: 10:00 صباحاً - 11:00 مساءً';

  @override
  String get aboutDescription =>
      'اطلب مشروبات وأكل لذيذ، أو احجز غرفة بلايستيشن لتجربة ألعاب رائعة.';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get orderStatusUpdates => 'تحديثات حالة الطلب';

  @override
  String get orderStatusUpdatesDescription =>
      'احصل على إشعار عند تغير حالة طلبك';

  @override
  String get promotionsAndOffers => 'العروض والتخفيضات';

  @override
  String get promotionsDescription => 'احصل على عروض وخصومات خاصة';

  @override
  String get sessionReminders => 'تذكير الجلسات';

  @override
  String get sessionRemindersDescription => 'تذكير قبل جلسة الألعاب';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'الثيم';

  @override
  String get account => 'الحساب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get updateEmail => 'تحديث البريد الإلكتروني';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirmation =>
      'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get accountDeletedSuccessfully => 'تم حذف الحساب بنجاح';

  @override
  String get failedToDeleteAccount => 'فشل حذف الحساب';

  @override
  String get selectTheme => 'اختر الثيم';

  @override
  String get light => 'فاتح';

  @override
  String get lightThemeDescription => 'استخدم الثيم الفاتح دائماً';

  @override
  String get dark => 'داكن';

  @override
  String get darkThemeDescription => 'استخدم الثيم الداكن دائماً';

  @override
  String get systemDefault => 'تلقائي';

  @override
  String get systemDefaultDescription => 'اتبع إعدادات الجهاز';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get currency => 'ج.م';

  @override
  String priceFormat(String price) {
    return '$price ج.م';
  }
}
