# Admin App Improvements - Implementation Plan

## Overview
Comprehensive improvements to align admin app with mobile app design patterns and fix critical bugs.

## Priority 1: Critical Fixes

### 1. Fix Accounts Page Null Cast Error ✓
**File**: `src/admin_app/lib/features/accounts/models/customer_account.dart`
**Issue**: Line 125 - customerId might be returned as null but cast as non-nullable String
**Fix**: Ensure proper null handling in fromJson

### 2. Add User Display Name to Orders
**Files to modify**:
- `src/admin_app/lib/features/orders/models/order.dart` - Add userName field
- Backend API should return userName with orders
- Update all order displays to show userName instead of just order number

## Priority 2: Consistent Styling

### 3. Apply FHeader to All Screens
**Pattern from mobile**: `FHeader(title: const Text('Title', style: TextStyle(fontSize: 18)))`
**Screens to update**:
- Dashboard ✓
- Orders
- Rooms
- Service Requests
- Menu
- Loyalty
- Accounts ✓ (already has header but not FHeader)
- Customers
- Settings

### 4. Standardize Padding
Use `const EdgeInsets.all(16)` or `kScreenPadding` consistently across all screens

## Priority 3: UI/UX Improvements

### 5. Redesign More Menu
**Changes**:
- Remove user info from top (lines 108-151 in admin_scaffold.dart)
- Add "Profile" menu item that navigates to /profile
- Move "Logout" under Profile menu
- Reduce font size and padding between menu items

### 6. Create Profile Screen for Admin
**New file**: `src/admin_app/lib/features/profile/screens/profile_screen.dart`
**Pattern**: Similar to mobile app profile (avatar, name, email, settings options)
**Contents**:
- User avatar with initials
- Display name
- Email
- Logout button

### 7. Show User Display Name for Reserved Rooms
**Files**: Room models and displays
- Add userDisplayName to Room/RoomSession model
- Display in room tiles and session lists

### 8. Redesign Room Listing
**Match mobile app**:
- Use icons instead of buttons
- Implement favorite/unfavorite icon
- Improve padding and card design
- Better visual hierarchy

### 9. Show User Display Name in Loyalty Page
**File**: `src/admin_app/lib/features/loyalty/screens/loyalty_screen.dart`
- Replace userId display with userDisplayName

### 10. Change Account Detail to Page (not sheet)
**File**: `src/admin_app/lib/features/loyalty/screens/loyalty_screen.dart`
- Navigate to new page instead of showing bottom sheet
- Use `context.push()` instead of `showModalBottomSheet()`

### 11. Fix Sheets to Use Forui
**Files**: Loyalty screen add points/adjust buttons
- Replace Material `showModalBottomSheet` with Forui sheet components
- Ensure consistent styling

## Priority 4: Architecture

### 12. Merge Customers with Accounts
**Analysis**:
- Customers: Firebase user management
- Accounts: Financial/billing tracking
**Decision**: Keep separate but add navigation between them
- Add link from Customer detail to their Account
- Add link from Account detail to Customer profile

## Implementation Sequence

1. Fix accounts page null error
2. Add user display names to Order model
3. Apply FHeader to all screens
4. Create admin profile screen
5. Update more menu
6. Fix loyalty page user display
7. Room listing redesign
8. Sheet component fixes
9. Customer/Account integration

## Technical Notes

### Backend Changes Needed
- Order API should return `userName` or `userDisplayName`
- Room/Session API should return `userDisplayName` for reserved rooms
- Loyalty API should return full user details not just IDs

### Design Patterns to Follow
- Header: `FHeader(title: const Text('Title', style: TextStyle(fontSize: 18)))`
- Padding: `kScreenPadding` or `const EdgeInsets.all(16)`
- Cards: Use `FCard` for containers
- Buttons: Use `FButton` with appropriate styles
- Navigation: Use `context.go()` or `context.push()` from go_router
