import Foundation
import UIKit

final class PFController: UIViewController {
    private enum Constant {
        static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    }

    /// Stack container view
    private let stackView = UIStackView(axis: .vertical) {
        $0.axis = .vertical
    }
    private let topPart = UIView()
    private let bottomPart = UIView()
    private let searchBar = UISearchBar()
    private let baseListTable = UITableView()
    private let topButtonsStack = UIStackView()

    private let presentationStyleSelectorView = PFPresentationStyleSelectorView(.list)
    private var presentationPagerContainer = UIStackView()
    private let serverSelector = PFServerSelectorView()
    private var nestedView = PFNestedListView(Pathfinder.shared.getGroupedRequests())
    private var dataList: [UrlSpec] = Pathfinder.shared.getAllUrls()
    private lazy var filteredList = dataList
    private var bottomStackConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        view.backgroundColor = .white
        configureLayout()
        setupTable()
        serverSelector.onSelected = { server in
            Pathfinder.shared.changeEnvironment(to: server)
        }
        searchBar.delegate = self

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func refreshData() {
        nestedView     = PFNestedListView(Pathfinder.shared.getGroupedRequests())
        dataList       = Pathfinder.shared.getAllUrls()
        filteredList   = dataList
        searchBar.text = ""

        nestedView.onSelectQuery = { [weak self] query in
            self?.present(PFQueryEditorController(config: query), animated: true)
        }

        handlePresentationStyleChange(to: .list)
        baseListTable.reloadData()
    }

    /// Setting up controller layout
    private func configureLayout() {
        stackView.embedIn(view)

        bottomStackConstraint = stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomStackConstraint?.isActive = true

        nestedView.onSelectQuery = { [weak self] query in
            self?.present(PFQueryEditorController(config: query), animated: true)
        }

        presentationStyleSelectorView.onSelect = { [weak self] style in
            self?.handlePresentationStyleChange(to: style)
        }

        stackView.addArrangedSubviews(
            configureTopButtons(),
            searchBar,
            configureBottom(),
            serverSelector,
            presentationStyleSelectorView,
            presentationPagerContainer
        )

        presentationPagerContainer.addArrangedSubviews(baseListTable)
    }

    private func setupTable() {
        baseListTable.dataSource = self
        baseListTable.delegate = self
        baseListTable.keyboardDismissMode = .interactive
        baseListTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private func handlePresentationStyleChange(to style: PFQueriesPresentationStyle) {
        presentationStyleSelectorView.setSelection(style)

        switch style {
        case .list:
            presentationPagerContainer.arrangedSubviews.forEach { subview in
                UIView.animate(withDuration: 0.15, animations: {
                    subview.alpha = 0
                }, completion: { _ in
                    self.presentationPagerContainer.removeArrangedSubview(subview)
                    subview.removeFromSuperview()
                    subview.alpha = 1
                    self.baseListTable.alpha = 0
                    self.presentationPagerContainer.addArrangedSubview(self.baseListTable)
                    UIView.animate(withDuration: 0.3) {
                        self.baseListTable.alpha = 1
                    }
                })
            }

        case .nestedList:
            presentationPagerContainer.arrangedSubviews.forEach { subview in
                UIView.animate(withDuration: 0.15, animations: {
                    subview.alpha = 0
                }, completion: { _ in
                    self.presentationPagerContainer.removeArrangedSubview(subview)
                    subview.removeFromSuperview()
                    subview.alpha = 1
                    self.nestedView.alpha = 0
                    self.presentationPagerContainer.addArrangedSubview(self.nestedView)
                    UIView.animate(withDuration: 0.3) {
                        self.nestedView.alpha = 1
                    }
                })
            }
        }
    }

    /// Configuring close button
    private func configureTopButtons() -> UIView {
        let topContainer = UIView()
        topButtonsStack.axis = .horizontal
        let flexibleSpacer = UIView()
        flexibleSpacer.translatesAutoresizingMaskIntoConstraints = false
        flexibleSpacer.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        flexibleSpacer.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1), for: .vertical)
        flexibleSpacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
        flexibleSpacer.height(56)
        topButtonsStack.addArrangedSubview(flexibleSpacer)

        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.titleLabel?.textAlignment = .right
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.height(56)
        topButtonsStack.addArrangedSubview(closeButton)
        topButtonsStack.embedIn(topContainer, hInset: 24)
        return topContainer
    }

    private func configureBottom() -> UIView {
        return UIView {
            $0.backgroundColor = .white
        }
    }
}

// MARK: - UITableView Delegate
extension PFController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = filteredList[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        let queryModel = filteredList[indexPath.row]
        let controller = PFQueryEditorController(config: queryModel)
        controller.onClose = { [weak self] in
            self?.refreshData()
        }
        present(controller, animated: true)
    }
}

// MARK: - UISearchBar Delegate
extension PFController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText != "" else {
            filteredList = dataList
            baseListTable.reloadData()
            return
        }
        handlePresentationStyleChange(to: .list)
        let lowerSearchText   = searchText.lowercased()
        let nameFilteredList  = dataList.filter { $0.name.lowercased().contains(lowerSearchText) }
        let tagFilteredList   = dataList.filter { $0.tag.lowercased().contains(lowerSearchText) }
        let tagFilteredExcludingOccurrences = tagFilteredList.filter { !nameFilteredList.contains($0) }
        filteredList = nameFilteredList + tagFilteredExcludingOccurrences
        baseListTable.reloadData()
    }
}

// MARK: - Keyboard Handling
extension PFController {
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            baseListTable.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        baseListTable.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
