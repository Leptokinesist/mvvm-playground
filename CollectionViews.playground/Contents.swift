//: A UIKit based Playground for presenting user interface
import UIKit
import PlaygroundSupport

class MyCollectionViewCell: UICollectionViewCell {
    let postTitle = UILabel()
    let postDescription = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        postTitle.translatesAutoresizingMaskIntoConstraints = false
        postDescription.translatesAutoresizingMaskIntoConstraints = false
        
        postTitle.backgroundColor = .green
        postTitle.textAlignment = .center
        
        postDescription.backgroundColor = .blue
        postDescription.textAlignment = .center
        postDescription.textColor = .green
        
        contentView.addSubview(postTitle)
        contentView.addSubview(postDescription)
        
        let bindings = ["title": postTitle, "description": postDescription]
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[title(69)][description]-|", options: [], metrics: nil, views: bindings)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[title]-|", options: [], metrics: nil, views: bindings)
         constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[description]-|", options: [], metrics: nil, views: bindings)
        contentView.addConstraints(constraints)
        NSLayoutConstraint.activate(constraints)
    }
}

class MyViewController: UICollectionViewController {
    lazy var activityIndicator: UIActivityIndicatorView = { [unowned self] in
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .gray
        indicator.hidesWhenStopped = true
        indicator.center = self.view.center
        indicator.layer.zPosition = 1
        self.view.insertSubview(indicator, aboveSubview: self.collectionView!)
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        return indicator
    }()
    
    let titleView = UILabel()
    var viewModel: ChannelViewModel
    
    init(collectionViewLayout layout: UICollectionViewLayout, viewModel: ChannelViewModel) {
        self.viewModel = viewModel
        super.init(collectionViewLayout: layout)
        
        self.viewModel.updateCallback = { [unowned self] (providedVM) in
            if self.viewModel.showLoading {
                self.activityIndicator.startAnimating()
                print("YEP")
            } else {
                self.activityIndicator.stopAnimating()
                print("NOPE")
            }
            self.titleView.text = providedVM.title
            self.collectionView?.reloadData()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: collectionView!.bounds.width, height: 150)
        self.collectionView?.backgroundColor = .white
        self.collectionView?.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: "PlayCell")
        activityIndicator.startAnimating()
        self.collectionView?.dataSource = self
        
        titleView.text = "YOOOOO"
        titleView.textAlignment = .center
        
        updateViewConstraints()
        self.viewModel.loadMorePosts()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        // collectionView!.translatesAutoresizingMaskIntoConstraints = false
        let bindings = ["collectionView": collectionView!, "title": titleView] as [String : Any]
        view.addSubview(titleView)
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[title(50)]-[collectionView]|", options: [], metrics: nil, views: bindings)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[title]-|", options: [], metrics: nil, views: bindings)
        view.addConstraints(constraints)
        NSLayoutConstraint.activate(constraints)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let items = viewModel.posts.count
        print(items)
        return items
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayCell", for: indexPath) as! MyCollectionViewCell
        cell.backgroundColor = .gray
        cell.postTitle.text = viewModel.posts[indexPath.item].title
        cell.postDescription.text = viewModel.posts[indexPath.item].description
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedPost(index: indexPath.item)
    }
}

struct PostViewModel {
    let title: String
    let description: String
}

class ChannelViewModel {
    var title: String
    var posts: [PostViewModel]
    private var isLoadingMorePosts: Bool = false
    var showLoading: Bool {
        return isLoadingMorePosts && !modelController.isFullyFetched
    }
    var modelController: ChannelModelController!
    var updateCallback: ((ChannelViewModel) -> Void)?
    
    init(title: String, posts: [PostViewModel] = []) {
        self.title = title
        self.posts = posts
    }
    
    func selectedPost(index: Int) {
        if index >= posts.count - 1 {
            loadMorePosts()
        }
    }
    
    func loadMorePosts() {
        isLoadingMorePosts = true
        updateCallback?(self)
        modelController.getNextPostPage { (postsVM, isLastPage) in
            self.isLoadingMorePosts = false
            self.posts.append(contentsOf: postsVM)
            self.updateCallback?(self)
        }
    }
}

class ChannelModelController {
    var viewModel: ChannelViewModel
    private let mockDatabase: [(String, String)] = [ ("Post Title 1", "Description 1"),
                                                     ("Post Title 2", "Description 2"),
                                                     ("Post Title 3", "Description 3"),
                                                     ("Post Title 4", "Description 4"),
                                                     ("Post Title 5", "Description 5"),
                                                     ("Post Title 6", "Description 6"),
                                                     ("Post Title 7", "Description 7"),
                                                     ("Post Title 8", "Description 8"),
                                                     ("Post Title 9", "Description 9"),
                                                     ("Post Title 10", "Description 10"),
                                                     ("Post Title 11", "Description 11") ]
    private var pageCount = 0
    private let pageSize = 2
    var isFullyFetched = false
    
    init() {
        viewModel = ChannelViewModel(title: "Testing Channel")
        viewModel.modelController = self
    }
    
    func getNextPostPage(completion: @escaping ([PostViewModel], Bool) -> Void) {
        let endIndex = (pageCount+1)*pageSize
        let isLastPage = endIndex >= mockDatabase.count
        
        let newResults = mockDatabase[pageCount*pageSize..<min(endIndex, mockDatabase.count)]
        
        if !isLastPage {
            pageCount += 1
        }
        
        isFullyFetched = isLastPage
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            completion(newResults.map({ PostViewModel(title: $0.0, description: $0.1) }), isLastPage)
        }
    }
}










let modelController = ChannelModelController()
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController(collectionViewLayout: UICollectionViewFlowLayout(), viewModel: modelController.viewModel)
