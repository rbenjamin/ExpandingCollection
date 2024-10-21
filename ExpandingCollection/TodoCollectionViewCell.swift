//
//  TodoCollectionViewCell.swift
//  TodoApp
//
//  Created by Ben Davis on 10/9/24.
//

import Foundation
import UIKit
import SwiftData
import SwiftUI



class TodoCollectionViewCell: UICollectionViewListCell {
    var task: Task?
    var selectedTask: Task?
    {
        didSet {
            if self.selectedTask != nil && self.selectedTask != self.task {
                showOverlayButton()
            }
            else {
                hideOverlayButton()
            }
        }
    }
    var overlayButton = UIButton(type: .custom)
    var overlayActive = false
    
    static let identifer = "kMosaicCollectionViewCell"
    
    let secondRowHeightID = "CellRowTwoHeightAnchor"
    let secondRowBottomID = "CellRowTwoBottomAnchor"

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
        
        NotificationCenter.default.addObserver(self, selector: #selector(cellExpanded(_ :)), name: .AutoCollapsingOpeningRowID, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(collapseAll(_ :)), name: .AutoCollapsingRowsCollapseAll, object: nil)

    }
    required init?(coder: NSCoder) {
        fatalError()
    }

    
    var expanded: Bool = false
    var starred: Bool = false
    var rectOne = UIView()
    var rectTwo = UIView()

    
    var secondRowHeightConstraint: NSLayoutConstraint?

    @objc
    func collapseAll(_ notification: Notification) {
        self.hideOverlayButton()
        self.expanded = false
        
        self.secondRowHeightConstraint?.constant = 14.0

        UIView.animate(withDuration: 0.20) {
            self.contentView.layoutIfNeeded()
        }

    }

    
    @objc
    func cellExpanded(_ notification: Notification) {
        guard let expandedTask = notification.object as? Task else {
            print("Cannot allocate notification.object as? Task")
            return
        }
        
        if expandedTask != self.task {
            self.expanded = false
            self.showOverlayButton()
            
            self.secondRowHeightConstraint?.constant = 14.0

            UIView.animate(withDuration: 0.20) {
                self.contentView.layoutIfNeeded()
            }
//            self.contentView.setNeedsDisplay()
//            self.contentView.setNeedsLayout()
//            self.contentView.invalidateIntrinsicContentSize()
            
        }
        else {
            self.expanded = true
            self.hideOverlayButton()
            self.secondRowHeightConstraint?.constant = 120

            UIView.animate(withDuration: 0.20) {
                self.contentView.layoutIfNeeded()
            }
            
//            self.invalidateIntrinsicContentSize()
            
        }
    }
    
    
    
    func configure() {
        self.clipsToBounds = false
        self.autoresizesSubviews = true
        
        
        overlayButton.backgroundColor = self.overlayActive ? UIColor.red : UIColor.green
        overlayButton.layer.opacity = 0.20
        overlayButton.isEnabled = self.overlayActive ? true : false
        overlayButton.addTarget(self, action: #selector(overlayTapped(id: )), for: .touchUpInside)
        overlayButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.contentView.addSubview(overlayButton)


        self.contentView.sendSubviewToBack(overlayButton)
        
        // RECT ONE
        self.rectOne.backgroundColor = .red
        
        self.rectOne.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(self.rectOne)
        
        self.rectOne.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20).isActive = true
        self.rectOne.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -20).isActive = true
        self.rectOne.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8).isActive = true
     
        self.secondRowHeightConstraint = self.rectOne.heightAnchor.constraint(equalToConstant: 14)
        self.secondRowHeightConstraint?.isActive = true

    }
    
    
    @objc
    public func overlayTapped(id: UIButton) {
        self.selectedTask = nil
        NotificationCenter.default.post(name: .AutoCollapsingRowsCollapseAll, object: nil)
        self.overlayActive = false
        self.contentView.sendSubviewToBack(self.overlayButton)


    }
    
    public func showOverlayButton() {
        self.overlayButton.isEnabled = true
        self.overlayButton.backgroundColor = UIColor.red
        self.contentView.bringSubviewToFront(self.overlayButton)
        self.overlayActive = true

    }
    
    public func hideOverlayButton() {
        self.overlayButton.isEnabled = false
        self.overlayButton.backgroundColor = UIColor.green
        self.contentView.sendSubviewToBack(self.overlayButton)
        self.overlayActive = false
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    
   
}
