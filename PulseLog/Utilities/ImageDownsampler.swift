import Foundation
import UIKit
import ImageIO

enum ImageDownsampler {
    static func downsample(imageData: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let interval = SignpostInterval(name: "ImageDecode", message: "downsample")
        defer { interval.end(message: "done") }

        let cfData = imageData as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }

        let maxDimension = max(pointSize.width, pointSize.height) * scale

        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            // Delayed cache avoids decoding the full-resolution image into memory up front.
            kCGImageSourceShouldCache: false,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    static func decodeFullResolution(imageData: Data) -> UIImage? {
        let interval = SignpostInterval(name: "ImageDecode", message: "full-resolution")
        defer { interval.end(message: "done") }

        return UIImage(data: imageData)
    }
}
