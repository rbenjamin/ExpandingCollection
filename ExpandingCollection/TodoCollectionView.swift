//
//  TodoCollectionView.swift
//  TodoApp
//
//  Created by Ben Davis on 10/7/24.
//

import Foundation
import UIKit
import SwiftUI
import Combine


extension NSNotification.Name {
    public static var AutoCollapsingRowsUpdateState = NSNotification.Name("AutoCollapsingRowsUpdateState")
    public static var AutoCollapsingRowsCollapseAll = NSNotification.Name("AutoCollapsingRowsCollapseAll")
    public static var AutoCollapsingOpeningRowID = NSNotification.Name("AutoCollapsingOpeningRowID")
    public static var AutoCollapsingClosingRowID = NSNotification.Name("AutoCollapsingClosingRowID")
    public static var TasksListDidChange = NSNotification.Name("tasksListDidChange")
    public static var TaskListEditing = NSNotification.Name("TaskListEditing")
    public static var TaskListNew = NSNotification.Name("TaskListNew")
    

}

enum NotificationKeys {
    case selectedTaskIDs
    case isEditing
    case newTask
}

struct Task: Equatable, Hashable {
    let id = UUID()
    var title: String?
    var starred: Bool = false
    
    public static func ==(lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct TodoCollectionView: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = TodoCollectionViewController

    
    init() {
        
    }
        
    func makeUIViewController(context: Context) -> TodoCollectionViewController {
        let controller = TodoCollectionViewController()
        return controller
    }
    func updateUIViewController(_ collectionController: TodoCollectionViewController, context: Context) {
        
    }
}

#Preview {
    TodoCollectionView()
}

class TodoCollectionViewController: UIViewController {
    
    
    var selected: Task?
    
    enum Section {
        case main
    }
    
    
    var cancellables = [AnyCancellable]()
    
    var tasks: [Section : [Task]] = [.main : [
        Task(title: "Item One", starred: false),
        Task(title: "Item Two", starred: false)
    ]]
    
        
    var dataSource: UICollectionViewDiffableDataSource<Section, Task>! = nil
    var collectionView: UICollectionView! = nil
    
    
     init() {
         
         
         super.init(nibName: nil, bundle: nil)
         
         /// Sent from SwiftUI side, when the EditButton is tapped
         NotificationCenter.default.addObserver(
             self,
             selector: #selector(editingNotification(_ :)),
             name: .TaskListEditing,
             object: nil
         )
         /// Sent from SwiftUI side, ensures we can add new tasks
         NotificationCenter.default.addObserver(
             self,
             selector: #selector(newTask(_ :)),
             name: .TaskListNew,
             object: nil
         )
        /// Sent from CollectionViewCell, once the overlay button is tapped
         NotificationCenter.default.addObserver(
             self,
             selector: #selector(dismissAll(_ :)),
             name: .AutoCollapsingRowsCollapseAll,
             object: nil
         )
         
         
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        configureHierarchy()
        configureDataSource()
    }
    
    /// Loads the initial list model for the collection view

    
}

extension TodoCollectionViewController {
    // MARK: - List -
    private func createLayout() -> UICollectionViewLayout {
        
/// List Configuation with Swipe-To-Delete
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        
        /// Add swipe-to-delete
        config.leadingSwipeActionsConfigurationProvider = { indexPath in
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completion in
               
                
                self?.deleteTask(indexPath: indexPath)
                
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        
        return UICollectionViewCompositionalLayout.list(using: config)
    }
}

extension TodoCollectionViewController {
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        ])
        
        collectionView.selfSizingInvalidation = .enabledIncludingConstraints
        
        /// background button for list -- allows for collapsing table rows when one row is expanded
        let backgroundButton = UIButton(type: .custom)
        backgroundButton.addTarget(self, action: #selector(deselectAll(id:)), for: .touchUpInside)
        backgroundButton.backgroundColor = UIColor.systemGroupedBackground
        backgroundButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundView = backgroundButton
        
        collectionView.delegate = self
    }
    
    private func configureDataSource() {
        
        let cellRegistration = UICollectionView.CellRegistration<TodoCollectionViewCell, Task> { (cell, indexPath, item) in

            
            cell.task = item
            cell.backgroundColor = .white
            cell.accessories = [.delete(displayed: .whenEditing, options: UICellAccessory.DeleteOptions(), actionHandler: {
                self.deleteTask(indexPath: indexPath)
        
            })]
 
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Task>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Task) -> TodoCollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        /// Load initial tasks
        applyInitialBackingStore()
    }
    
    // MARK: - View Reloads -
    /// These reloads occur when deleting, moving, adding new items.
    func applyInitialBackingStore(animated: Bool = false) {
        
        for (section, items) in self.tasks {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Task>()
            sectionSnapshot.append(items)
            dataSource.apply(sectionSnapshot, to: section, animatingDifferences: animated)
        }
    }
    
    func applySnapshotsFromBackingStore(animated: Bool = false) {
        
        for (section, items) in self.tasks {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Task>()
            sectionSnapshot.append(items)
            dataSource.apply(sectionSnapshot, to: section, animatingDifferences: animated)
        }
    }
    
    // MARK: - Delete Action -
    private func deleteTask(indexPath: IndexPath) {
        guard let toDelete = self.tasks[.main]?[indexPath.item] as? Task else {
            return
        }
        self.tasks[.main]?.remove(at: indexPath.item)
        applySnapshotsFromBackingStore(animated: true)

    }
    
    /// Our only button -- allows the user to tap outside the rows in the list to `dismiss` the current Task
    @objc
    func deselectAll(id: UIButton) {
        self.selected = nil
        NotificationCenter.default.post(name: .AutoCollapsingRowsCollapseAll, object: nil)
    }


    
    
    
}
// MARK: - UICollectionViewDelegate -

extension TodoCollectionViewController: UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let cell = collectionView.cellForItem(at: indexPath) as! TodoCollectionViewCell
        if cell.expanded == true {
            return false
        }
        return true
        
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! TodoCollectionViewCell
        cell.expanded = true
        let task = cell.task
        
        NotificationCenter.default.post(name: .AutoCollapsingOpeningRowID, object: task, userInfo: nil)
        collectionView.deselectItem(at: indexPath, animated: true)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

    }
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool  {
        return true
    }
    
    
}

// MARK: - Notifications -
extension TodoCollectionViewController {
    
    @objc
    func editingNotification(_ notification: Notification) {
        
        guard notification.name == .TaskListEditing,
            let userInfo = notification.userInfo,
            let editing = userInfo[NotificationKeys.isEditing] as? Bool
        else {
            return
        }

        self.collectionView.isEditing = editing
    }
    
    @objc
    public func dismissAll(_ notification: Notification) {
        for indexPath in collectionView.indexPathsForVisibleItems {
            if let cell = collectionView.cellForItem(at: indexPath) as? TodoCollectionViewCell {
                cell.selectedTask = nil
            }
        }
    }
    
    @objc
    private func newTask(_ notification: Notification) {
        guard notification.name == .TaskListNew else {
            return
        }
      
        let task = Task()
//        container?.mainContext.insert(task)
        self.tasks[.main]?.append(task)
        applySnapshotsFromBackingStore(animated: true)
    }
    
}
