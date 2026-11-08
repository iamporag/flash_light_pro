# App Update System

Flash Light Pro checks for updates through **Google Play In-App Updates** only.
There is no custom update endpoint, backend, Firebase project, or analytics SDK.
The update system never opens a network connection itself: Google Play handles
all update traffic and package delivery. The release manifest declares
`INTERNET` for the optional AdMob ads and Google Play Billing only; those SDKs
are independent of the update system and are suspended while an update check or
mandatory update is active. Debug and profile builds additionally receive
Flutter's development-only `INTERNET` permission for hot reload.

> **Important:** In-app updates work only for builds installed and updated by
> Google Play. A sideloaded APK, an APK installed with `adb install`, or a build
> that was never uploaded to a Play testing or production track cannot be
> updated through this system. The app does not attempt to work around that.

## 1. Architecture

| Layer | File | Responsibility |
| --- | --- | --- |
| Domain values | `lib/features/updates/domain/app_version.dart` | Lenient semantic version parsing and comparison, including `+build` |
| Configuration | `lib/features/updates/domain/update_config.dart` | Play application id, minimum supported version, priorities, timings |
| Models | `lib/features/updates/domain/update_models.dart` | Platform-neutral availability, urgency, install status, failure, trusted policy |
| Policy | `lib/features/updates/domain/update_policy.dart` | Maps Play availability + priority + minimum version to an urgency |
| Persistence | `lib/features/updates/data/update_policy_store.dart` | `SharedPreferences` cache for verified policy, dismissal, last check |
| Play boundary | `lib/features/updates/data/update_gateway.dart` | Thin wrapper around `in_app_update`; Android-only |
| Store fallback | `lib/features/updates/data/store_launcher.dart` | Opens the Play Store listing (or App Store link when configured) |
| State machine | `lib/features/updates/application/update_cubit.dart` | Checks, throttling, retries, flows, install status, lifecycle |
| UI | `lib/features/updates/presentation/update_dialog.dart` | Premium dark update dialog for all phases |
| Startup gate | `lib/features/updates/presentation/update_gate.dart` | Delayed startup check, resume checks, duplicate prevention, ready notice |
| Composition | `lib/flash_light_pro.dart` | Provides `UpdateCubit` and wraps `HomeScreen` in `UpdateGate` |
| Manual entry | `lib/src/presentation/screens/settings/settings_page.dart` | “App updates” row with status and Check/Update/Install action |

The flashlight feature is untouched. The update gate only listens to
`FlashLightState.activeLight` to avoid interrupting lighting in progress.

## 2. Startup, lifecycle, and duplicate suppression

1. `UpdateGate.initState` schedules one check after
   `UpdateConfig.startupCheckDelay` (default **1.5 s**), after the flashlight
   has completed its essential initialization.
2. `UpdateCubit.checkForUpdate` is coalesced: a second call while a check is in
   flight returns immediately.
3. Non-forced checks are throttled by `recheckInterval` (default **6 h**),
   persisted as `updates.last_check_at`.
4. Returning to the app calls `onAppResumed`. If the app just opened the Play
   Store or a Play update flow, the next resume forces a check; otherwise the
   normal throttle applies.
5. The gate keeps `_dialogVisible`, so state updates and repeated checks cannot
   stack two dialogs. Notifications of a downloaded flexible update are also
   shown once per available build.
6. Builds, rebuilds, and unrelated flashlight state changes never trigger
   checks.

## 3. Policy levels

The policy combines Google Play's verified response with a version compiled
into the app.

| Play `updatePriority` | Urgency | Presentation |
| --- | --- | --- |
| 0–2 (or updatePriority unavailable) | Optional | “New Update Available”, dismissible |
| 3–4 | Recommended | “Update Recommended”, prominent but dismissible |
| 5 (configurable `mandatoryPriority`) | Mandatory | “Update Required”, non-dismissible |

An installed version below `UpdateConfig.minimumSupportedVersion` is also
mandatory **only when Google Play successfully reports that an update is
available**. The default minimum is `0.1.0`, which matches the current release,
so ordinary releases are never mandatory unless their Play priority is 5.

