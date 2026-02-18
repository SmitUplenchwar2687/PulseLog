# PulseLog

PulseLog is a SwiftUI + SwiftData personal fitness tracker with deep built-in observability for performance profiling.

## What is implemented

- Workout tracker with create/log/delete, local SwiftData persistence, and paginated history with date/type filters.
- Exercise library backed by `https://wger.de/api/v2/exercise/` with search, category filtering, pagination, `URLCache`, and custom in-memory LRU cache.
- Progress dashboard using Swift Charts for volume trends, personal records, and weekly summary.
- Profile screen with local profile storage and PhotosPicker image selection with ImageIO downsampling.
- Observability layer:
  - `OSLog` + `os_signpost` intervals for API requests, SwiftData fetches, and image decode operations.
  - ViewModel lifecycle logging to subsystem `com.pulselog.lifecycle`.
  - Live memory dashboard (shake gesture or debug menu) with 60-second sparkline and CSV export.
  - Lifecycle tracker overlay for live ViewModel count and growth warnings.
- Debug scenarios:
  - Memory issue playground (retain cycle, unbounded growth, image spike, cache eviction).
  - SwiftUI render stressor (broken/fixed property wrapper modes + `LazyVStack`/`VStack` toggle).

## Project layout

- `PulseLog/Features/`
- `PulseLog/Networking/`
- `PulseLog/Persistence/`
- `PulseLog/Observability/`
- `PulseLog/Components/`
- `PulseLog/Utilities/`

## Add to Xcode

1. Create a new iOS App project in Xcode (`iOS 17+`) named `PulseLog`.
2. Delete the default template Swift files.
3. Drag the `PulseLog/` folder from this repository into the Xcode target.
4. Ensure these frameworks are available: SwiftUI, SwiftData, Charts, PhotosUI, OSLog, ImageIO.
5. Build and run.

## Debug tools

- Debug tab is visible when `AppDebug.isDebugEnabled` is true.
- In Debug builds it is enabled by default.
- In non-debug builds it can be enabled using launch argument: `--pulselog-debug`.

See `PROFILING.md` for end-to-end Instruments workflows.
