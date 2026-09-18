/// Maps SPA tab index → CI4 `designation.rolls` module keys
/// (see Designation::$aMenu in the PHP app).
class TabAccess {
  static const modules = [
    'Dashboard', // 0
    'AdminSetup', // 1 — Employee lives under AdminSetup
    'Performance', // 2
    'Leave', // 3
    'HiringProcess', // 4
    'Payroll', // 5
  ];

  static String moduleFor(int tab) =>
      modules[tab.clamp(0, modules.length - 1)];
}