Additional safety rules:

- Play must report `updateAvailable`; an `updateNotAvailable` response clears the
  cached policy.
- If Play reports an `availableVersionCode` that is not greater than the
  installed `+build` number, no prompt is shown. This prevents false “newer
  version” dialogs from stale or duplicated version codes.
- Only a successful Play response can establish a mandatory update. A timeout,
  `PlatformException`, `MissingPluginException`, or malformed response never
  becomes mandatory.
- A previously verified mandatory policy is honored during a temporary outage
  only while fresh (`cachedPolicyTtl`, default **72 h**). After
  `bypassAfterFailedChecks` (default **2**) consecutive failures the dialog
  exposes “Continue without updating”, so a Play outage cannot lock the
  flashlight away forever.
- Optional dismissal is stored per `availableVersionCode`. A newer build asks
  again. Dismissals never suppress a mandatory prompt.

### Changing policy remotely

There is no custom remote JSON endpoint. The remote lever is the **Play update
priority**, set with the Google Play Developer API on the release:

```
PUT https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/edits/{editId}/tracks/{track}
{
  "track": "production",
  "releases": [{
    "versionCodes": ["42"],
    "status": "completed",
    "inAppUpdatePriority": 5
  }]
}
```

Notes:

- Priority is **not** editable in the Play Console UI; use the API (or a tool
  built on it).
- Play uses the highest priority among all tracks where the version is
  available.
- Google may cap or delay an update's availability (staged rollout, review).
- `minimumSupportedVersion` is a second, locally compiled lever for emergencies.
  Raising it requires shipping a new build, but it does not depend on any
  server.
- Changing either lever requires uploading a build with a higher version code
  and waiting for Play to expose it.

## 4. Dialog behavior

| State | Title | Actions |
| --- | --- | --- |
| Optional, available | New Update Available | Update Now, Open Play Store, Later |
| Recommended, available | Update Recommended | Update Now, Open Play Store, Later |
| Mandatory, available | Update Required | Update Now, Open Play Store; Continue without updating only while a cached policy is being bypassed |
| Downloading (optional/recommended) | Same urgency title | Hide |
| Downloading (mandatory) | Same urgency title | None (progress indicator only) |
| Downloaded | Same urgency title | Install Update; Later only when dismissible |
| Installing | Same urgency title | None (progress indicator only) |
| Failed | Same urgency title | Try again (rechecks Play), Open Play Store |
| Installed | Same urgency title | Close |

The dialog always shows the installed version and, when Play provides it, the
available build. Mandatory dialogs use `barrierDismissible: false` and
`PopScope(canPop: false)`; system back and outside taps do nothing. A failed or
canceled mandatory flow returns to the retryable dialog rather than dismissing
it.

**Emergency lighting:** the gate does not present any prompt while
`FlashLightState.activeLight` is non-null, including Torch, SOS, Strobe, Morse,
and Screen Light. If a mandatory update is established while a light is on, the
dialog appears as soon as the user turns the light off. Downloading a flexible
update never stops an active light.

## 5. Immediate updates

Used only when **both** conditions hold:

1. The policy is mandatory.
2. Play reports `immediateUpdateAllowed`.

The app calls `InAppUpdate.performImmediateUpdate()`. Android shows Play's
full-screen flow; the app cannot draw over it. On success the dialog confirms
installation; on user cancellation (`userDeniedUpdate`) or failure
(`inAppUpdateFailed`) the app returns to the update dialog with a retry action.
A missing plugin or Play Store failure falls back safely.

Immediate updates are not available for optional or recommended releases even
when Play would allow them. This avoids full-screen interruption for routine
updates.

## 6. Flexible updates

Used for optional/recommended updates, or a mandatory update when immediate is
not allowed but flexible is. The app calls
`InAppUpdate.startFlexibleUpdate()`.

