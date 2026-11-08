/// Pure start rule for monetization. It is kept separate from the widget layer
/// so the "mandatory update wins" ordering can be tested directly.
bool canStartMonetization({
  required bool updateSupported,
  required bool sawUpdateCheck,
  required bool updateCheckInProgress,
  required bool mandatoryUpdateActive,
  required bool lightActive,
  required bool essentialInitialization,
  required bool appResumed,
  bool allowBeforeFirstCheck = false,
}) {
  if (!appResumed || lightActive || essentialInitialization) return false;
  if (mandatoryUpdateActive || updateCheckInProgress) return false;
  if (updateSupported && !sawUpdateCheck && !allowBeforeFirstCheck) {
    return false;
  }
  return true;
}
