//
//  ContentView.swift
//  ExpandingCollection
//
//  Created by Ben Davis on 10/10/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTask: Task?
    @State private var editing: Bool = false
    
    var body: some View {
        NavigationStack {
            TodoCollectionView(title: "Tasks", selected: $selectedTask)
                
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                            .simultaneousGesture(TapGesture().onEnded({ _ in
                                self.setEditing()
                            }))
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
        }
    }
    private func setEditing() {
        self.editing.toggle()
        NotificationCenter.default.post(name: .TaskListEditing, object: nil, userInfo: [NotificationKeys.isEditing : self.editing])

    }
    
    private func addItem() {
        NotificationCenter.default.post(name: NSNotification.Name.TaskListNew, object: nil, userInfo: nil)

    }

}

#Preview {
    ContentView()
}