- The download runs in the background; the light keeps working.
- `installUpdateListener` updates the state machine: `pending`/`downloading`
  map to a progress phase, `downloaded` enables install, `installing` shows a
  progress phase, `installed` completes, and `failed`/`canceled` return to the
  retryable dialog.
- When the download completes and no dialog is open, a SnackBar with an
  **Install** action is shown once per build.
- **Install Update** calls `InAppUpdate.completeFlexibleUpdate()`. Android then
  installs the update; the app may be restarted by the platform.
- Google Play does not expose byte-level progress, so the UI shows an
  indeterminate progress indicator rather than a percentage.
- If flexible updates are disallowed, the app opens the Play Store listing as a
  fallback.

## 7. Version comparison

`AppVersion.tryParse` accepts `major`, `major.minor`, `major.minor.patch`, an
optional `+build`, and ignores a prerelease suffix such as `-beta`. Invalid or
negative values are rejected.

- `compareTo` compares major/minor/patch only (semantic-version precedence).
- `isOlderThan` also compares build numbers when both versions declare them.
- A missing or invalid `minimumSupportedVersion` disables the local minimum
  check instead of forcing anything.
- Play availability is additionally guarded by comparing `availableVersionCode`
  with the installed build number.

## 8. Offline and failure behavior

| Situation | Result |
| --- | --- |
| App online, update available | Prompt per policy |
| Play reports no update | No prompt; cached policy cleared |
| No connection / Play timeout | Existing optional prompt preserved, no force; cached fresh mandatory may be shown with a bypass after repeated failures |
| Play API missing (e.g. sideloaded/unsupported device) | No prompt, no force |
| App killed during flexible download | Download continues in Play; next check reports `inProgress` and the dialog resumes the correct phase |
| User cancels immediate flow | Retryable dialog, app remains usable |
| Flexible download/install fails | Retryable dialog with Play Store fallback |
| Play Store launch fails | Inline error with retry |
| Invalid config/minimum/preferences | Defaults; update checks continue; no crash |
| iOS | No Play check at all; store-managed message in Settings; optional App Store link only when configured |

The update system never makes its own network request, so an offline state never
produces a false “update required” or an error dialog on launch. AdMob failures
and slow ad loading cannot delay or block an update check, and every ad format
is suppressed while a mandatory update is active or the Play update flow runs.

## 9. Configuration

`UpdateConfig` is the single place to change behavior:

| Field | Default | Meaning |
| --- | --- | --- |
| `playStoreId` | `io.github.iamporag.flashlightpro` (or `--dart-define=PLAY_STORE_ID=…`) | Play listing id; must match `applicationId` |
| `appStoreId` | empty (or `--dart-define=APP_STORE_ID=…`) | Numeric App Store id; no iOS link when empty |
| `minimumSupportedVersion` | `0.1.0` | Locally compiled emergency minimum |
| `mandatoryPriority` | `5` | Play priority that makes an update mandatory |
| `recommendedPriority` | `3` | Play priority that makes an update recommended |
| `startupCheckDelay` | `1.5 s` | Delay after flashlight initialization |
| `recheckInterval` | `6 h` | Throttle for automatic checks |
| `cachedPolicyTtl` | `72 h` | How long a verified mandatory policy survives outages |
| `checkTimeout` | `10 s` | Timeout around the Play check |
| `bypassAfterFailedChecks` | `2` | Failed checks before a cached mandatory prompt offers a bypass |

`lib/flash_light_pro.dart` accepts injectable `updateGateway`,
`updatePolicyStore`, `storeLauncher`, `updateConfig`, `updateCurrentVersion`, and
`updateClock` for tests. Production uses `PlayUpdateGateway`,
`SharedPreferencesUpdatePolicyStore`, and `UrlStoreLauncher`.

## 10. Google Play Console and API setup

1. Upload a build with `versionCode` greater than the installed build.
2. Distribute it to an **internal testing**, **closed testing**, **open
   testing**, or **production** track. In-app updates do not work for local or
   sideloaded builds.
3. Install the lower build from that Play track on a real device signed into a
   Play account that has access to the track.
