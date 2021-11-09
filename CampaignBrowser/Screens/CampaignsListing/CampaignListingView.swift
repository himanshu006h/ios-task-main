import UIKit
import RxSwift

protocol CampaignsLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath , cellWidth : CGFloat ) -> CGFloat
}
/**
 The view which displays the list of campaigns. It is configured in the storyboard (Main.storyboard). The corresponding
 view controller is the `CampaignsListingViewController`.
 */
class CampaignListingView: UICollectionView {
    
    /**
     A strong reference to the view's data source. Needed because the view's dataSource property from UIKit is weak.
     */
    @IBOutlet var strongDataSource: UICollectionViewDataSource!
    var dataSourceValue: [Campaign]?
    /**
     Displays the given campaign list.
     */
    
    
    func display(campaigns: [Campaign]) {
        let campaignDataSource = ListingDataSource(campaigns: campaigns)
        dataSource = campaignDataSource
        dataSourceValue = campaigns
        strongDataSource = campaignDataSource
        let commentFlowLayout = CampaignsLayout()
        //commentFlowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        commentFlowLayout.delegate = self
        self.collectionViewLayout = commentFlowLayout
        self.contentInsetAdjustmentBehavior = .never
        //commentFlowLayout.sectionInsetReference = .fromLayoutMargins
        reloadData()
    }
    
    
    struct Campaign {
        let name: String
        let description: String
        let moodImage: Observable<UIImage>
    }
    
    /**
     All the possible cell types that are used in this collection view.
     */
    enum Cells: String {
        
        /** The cell which is used to display the loading indicator. */
        case loadingIndicatorCell
        
        /** The cell which is used to display a campaign. */
        case campaignCell
    }
}


/**
 The data source for the `CampaignsListingView` which is used to display the list of campaigns.
 */
class ListingDataSource: NSObject, UICollectionViewDataSource {
    
    /** The campaigns that need to be displayed. */
    let campaigns: [CampaignListingView.Campaign]
    
    /**
     Designated initializer.
     
     - Parameter campaign: The campaigns that need to be displayed.
     */
    init(campaigns: [CampaignListingView.Campaign]) {
        self.campaigns = campaigns
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return campaigns.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let campaign = campaigns[indexPath.item]
        let reuseIdentifier =  CampaignListingView.Cells.campaignCell.rawValue
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let campaignCell = cell as? CampaignCell {
            campaignCell.moodImage = campaign.moodImage
            campaignCell.name = campaign.name
            campaignCell.descriptionText = campaign.description
        } else {
            assertionFailure("The cell should a CampaignCell")
        }
        return cell
    }
    
}



/**
 The data source for the `CampaignsListingView` which is used while the actual contents are still loaded.
 */
class LoadingDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = CampaignListingView.Cells.loadingIndicatorCell.rawValue
        return collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                  for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}


class CampaignsLayout: UICollectionViewLayout {
    
    weak var delegate: CampaignsLayoutDelegate?
    private let numberOfColumns = 1
    private let cellPadding: CGFloat = 0
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func prepare() {
        guard cache.isEmpty == true, let collectionView = collectionView else {
            return
        }
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            // dynamic height for image
            let photoHeight = delegate?.collectionView( collectionView,
                                                        heightForPhotoAtIndexPath: indexPath , cellWidth: columnWidth) ?? 480
            let height = cellPadding * 2 + photoHeight
            let frame = CGRect(x: xOffset[column],y: yOffset[column],width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
            
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
            column = column < (numberOfColumns - 1) ? (column + 1) : 0
            
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
        
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}
//MARK: Image height calculate delegate
extension CampaignListingView: CampaignsLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath, cellWidth: CGFloat) -> CGFloat {
        guard let campaign = dataSourceValue?[indexPath.item] else { return .zero }
        let imgHeight = calculateImageHeight(imageValue: campaign.moodImage)
        let desHeight = requiredHeight(text: campaign.description, cellWidth: cellWidth, font: "Hoefler Text", size: 12)
        let titleHeight = requiredHeight(text: campaign.name, cellWidth: cellWidth, font: "Helvetica Neue Bold ", size: 17)
        return (imgHeight + desHeight + titleHeight + 16)
    }
    /**
     Calculate height for Image
     */
    func calculateImageHeight(imageValue: Observable<UIImage>) -> CGFloat {
        var aReturnValue: CGFloat = 0
        imageValue.subscribe(onNext: { image in
            let oldWidth = image.size.width
            let scaleFactor = self.frame.width / oldWidth
            aReturnValue = image.size.height * scaleFactor
        })
        .disposed(by: DisposeBag())
        return aReturnValue
    }
    /**
     Calculate height for text
     */
    func requiredHeight(text:String , cellWidth : CGFloat, font: String, size: CGFloat) -> CGFloat {
        let font = UIFont(name: font, size: size)
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: cellWidth, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
        
    }
    
    
}

