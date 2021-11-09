import MapleBacon
import RxSwift
import UIKit


/**
 Responsible for downloading images.
 */
public class ImageService {

    /** The `MapleBacon` image manager instance which we're using for image fetching and caching. */
    private let imageManager = ImageManager.sharedManager

    /**
     Designated initializer.

     - Parameters:
        - maximumCacheTime:   The maximum storage time of the cached images. (Default: 1 Day)
     */
    public init(maximumCacheTime: TimeInterval = 60 * 60 * 24) {
        DiskStorage.sharedStorage.maxAge = maximumCacheTime
    }

    /**
     Get an image for the given `URL`.

     - Parameter url: The image resource url.

     - Returns: An observable `UIImage` instance.
     */
    public func getImage(url: URL) -> Observable<UIImage> {
        return Observable.create { [imageManager] observer in
            let download = imageManager.downloadImage(atUrl: url, cacheScaled: true, imageView: nil,
                                                      completion: { (imageInstance, error) in
                if let unwrappedError = error {
                    observer.onError(unwrappedError)
                }
                if let image = imageInstance?.image {
                    observer.onNext(image)
                }
            })
            return Disposables.create(with: download?.cancel ?? {})
        }
    }
}