4. Set `inAppUpdatePriority` on the newer release through the Google Play
   Developer API. Use `5` for mandatory, `3–4` for recommended, or `0–2` for
   optional.
5. Make sure the newer build is fully available to that tester (staged rollouts
   and review delays can hide it).
6. Launch the app, wait for the startup delay, and verify the dialog.

Optional API approval: the Play Developer API must be enabled in the associated
Google Cloud project, and the calling account needs release-management
permission.

## 11. Manual testing procedure

Preconditions:

- Real Android device with Google Play services and Play Store.
- App installed from the same Play testing track as the newer build.
- Network connection.
- Access to Play Console and the Developer API (for priority changes).

Scenarios:

1. **No update** — install the newest test build; no dialog appears; Settings
   shows “You're using the latest version”.
2. **Optional** — upload a newer build with priority 0–2; optional dialog, Later
   hides it, and it stays hidden for that build.
3. **Newer build after dismissal** — upload another build; the prompt returns.
4. **Recommended** — priority 3–4; title says Recommended; Later still works.
5. **Mandatory** — priority 5; back and outside taps do nothing; Update Now
   starts Play's flow.
6. **Immediate** — mandatory + Play allows immediate; verify Play's full-screen
   flow, success, cancellation, and return behavior.
7. **Flexible** — update in background while using Torch/SOS; verify the light
   is not interrupted, the Install snackbar appears, and Install completes.
8. **Offline** — enable airplane mode after establishing a mandatory policy;
   verify the cached notice and bypass after repeated failures.
9. **Play Store return** — tap Open Play Store, update manually, and return;
   verify the app rechecks.
10. **iOS** — confirm no Play prompt and the store-managed Settings row.

Automated tests cover the state machine, policy, preferences, gate, dialog,
lifecycle, and existing flashlight behavior. They cannot replace testing through
an eligible Play track: the real Play flows are provided by the Play Store app
and are not available in the test harness.

## 12. Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| No prompt on a sideloaded APK | In-app updates require Play distribution |
| No prompt after upload | Build not yet available to the tester, staged rollout, review pending, or installed build is not from Play |
| `updateNotAvailable` despite newer upload | Version code not higher, wrong track/account, or Play cache delay |
| Immediate flow never starts | Play does not allow it for this user/build; app falls back to flexible or store |
| Priority seems ignored | Priority set on the wrong track/release, or API edit not committed |
| Prompt appears in tests but not on device | The test injects a fake gateway; real builds need Play distribution |
| Mandatory prompt after airplane mode | Fresh cached policy (≤72 h). After repeated failures a bypass appears; it expires after 72 h |
| Dialog while an emergency light is on | Should not happen; report it. The gate checks `activeLight` before showing |
| iOS shows no update row action | Expected: the App Store manages iOS updates; the row is informational unless `APP_STORE_ID` is configured |

## 13. Features that require Play distribution

The following cannot be exercised outside Google Play:

- `checkForUpdate` returning real availability/priority.
- Immediate and flexible Play flows, including user cancellation.
- `completeFlexibleUpdate` installation.
- The `installUpdateListener` status stream.
- Priority-based mandatory/recommended behavior set through the Developer API.

The domain policy, cache, throttling, dialogs, and failure handling are fully
covered by automated tests using fakes.

## 14. Validation commands

```bash
dart format .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release   # only with android/key.properties configured
```

If release signing is not configured, the release bundle is unsigned and must
not be uploaded to Play. See `docs/release/release_checklist.md`.

## 15. Known limitations

- No byte-level flexible download progress (the Play API does not expose it).
- No custom remote release notes; the dialog shows version/build information
  only. Play may display its own release notes in its update UI.
- App Store updates are outside the app's control; iOS only gets a store link
  when a numeric App Store id is configured.
- The minimum supported version is compiled into the app and only changes with
  a new release.
- Play priority changes propagate at Play's pace; staged rollouts may delay
  availability.
- A user who installed from outside Play cannot receive in-app updates and will
  not be force-locked by this system.
