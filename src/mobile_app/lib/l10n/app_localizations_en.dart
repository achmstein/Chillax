// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chillax';

  @override
  String get cafeAndGaming => 'Cafe & Gaming';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get register => 'Register';

  @override
  String get signOut => 'Sign Out';

  @override
  String get username => 'Username';

  @override
  String get usernameOrEmail => 'Username or Email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get name => 'Name';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get enterUsernameOrEmail => 'Enter your username or email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get createPassword => 'Create a password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get yourDisplayName => 'Your display name';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get google => 'Google';

  @override
  String get facebook => 'Facebook';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get createAccount => 'Create Account';

  @override
  String get guestUser => 'Guest User';

  @override
  String get enterBothUsernamePassword =>
      'Please enter both username and password.';

  @override
  String get invalidCredentials =>
      'Invalid username or password. Please try again.';

  @override
  String anErrorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get socialSignInFailed => 'Social sign in failed. Please try again.';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String get passwordsDontMatch => 'Passwords do not match.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';

  @override
  String get registrationSuccessful =>
      'Registration successful! Please sign in.';

  @override
  String get registrationFailed =>
      'Registration failed. Username or email may already exist.';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get clear => 'Clear';

  @override
  String get retry => 'Retry';

  @override
  String get join => 'Join';

  @override
  String get close => 'Close';

  @override
  String get menu => 'Menu';

  @override
  String get orders => 'Orders';

  @override
  String get rooms => 'Rooms';

  @override
  String get profile => 'Profile';

  @override
  String get cart => 'Cart';

  @override
  String get settings => 'Settings';

  @override
  String get searchMenu => 'Search menu...';

  @override
  String get noItemsAvailable => 'No items available';

  @override
  String failedToLoadMenu(String error) {
    return 'Failed to load menu: $error';
  }

  @override
  String get viewCart => 'View Cart';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get yourCartIsEmpty => 'Your cart is empty';

  @override
  String get addItemsFromMenu => 'Add items from the menu';

  @override
  String get orderNoteOptional => 'Order Note (optional)';

  @override
  String get anySpecialRequests => 'Any special requests';

  @override
  String get useLoyaltyPoints => 'Use Loyalty Points';

  @override
  String get pts => 'pts';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get pointsDiscount => 'Points discount';

  @override
  String get total => 'Total';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get removeAllItemsFromCart => 'Remove all items from your cart?';

  @override
  String get orderPlacedSuccessfully => 'Order placed successfully!';

  @override
  String get failedToPlaceOrder => 'Failed to place order';

  @override
  String noteWithText(String notes) {
    return 'Note: $notes';
  }

  @override
  String get failedToLoadOrders => 'Failed to load orders';

  @override
  String get pullDownToRetry => 'Pull down to retry';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get orderHistoryWillAppearHere =>
      'Your order history will appear here';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get noItems => 'No items';

  @override
  String get yourRating => 'Your rating: ';

  @override
  String get rateThisOrder => 'Rate This Order';

  @override
  String get failedToLoadDetails => 'Failed to load details';

  @override
  String get enterSixDigitCode => 'Enter 6-digit code';

  @override
  String get enterCode => 'Enter code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get joinedSession => 'Joined session!';

  @override
  String get failedToLoadRooms => 'Failed to load rooms';

  @override
  String get sessionActive => 'Session Active';

  @override
  String get shareCodeWithFriends => 'Share code with friends';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get needSomething => 'Need something?';

  @override
  String get callWaiter => 'Call Waiter';

  @override
  String get controller => 'Controller';

  @override
  String get getBill => 'Get Bill';

  @override
  String get waiterNotified => 'Waiter has been notified';

  @override
  String get controllerRequestSent => 'Controller request sent';

  @override
  String get billRequestSent => 'Bill request sent';

  @override
  String get reserved => 'Reserved';

  @override
  String get cancelReservation => 'Cancel Reservation';

  @override
  String get cancelReservationQuestion => 'Cancel Reservation?';

  @override
  String get confirmCancelReservation =>
      'Are you sure you want to cancel your reservation?';

  @override
  String get noKeep => 'No, Keep';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get reservationCancelled => 'Reservation cancelled';

  @override
  String get failedToCancelReservation => 'Failed to cancel reservation';

  @override
  String get allRoomsBusy => 'All rooms are currently busy';

  @override
  String get getNotifiedWhenAvailable =>
      'Get notified when a room becomes available';

  @override
  String get willBeNotifiedWhenAvailable =>
      'You will be notified when a room is available';

  @override
  String get unsubscribedFromNotifications => 'Unsubscribed from notifications';

  @override
  String get youWillBeNotified => 'You will be notified!';

  @override
  String get failedToSubscribe => 'Failed to subscribe';

  @override
  String get notifyMe => 'Notify Me';

  @override
  String get fifteenMinutesToArrive => '15 minutes to arrive';

  @override
  String get reservationCancelledIfNoCheckIn =>
      'Your reservation will be automatically cancelled if you don\'t check in within 15 minutes.';

  @override
  String reserveRoomName(String roomName) {
    return 'Reserve $roomName';
  }

  @override
  String get perHour => '/hr';

  @override
  String get reserveNow => 'Reserve Now';

  @override
  String get roomReservedSuccess =>
      'Room reserved! You have 15 minutes to arrive.';

  @override
  String get failedToReserveRoom => 'Failed to reserve room';

  @override
  String get available => 'Available';

  @override
  String get occupied => 'Occupied';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get statusReserved => 'Reserved';

  @override
  String get statusActive => 'Active';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String hourlyRateFormat(String rate) {
    return '£$rate/hour';
  }

  @override
  String get orderHistory => 'Order History';

  @override
  String get sessionHistory => 'Session History';

  @override
  String get favorites => 'Favorites';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get needHelpContactUs => 'Need help? Contact us:';

  @override
  String get supportHours => 'Mon-Sun: 10:00 AM - 11:00 PM';

  @override
  String get aboutDescription =>
      'Order delicious food & drinks, or reserve a PlayStation room for an amazing gaming experience.';

  @override
  String get notifications => 'Notifications';

  @override
  String get orderStatusUpdates => 'Order Status Updates';

  @override
  String get orderStatusUpdatesDescription =>
      'Get notified when your order status changes';

  @override
  String get promotionsAndOffers => 'Promotions & Offers';

  @override
  String get promotionsDescription => 'Receive special deals and discounts';

  @override
  String get sessionReminders => 'Session Reminders';

  @override
  String get sessionRemindersDescription =>
      'Get reminded before your gaming session';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change Password';

  @override
  String get updateEmail => 'Update Email';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get failedToDeleteAccount => 'Failed to delete account';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get light => 'Light';

  @override
  String get lightThemeDescription => 'Always use light theme';

  @override
  String get dark => 'Dark';

  @override
  String get darkThemeDescription => 'Always use dark theme';

  @override
  String get systemDefault => 'System Default';

  @override
  String get systemDefaultDescription => 'Follow your device settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get currency => 'EGP';

  @override
  String priceFormat(String price) {
    return '$price EGP';
  }

  @override
  String basePrice(String price) {
    return 'Base price: £$price';
  }

  @override
  String get specialInstructions => 'Special Instructions';

  @override
  String get anySpecialRequestsOptional => 'Any special requests?';

  @override
  String get required => 'Required';

  @override
  String get loyaltyRewards => 'Loyalty Rewards';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noLoyaltyAccountYet => 'No loyalty account yet';

  @override
  String get makePurchaseToEarn => 'Make a purchase to start earning points!';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get amountDue => 'Amount Due';

  @override
  String get creditBalance => 'Credit Balance';

  @override
  String get pleasePayAtCounter => 'Please pay at the counter';

  @override
  String get willBeAppliedToNextPurchase =>
      'Will be applied to your next purchase';

  @override
  String get noOutstandingBalance => 'No outstanding balance';

  @override
  String get transactions => 'Transactions';

  @override
  String get failedToLoadTransactions => 'Failed to load transactions';

  @override
  String failedToLoadFavorites(String error) {
    return 'Failed to load favorites: $error';
  }

  @override
  String get browseMenu => 'Browse Menu';

  @override
  String get joinOurLoyaltyProgram => 'Join our Loyalty Program';

  @override
  String get earnPointsDescription =>
      'Earn points on every purchase and unlock exclusive rewards!';

  @override
  String get joinNow => 'Join Now';

  @override
  String get viewHistory => 'View history';

  @override
  String lifetimePoints(String points) {
    return 'Lifetime: $points pts';
  }

  @override
  String pointsToNextTier(String points, String tier) {
    return '$points pts to $tier';
  }

  @override
  String get rateYourOrder => 'Rate Your Order';

  @override
  String get yourReviewOptional => 'Your Review (optional)';

  @override
  String get shareYourExperience => 'Share your experience...';

  @override
  String get submitRating => 'Submit Rating';

  @override
  String get ratingPoor => 'Poor';

  @override
  String get ratingFair => 'Fair';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingVeryGood => 'Very Good';

  @override
  String get ratingExcellent => 'Excellent';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Please enter a new password';

  @override
  String get passwordMustBe8Chars => 'Password must be at least 8 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get failedToChangePassword =>
      'Failed to change password. Please try again.';

  @override
  String get newEmail => 'New Email';

  @override
  String get pleaseEnterEmail => 'Please enter an email address';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get emailUpdatedSuccessfully => 'Email updated successfully';

  @override
  String get failedToUpdateEmail => 'Failed to update email. Please try again.';

  @override
  String get supportEmail => 'support@chillax.com';

  @override
  String get supportPhone => '0100 469 8 469';

  @override
  String get joinedSessionSuccessfully => 'Joined session successfully!';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get noFavoritesDescription => 'Items you love will appear here';
}
