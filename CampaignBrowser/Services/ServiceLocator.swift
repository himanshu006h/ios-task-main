import Foundation


class ServiceLocator {
    static let instance: ServiceLocator = ServiceLocator()

    lazy var imageService: ImageService = ImageService()

    lazy var networkingService = NetworkingService(urlSession: URLSession.shared)
}
