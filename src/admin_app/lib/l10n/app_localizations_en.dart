// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chillax Admin';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get pending => 'Pending';

  @override
  String get active => 'Active';

  @override
  String get available => 'Available';

  @override
  String get pendingOrders => 'Pending Orders';

  @override
  String get activeSessions => 'Active Sessions';

  @override
  String get availableRooms => 'Available Rooms';

  @override
  String get viewAll => 'View all';

  @override
  String get noPendingOrders => 'No pending orders';

  @override
  String get noActiveSessions => 'No active sessions';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get usernameOrEmail => 'Username or Email';

  @override
  String get enterUsernameOrEmail => 'Enter your username or email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get error => 'Error';

  @override
  String get adminRoleRequired =>
      'You must have Admin role to access this application.';

  @override
  String get enterBothFields => 'Please enter both username and password.';

  @override
  String get invalidCredentials =>
      'Invalid username or password. Please try again.';

  @override
  String get orders => 'Orders';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get cancelOrderQuestion => 'Cancel Order?';

  @override
  String get cancelOrderConfirmation =>
      'Are you sure you want to cancel this order?';

  @override
  String get keep => 'Keep';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get create => 'Create';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get item => 'item';

  @override
  String get items => 'Items';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0';
  }

  @override
  String get note => 'Note';

  @override
  String get customerNote => 'Customer Note';

  @override
  String get total => 'Total';

  @override
  String get date => 'Date';

  @override
  String get each => 'each';

  @override
  String orderNumber(int id) {
    return 'Order #$id';
  }

  @override
  String get validating => 'Validating';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String get cancelOrderButton => 'Cancel Order';

  @override
  String get noKeep => 'No, Keep';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get rooms => 'Rooms';

  @override
  String get addRoom => 'Add Room';

  @override
  String get editRoom => 'Edit Room';

  @override
  String get noRoomsConfigured => 'No rooms configured';

  @override
  String get addRoomToGetStarted => 'Add a room to get started';

  @override
  String get endSession => 'End Session?';

  @override
  String get endSessionConfirmation =>
      'Are you sure you want to end this session? The customer will be charged for the time used.';

  @override
  String get endSessionButton => 'End Session';

  @override
  String get statusActive => 'Active';

  @override
  String get statusReserved => 'Reserved';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusOccupied => 'Occupied';

  @override
  String get statusMaintenance => 'Maintenance';

  @override
  String reservedCountdown(String countdown) {
    return 'Reserved ($countdown)';
  }

  @override
  String get expiring => 'Expiring...';

  @override
  String get perHour => '/hr';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Name *';

  @override
  String get description => 'Description';

  @override
  String get optionalDescription => 'Optional description';

  @override
  String get hourlyRate => 'Hourly Rate (\$) *';

  @override
  String get menu => 'Menu';

  @override
  String get categories => 'Categories';

  @override
  String get addItem => 'Add item';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get all => 'All';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get deleteItem => 'Delete Item?';

  @override
  String deleteItemConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get availableLabel => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get clickAddCategoryHint => 'Click the + button above to create one';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameHint => 'e.g., Drinks, Food, Desserts';

  @override
  String get categoryCreatedSuccess => 'Category created successfully';

  @override
  String get categoryUpdatedSuccess => 'Category updated successfully';

  @override
  String get categoryDeletedSuccess => 'Category deleted successfully';

  @override
  String get cannotDeleteCategory => 'Cannot Delete Category';

  @override
  String categoryHasItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return 'This category has $count $_temp0. Move or delete the items before deleting the category.';
  }

  @override
  String get deleteCategory => 'Delete Category?';

  @override
  String deleteCategoryConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get backToMenu => 'Back to menu';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get adminUser => 'Admin User';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get identityProvider => 'Identity Provider';

  @override
  String get ordersApi => 'Orders API';

  @override
  String get roomsApi => 'Rooms API';

  @override
  String get catalogApi => 'Catalog API';

  @override
  String get signOutQuestion => 'Sign Out?';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get accounts => 'Accounts';

  @override
  String get addCharge => 'Add Charge';

  @override
  String get totalOutstanding => 'Total Outstanding';

  @override
  String get searchByName => 'Search by name...';

  @override
  String get noAccountsFound => 'No accounts found';

  @override
  String get addChargeToCreate => 'Add a charge to create an account';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get customer => 'Customer';

  @override
  String get customerRequired => 'Customer *';

  @override
  String get searchCustomerByName => 'Search customer by name...';

  @override
  String get amount => 'Amount';

  @override
  String get amountEgp => 'Amount (EGP) *';

  @override
  String get descriptionOptional => 'Description';

  @override
  String get chargeDescriptionHint => 'e.g., Remaining from session - Room 3';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get chargeAddedSuccess => 'Charge added successfully';

  @override
  String get failedToAddCharge => 'Failed to add charge';

  @override
  String get loyalty => 'Loyalty';

  @override
  String get overview => 'Overview';

  @override
  String get accountsLabel => 'Accounts';

  @override
  String get todayLabel => 'Today';

  @override
  String get weekLabel => 'Week';

  @override
  String get monthLabel => 'Month';

  @override
  String get tiers => 'Tiers';

  @override
  String get noLoyaltyAccounts => 'No loyalty accounts yet';

  @override
  String get points => 'pts';

  @override
  String get lifetime => 'lifetime';

  @override
  String get requests => 'Requests';

  @override
  String get allClear => 'All clear';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get inProgress => 'In Progress';

  @override
  String get done => 'Done';

  @override
  String get room => 'Room';

  @override
  String get time => 'Time';

  @override
  String get tap => 'TAP';

  @override
  String get doneLabel => 'DONE';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get callWaiter => 'Call Waiter';

  @override
  String get controllerChange => 'Controller Change';

  @override
  String get receiptToPay => 'Receipt to Pay';

  @override
  String get customers => 'Customers';

  @override
  String get more => 'More';

  @override
  String get now => 'now';

  @override
  String get end => 'End';

  @override
  String get no => 'No';

  @override
  String get cancelReservation => 'Cancel Reservation';

  @override
  String get cancelReservationQuestion => 'Cancel Reservation?';

  @override
  String get cancelReservationConfirmation =>
      'Are you sure you want to cancel this reservation?';

  @override
  String get deleteRoom => 'Delete Room?';

  @override
  String deleteRoomConfirmation(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get startSession => 'Start Session';

  @override
  String get reserve => 'Reserve';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get customerWillBeCharged =>
      'The customer will be charged for the time used.';

  @override
  String get accessCodeCopied => 'Access code copied!';

  @override
  String get record => 'Record';

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get failedToRecordPayment => 'Failed to record payment';

  @override
  String get charge => 'Charge';

  @override
  String get payment => 'Payment';

  @override
  String get adjust => 'Adjust';

  @override
  String get addPoints => 'Add Points';

  @override
  String get pleaseEnterValidPoints => 'Please enter a valid points amount';

  @override
  String get pointsAdjusted => 'Points adjusted';

  @override
  String get pointsAdded => 'Points added';

  @override
  String get failedToAdjustPoints => 'Failed to adjust points';

  @override
  String get failedToAddPoints => 'Failed to add points';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get accountTab => 'Account';

  @override
  String get loyaltyTab => 'Loyalty';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String viewAllOrdersCount(int count) {
    return 'View all $count orders';
  }

  @override
  String get amountEgpLabel => 'Amount (EGP)';

  @override
  String get readyToStart => 'Ready to Start';

  @override
  String codeLabel(String code) {
    return 'Code: $code';
  }

  @override
  String get balance => 'Balance';

  @override
  String get memberSince => 'Member since';

  @override
  String get status => 'Status';

  @override
  String get disabled => 'Disabled';

  @override
  String get customerNotFound => 'Customer not found';

  @override
  String get accountNotFound => 'Account not found';

  @override
  String get orderHistory => 'Order History';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get viewCustomer => 'View Customer';

  @override
  String get history => 'History';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get cashPaymentHint => 'e.g., Cash payment';

  @override
  String get sessionBalanceHint => 'e.g., Session balance';

  @override
  String get chargeAdded => 'Charge added';

  @override
  String get loyaltyAccount => 'Loyalty Account';

  @override
  String get pointsBalance => 'Points Balance';

  @override
  String get usePositiveToAdd => 'Use positive to add, negative to deduct';

  @override
  String get reason => 'Reason';

  @override
  String get correctionHint => 'e.g., Correction';

  @override
  String get bonusPointsHint => 'e.g., Bonus points';

  @override
  String get pointsValueHint => 'e.g., 100 or -50';

  @override
  String get editMenuItem => 'Edit Menu Item';

  @override
  String get addMenuItem => 'Add Menu Item';

  @override
  String get enterItemName => 'Enter item name';

  @override
  String get enterItemDescription => 'Enter item description';

  @override
  String get price => 'Price';

  @override
  String get categoryRequired => 'Category *';

  @override
  String get selectCategory => 'Select category';

  @override
  String get preparationTime => 'Preparation Time (minutes)';

  @override
  String get prepTimeHint => 'e.g. 10';

  @override
  String get searchByNameOrEmail => 'Search by name or email...';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get roomNameHint => 'e.g. PlayStation Room 1';

  @override
  String get tierBronze => 'BRONZE';

  @override
  String get tierSilver => 'SILVER';

  @override
  String get tierGold => 'GOLD';

  @override
  String get tierPlatinum => 'PLATINUM';
}
