# Withdrawal Feature Implementation

## Files Created

### 1. Model - `lib/models/withdrawal.dart`

- `Withdrawal` class - Model untuk single withdrawal request
- `WithdrawalSummary` class - Summary balance info
- Helper methods: `getStatusLabel()`, `getMethodLabel()`

### 2. Provider Update - `lib/providers/goal_provider.dart`

Added methods:

- `requestWithdrawal()` - Submit withdrawal request
- `fetchWithdrawalHistory()` - Get list of withdrawals with summary
- `getAvailableBalance()` - Get balance available for withdrawal
- `getTotalPendingWithdrawal()` - Get pending amount

State added:

- `_withdrawalSummary` - Balance info
- `_withdrawals` - List of withdrawal requests

### 3. Screen - `lib/screens/withdrawals/withdrawal_screen.dart`

Features:

- **Tab 1: Tarik Dana (Request Withdrawal)**
  - Display balance summary (total, pending, available)
  - Form to request withdrawal
  - Method selection (Dana, GoPay, Bank Transfer, dll)
  - Amount validation (min Rp 10.000)
  - Auto-formatting with IDR currency
  - Account number input based on method

- **Tab 2: Riwayat (Withdrawal History)**
  - List of all withdrawal requests
  - Status indicators (Pending, Approved, Completed, Rejected)
  - Tap to view detail
  - Pull-to-refresh

---

## How to Integrate

### Step 1: Add to Main Navigation

```dart
// lib/main.dart atau routing file

import 'screens/withdrawals/withdrawal_screen.dart';

// Add to navigation menu
bottomNavigationBar: BottomNavigationBar(
  items: [
    // ... existing items ...
    const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet),
      label: 'Tarik Dana',
    ),
  ],
  onTap: (index) {
    if (index == 3) { // Adjust index as needed
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
      );
    }
  },
),
```

### Step 2: Test API Integration

Make sure backend endpoints are running:

- `POST /api/withdrawals/request`
- `GET /api/withdrawals/index`

### Step 3: Update API Base URL

In `lib/core/constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
// or
static const String baseUrl = 'http://192.168.x.x:8000/api'; // Device
```

---

## Features Implemented

### Balance Summary

✅ Total Balance - Sum of all goals' current amount
✅ Pending Withdrawal - Withdrawals waiting for approval
✅ Available for Withdrawal - Balance - Pending
✅ Total Completed - Total successfully withdrawn

### Withdrawal Request Form

✅ Amount input with auto-formatting (IDR)
✅ Method selection dropdown
✅ Method-specific account input (phone/account number)
✅ Optional notes
✅ Amount validation (min 10,000)
✅ Insufficient balance check

### Withdrawal History

✅ List all withdrawal requests
✅ Status indicators with colors
✅ Timestamp display
✅ Tap to view full details
✅ Pull-to-refresh
✅ Empty state handling

### Form Validation

✅ Amount required & > 0
✅ Minimum 10,000 check
✅ Maximum available balance check
✅ Account number required & validated
✅ Account number length validation

---

## Status Flow

```
pending → approved → completed
            ↓
         rejected
```

Status colors:

- Pending (Orange) - Waiting for admin approval
- Approved (Blue) - Approved, waiting for processing
- Completed (Green) - Successfully withdrawn
- Rejected (Red) - Rejected by admin

---

## Testing Checklist

- [ ] Backend withdrawal endpoints deployed
- [ ] Can request withdrawal with valid amount
- [ ] Validation works (insufficient balance, min amount)
- [ ] Auto-formatting works (IDR currency)
- [ ] Can switch between withdrawal methods
- [ ] History shows all requests
- [ ] Refresh works
- [ ] Detail modal opens on tap
- [ ] Status colors display correctly

---

## API Response Format Expected

### Request Success (201)

```json
{
  "success": true,
  "message": "Withdrawal request created successfully",
  "data": {
    "id": 1,
    "user_id": 1,
    "amount": 100000,
    "method": "dana",
    "status": "pending",
    "created_at": "2026-01-18 10:30:00"
  }
}
```

### Get History Success (200)

```json
{
  "success": true,
  "data": {
    "summary": {
      "total_balance": 500000,
      "total_pending_withdrawal": 100000,
      "available_for_withdrawal": 400000,
      "total_completed": 1000000
    },
    "withdrawals": [
      {
        "id": 1,
        "user_id": 1,
        "amount": 100000,
        "method": "dana",
        "account_number": "08123456789",
        "status": "pending",
        "notes": null,
        "admin_notes": null,
        "created_at": "2026-01-18 10:30:00",
        "updated_at": null
      }
    ]
  }
}
```

---

## Error Handling

✅ Insufficient balance error
✅ API errors caught and displayed
✅ Loading state during request
✅ SnackBar notifications for success/error
✅ Network error handling

---

## Next Steps (Optional Enhancements)

1. **Admin Dashboard** - Approve/reject withdrawal requests
2. **Notification** - Push notification when withdrawal approved/rejected
3. **Transaction Receipt** - Download withdrawal receipt
4. **Scheduled Withdrawals** - Set automatic weekly/monthly withdrawals
5. **Withdrawal Analytics** - Charts showing withdrawal trends

---

## Debug Logging

Withdrawal operations are logged with `[GoalProvider]` prefix:

```
[GoalProvider] Requesting withdrawal of 100000 via dana
[GoalProvider] Withdrawal request created successfully
[GoalProvider] Fetching withdrawal history
[GoalProvider] Fetched 5 withdrawals
```

Enable in production by monitoring app logs.
