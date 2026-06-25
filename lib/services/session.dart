// lib/services/session.dart
//
// Tiny global signal for auth state. Flipped to `true` by AuthScreen after
// a successful login and to `false` by DashboardV2 on logout. AuthCheck
// listens to this and re-runs the token check whenever it changes, so the
// app navigates between AuthScreen ↔ DashboardV2 without needing a full
// restart.

import 'package:flutter/foundation.dart';

/// Auth state signal for the running session.
///
/// - `true`  → user is (or just became) signed in.
/// - `false` → user is (or just became) signed out.
final ValueNotifier<bool> authNotifier = ValueNotifier<bool>(false);

/// Convenience flip — only notifies when the value actually changes.
void setAuthed(bool loggedIn) {
  if (authNotifier.value != loggedIn) {
    authNotifier.value = loggedIn;
  }
}
