import Foundation


typealias CampaignList = [CampaignData]


struct CampaignData: Decodable {

    /** The campaign's unique identifier. Usually used to identify the campaign in URLs. */
    let urlKey: String

    /** The campaign's name. This is the name which is displayed to customers. */
    let name: String

    /** The campaign's description. This is the text with additional information which is displayed to customers. */
    let description: String

    /** The campaign's image. */
    let moodImage: URL

    enum CodingKeys: String, CodingKey {
        case urlKey = "url_key"
        case name
        case description
        case moodImage = "image_url"
    }
}



extension CampaignData: Hashable {
}


extension CampaignData: Equatable {
}
