import Foundation
import RxSwift
import RxCocoa


/**
 The requests which are handled by the networking service.
 */
protocol Request {

    /** The response type when the response was parsed by the application. */
    associatedtype ResponseData: Decodable

    /** The URL that should be requested. */
    var url: URL { get }
}


/**
Responsible for handling the networking communication.
*/
class NetworkingService {

    /** The URLSession instance which is used to handle the request. */
    private let urlSession: URLSession

    private let jsonDecoder = JSONDecoder()

    /**
     Designated initializer.

     - Parameter urlSession: The URLSession instance which is used to handle the request.
     */
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    /**
     Creates a cold observable from the given request.
     */
    func createObservableResponse<R: Request>(request: R) -> Observable<R.ResponseData> {
        return urlSession.rx
            .data(request: URLRequest(url: request.url))
            .map { [jsonDecoder] rawData in
                try jsonDecoder.decode(R.ResponseData.self, from: rawData)
            }
    }
}

/**
The error which is thrown when the server responded with an unexpected response.
*/
struct UnexpectedResponse: Error {

/** The server's response. */
    let response: Any
}


/**
The request which fetches the list of campaigns.
*/
struct CampaignListingRequest: Request {
    typealias ResponseData = CampaignList

    var url: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://westwing-home-and-living.github.io/ios-task/campaigns.json")!
    }
}
