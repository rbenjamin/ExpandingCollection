
Trying to create a UICollectionViewCell that expands and contracts.  I know I can do this with UIHostingConfiguration and SwiftUI,
which I have (working) in a different project, but want to do this with UICollectionViewCell if possible -- after viewing
Session 10068: What's new in UIKit (WWDC22).

I figured setting collectionView.selfSizingInvalidation = .enabledIncludingConstraints would be enough, after changing constraints in
cell, to do this automatically.  Perhaps I'm misunderstanding the process.

Also tried calling invalidateIntrinsicContentSize() on the cell and cell.contentView, with no luck.
