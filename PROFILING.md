# PulseLog Profiling Guide

This guide covers how to profile PulseLog with Instruments and map results to the built-in debug scenarios.

## 1. Attach Instruments

1. Run PulseLog on device or simulator from Xcode.
2. In Xcode: `Product > Profile`.
3. Select the template based on scenario:
   - `Points of Interest` for API/signpost timelines.
   - `Allocations` for memory growth and image decode spikes.
   - `Leaks` for retain-cycle detection.
   - `Time Profiler` for SwiftUI rendering overhead.

## 2. API call intervals (Points of Interest)

PulseLog emits signposts from `APIClient` with interval name `APIRequest`.

What to check:
- Each request should show a clear begin/end interval.
- Compare interval durations with and without Network Simulator latency.
- Verify retries: failing requests should show multiple intervals for one logical fetch.
- Correlate request spikes with UI actions (exercise list refresh/pagination).

Additional signposted intervals:
- `SwiftDataFetch` for repository fetches.
- `ImageDecode` for downsampled/full-resolution decode paths.

## 3. Image spike scenario (Allocations)

Open: `Debug > Memory Issue Playground`.

1. Press `Decode Full-Resolution Images`.
2. Observe Allocations:
   - Large transient/retained `UIImage` and backing bitmap memory.
   - Higher physical footprint and larger VM regions.
3. Press `Decode Downsampled Images`.
4. Compare:
   - Smaller decoded image buffers.
   - Lower sustained heap growth.
   - Shorter decode intervals in Points of Interest for `ImageDecode`.

Expected result: downsampling significantly reduces peak and retained memory.

## 4. Retain cycle detection (Leaks)

Open: `Debug > Memory Issue Playground`.

1. Enable `Broken (strong self capture)`.
2. Tap `Start Retain Cycle Scenario`.
3. Run Leaks template and capture.
4. Use leak cycles / allocation graph to locate `WorkoutSession` retained by closure.
5. Stop scenario and rerun with fixed path (`Broken` toggle off).

Expected result:
- Broken path keeps session alive.
- Fixed path (`[weak self]`) allows deallocation.

## 5. SwiftData fetch visibility (Points of Interest)

Use normal app flows (Home, Workouts, Progress).

What to inspect:
- `SwiftDataFetch` intervals around page loads and dashboard refresh.
- Check interval duration growth as data volume increases.
- Confirm pagination reduces per-fetch cost for long workout histories.

## 6. SwiftUI render stressor (Time Profiler)

Open: `Debug > SwiftUI Render Stressor`.

Scenarios:
- `Broken: @StateObject in row` ON.
- `Broken: @StateObject in row` OFF (fixed).
- Toggle `LazyVStack` vs `VStack`.

What to inspect in Time Profiler:
- `SwiftUI` layout/body computation stacks for row views.
- Broken mode should show more row model allocations and extra update overhead.
- `VStack` mode should show heavier upfront work vs `LazyVStack`.

In-app indicators:
- `Broken VM initializations` counter rises quickly in broken mode.
- Per-row render counters make update frequency differences visible directly in UI.

## 7. Memory dashboard interpretation

Open via shake gesture or `Debug > Open Memory Dashboard`.

Metrics:
- `Physical Footprint`: overall process memory pressure indicator.
- `Resident Size`: currently resident pages.
- `Peak Resident`: historical max resident size.

Thresholds:
- Yellow warning at `150 MB`.
- Red warning at `250 MB`.

Use `Export CSV` for sharing profiling sessions and plotting trends externally.
