import Foundation
import UIKit

private final class WorkoutSession {
    var onTick: (() -> Void)?
    private(set) var tickCount = 0

    func startRetainCycleScenario() {
        // Intentional leak: strong self capture in stored closure forms a cycle.
        onTick = {
            self.tickCount += 1
        }
    }

    func startFixedScenario() {
        onTick = { [weak self] in
            self?.tickCount += 1
        }
    }

    func stop() {
        onTick = nil
    }
}

@MainActor
final class MemoryIssuePlaygroundViewModel: TrackedViewModel {
    @Published private(set) var retainCycleStatus = "Idle"
    @Published private(set) var growthStatus = "Idle"
    @Published private(set) var imageStatus = "Idle"
    @Published private(set) var cacheStatus = "Idle"

    private var leakedSession: WorkoutSession?
    private var growthTask: Task<Void, Never>?
    private var growingBytes: [Data] = []
    private var demoCache = LRUCache<Int, Data>(capacity: 20)
    private var warningObserver: NSObjectProtocol?

    init() {
        super.init(typeName: String(describing: MemoryIssuePlaygroundViewModel.self))

        warningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.evictCacheOnMemoryWarning()
            }
        }
    }

    deinit {
        if let warningObserver {
            NotificationCenter.default.removeObserver(warningObserver)
        }
    }

    func startRetainCycle(broken: Bool) {
        let session = WorkoutSession()
        if broken {
            session.startRetainCycleScenario()
            leakedSession = session
            retainCycleStatus = "Broken scenario started (leak expected)"
        } else {
            session.startFixedScenario()
            leakedSession = session
            retainCycleStatus = "Fixed scenario started (releasable)"
        }
    }

    func stopRetainCycle() {
        leakedSession?.stop()
        leakedSession = nil
        retainCycleStatus = "Stopped"
    }

    func startMemoryGrowth() {
        guard growthTask == nil else { return }

        growthTask = Task {
            while !Task.isCancelled {
                // Intentional growth: appending and never trimming mimics a runaway cache/buffer.
                growingBytes.append(Data(repeating: 0xAA, count: 1_000_000))
                growthStatus = "Leaked buffers: \(growingBytes.count) MB"
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    func stopMemoryGrowth() {
        growthTask?.cancel()
        growthTask = nil
        growingBytes.removeAll()
        growthStatus = "Stopped and cleared"
    }

    func runImageSpikeScenario(useDownsampling: Bool) {
        guard let imageData = makeSyntheticJPEG(size: CGSize(width: 4000, height: 4000)) else {
            imageStatus = "Could not generate test image"
            return
        }

        if useDownsampling {
            var thumbnails: [UIImage] = []
            for _ in 0..<25 {
                if let image = ImageDownsampler.downsample(imageData: imageData, to: CGSize(width: 150, height: 150)) {
                    thumbnails.append(image)
                }
            }
            imageStatus = "Downsampled decode x\(thumbnails.count)"
        } else {
            var fullImages: [UIImage] = []
            for _ in 0..<25 {
                if let image = ImageDownsampler.decodeFullResolution(imageData: imageData) {
                    fullImages.append(image)
                }
            }
            imageStatus = "Full-resolution decode x\(fullImages.count)"
        }
    }

    func fillCache() {
        Task {
            for index in 0..<40 {
                await demoCache.setValue(Data(repeating: 0xFF, count: 500_000), for: index)
            }
            let count = await demoCache.count()
            cacheStatus = "Cache filled. Live keys after eviction: \(count)"
        }
    }

    func simulateMemoryWarning() {
        Task {
            await evictCacheOnMemoryWarning()
        }
    }

    private func evictCacheOnMemoryWarning() async {
        await demoCache.removeAll()
        cacheStatus = "Cache evicted after memory warning"
    }

    private func makeSyntheticJPEG(size: CGSize) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setStroke()
            context.cgContext.setLineWidth(8)
            context.cgContext.stroke(CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40))
        }

        return image.jpegData(compressionQuality: 0.9)
    }
}
