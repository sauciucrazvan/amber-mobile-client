# 08 - Desktop-Only Features (Not Planned)

These desktop features have no direct mobile equivalent, so they are out of scope for the core client.

| Desktop feature | Why it is out of scope |
|-----------------|------------------------|
| System tray with close-to-tray | Mobile apps do not have a tray. |
| Start on boot | Mobile apps cannot start at login. |
| Auto-updater (Electron) | The app stores handle updates. |
| Custom titlebar and window controls | Mobile uses the OS chrome. |
| Sidebar placement (left or right) | Mobile uses bottom navigation. |
| Open external links through the OS | Use the platform URL launcher if needed. |
| Developer server switcher | Excluded for now (see [07-settings.md](07-settings.md)). |

If one of these needs a mobile version later, add a new feature file rather than changing this one.
