# Remaining Admin App Improvements

## Completed Tasks ✅

1. **Fixed accounts page null type cast error** - Updated CustomerAccount.fromJson to safely handle null customerIds
2. **Added user display name to orders** - Updated Order model to include userName field and display it in pending orders
3. **Room name already shown in orders** - Confirmed this is working
4. **Created profile screen** - New profile page with avatar, name, email, and logout
5. **Updated more menu** - Removed user info from top, added Profile item, reduced spacing

## Remaining Tasks

### High Priority

#### 1. Apply FHeader to All Admin Screens

**What to do**: Replace custom headers with FHeader across all admin screens for consistency.

**Pattern**:
```dart
FHeader(
  title: const Text('Screen Title', style: TextStyle(fontSize: 18)),
)
```

**Files to update**:
- ✅ Dashboard - Currently has custom padding/text (line 46-63)
- Orders screen
- Rooms screen
- Service Requests screen
- Menu screen
- Loyalty screen
- ✅ Accounts screen - Already uses custom header
- Customers screen
- Settings screen

**Example for dashboard_screen.dart**:
```dart
// Replace lines 46-63 with:
return Column(
  children: [
    // Header
    FHeader(
      title: const Text('Dashboard', style: TextStyle(fontSize: 18)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 22),
          onPressed: () => ref.read(dashboardProvider.notifier).loadDashboard(),
          tooltip: 'Refresh',
        ),
      ],
    ),
    // Rest of content...
```

#### 2. Show User Display Name for Reserved Rooms

**Backend Changes Needed**:
- Room/Session API should return `userDisplayName` or `userName` for reserved rooms
- Update RoomSession model in `src/admin_app/lib/features/rooms/models/room.dart`

**Add to RoomSession model**:
```dart
final String? userId;
final String? userName;  // Add this

RoomSession({
  // existing fields...
  this.userId,
  this.userName,  // Add this
});

factory RoomSession.fromJson(Map<String, dynamic> json) {
  return RoomSession(
    // existing parsing...
    userId: json['userId'] as String?,
    userName: json['userName'] ?? json['userDisplayName'] as String?,  // Add this
  );
}
```

**Display in UI**: Update room cards and session displays to show userName where currently showing just status.

#### 3. Redesign Room Listing (Match Mobile App)

**Current Issues**:
- Uses buttons instead of icons
- Missing favorite functionality
- Inconsistent padding

**What to do**:
1. Replace action buttons with icon buttons
2. Add favorite icon (star) that can be tapped
3. Improve card design with better padding
4. Match the visual hierarchy from mobile app's rooms screen

**Reference**: `src/mobile_app/lib/features/rooms/screens/rooms_screen.dart`

#### 4. Show User Display Name in Loyalty Page

**File**: `src/admin_app/lib/features/loyalty/screens/loyalty_screen.dart`

**What to do**:
- Currently displays userId in loyalty accounts list
- Update to display userName/displayName instead
- May need backend changes to include full user details

#### 5. Change Account Detail to Page (Not Sheet)

**File**: `src/admin_app/lib/features/loyalty/screens/loyalty_screen.dart`

**What to do**:
Replace bottom sheet navigation with page navigation:

**Before**:
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => AccountDetailSheet(...),
);
```

**After**:
```dart
context.push('/loyalty/account/${accountId}');
```

**Steps**:
1. Create new route in `app_router.dart` for loyalty account detail
2. Convert `AccountDetailSheet` to full screen page
3. Update navigation in loyalty screen to use `context.push()` instead of `showModalBottomSheet()`

#### 6. Fix Sheets to Use Forui Instead of Material

**Files**:
- Loyalty screen (add points, adjust buttons)

**What to do**:
Find all instances of Material's `showModalBottomSheet` and replace with For ui's sheet components or use FDialog for simple forms.

**Material showModalBottomSheet** → **Forui alternatives**:
- For simple forms: Use `FDialog`
- For complex sheets: Use `showModalBottomSheet` but styled consistently

**Example**:
```dart
// Instead of Material dialog
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
);

// Use Forui dialog
showAdaptiveDialog(
  context: context,
  builder: (context) => FDialog(
    direction: Axis.horizontal,
    title: const Text('Title'),
    body: const Text('Content'),
    actions: [
      FButton(
        style: FButtonStyle.outline(),
        child: const Text('Cancel'),
        onPress: () => Navigator.pop(context),
      ),
      FButton(
        child: const Text('Confirm'),
        onPress: () => _handleAction(),
      ),
    ],
  ),
);
```

### Medium Priority

#### 7. Merge/Integrate Customers with Accounts

**Current State**:
- **Customers**: Firebase user management (email, name, phone, loyalty points)
- **Accounts**: Financial tracking (balance, charges, payments)

**Recommendation**: Keep separate but add cross-navigation

**What to do**:
1. In Customer detail screen, add link/button to view their Account (if they have one)
2. In Account detail sheet/page, add link to view Customer profile
3. Add "customerName" caching in Accounts API to reduce lookups

**Files to update**:
- `src/admin_app/lib/features/customers/screens/customer_detail_screen.dart` - Add "View Account" button
- Account detail UI - Add "View Customer Profile" link

### Backend Changes Needed

**Summary of API changes required**:

1. **Orders API** (`/api/orders`):
   - Include `userName` or `userDisplayName` in order responses
   - This field should be populated from the buyer's Firebase user data

2. **Rooms/Sessions API**:
   - Include `userName` or `userDisplayName` for reserved rooms and active sessions
   - Show who reserved/is using the room

3. **Loyalty API**:
   - Include full user details (name, email) not just userId in loyalty accounts list
   - OR create a lookup mechanism to get user details by ID

## Implementation Priority

### Week 1:
1. Apply FHeader to all screens (1-2 hours)
2. Backend: Add userName to Orders API response
3. Fix accounts null error (DONE ✅)
4. Create profile screen (DONE ✅)
5. Update more menu (DONE ✅)

### Week 2:
1. Backend: Add userName to Rooms/Sessions API
2. Show user names for reserved rooms
3. Show user names in loyalty page
4. Change account detail to page navigation

### Week 3:
1. Redesign room listing
2. Fix remaining Material sheets to use Forui
3. Add customer/account cross-navigation
4. Polish and testing

## Testing Checklist

After implementing changes, test:
- [ ] All screens have consistent FHeader styling
- [ ] Orders show user display names
- [ ] Room reservations show who reserved them
- [ ] Profile screen works (navigation, logout)
- [ ] More menu has correct items and compact layout
- [ ] Accounts page doesn't crash with null customerIds
- [ ] Loyalty page shows user names not IDs
- [ ] Account details open in new page (not sheet)
- [ ] All dialogs/sheets use Forui components
- [ ] Navigation between customers and accounts works

## Notes

- Keep mobile app padding consistent: `const EdgeInsets.all(16)` or `kScreenPadding`
- Use Forui components exclusively (FButton, FHeader, FDialog, etc.)
- Follow mobile app patterns for consistency
- Test on both mobile and tablet layouts
- Ensure all null safety is proper (use `?.` and `?? ''` patterns)

## Code Style Guidelines

```dart
// Headers
FHeader(
  title: const Text('Title', style: TextStyle(fontSize: 18)),
)

// Padding
padding: const EdgeInsets.all(16)
// or
padding: kScreenPadding

// Buttons
FButton(
  onPress: () {},
  child: const Text('Label'),
)

// Navigation
context.go('/route')  // For main navigation
context.push('/route')  // For detail screens

// Dialogs
showAdaptiveDialog(
  context: context,
  builder: (context) => FDialog(...),
)
```
