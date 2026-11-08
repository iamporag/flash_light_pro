enum LightMode { torch, screenLight, sos, strobe, morse }

extension LightModeX on LightMode {
  bool get isSequence =>
      this == LightMode.sos ||
      this == LightMode.strobe ||
      this == LightMode.morse;
}
