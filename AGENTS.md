# Aktiviti , project rules

Product: native macOS 14+ menu bar app, Swift + SwiftUI/AppKit.
Shows live CPU% and RAM% in the menu bar, and a dashboard window with
disk usage, RAM usage, and the top RAM-consuming processes.

Hard rules:
- No third-party dependencies. No database. No caching: data is fetched
  fresh whenever the dashboard opens. No networking, no analytics.
- NEVER edit .pbxproj files. The Xcode project is generated from
  project.yml with `xcodegen generate`. Change project.yml, then regenerate.
- The app is NOT sandboxed (ENABLE_APP_SANDBOX = NO), or the process
  list will be empty. Info.plist: LSUIElement = YES (no Dock icon).
- Signing: ad-hoc / "Sign to Run Locally" (CODE_SIGN_IDENTITY = "-").
- Metrics code lives in a local Swift package at Packages/SystemMetrics
  with unit tests. The app imports it and contains no metrics logic.
- Build command (must pass before you say a task is done):
  xcodegen generate && xcodebuild -project CacheAnalyzer.xcodeproj \
    -scheme CacheAnalyzer -configuration Debug build
- Do only the stage you were asked to do. When finished, STOP, show the
  build output, and summarize what you did. Do not start the next stage.
- Out of scope for now: widgets, cache scanning/cleanup, scheduler,
  SQLite, notifications.
