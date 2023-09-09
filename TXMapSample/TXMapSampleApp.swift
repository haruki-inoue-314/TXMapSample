//
//  TXMapSampleApp.swift
//  TXMapSample
//
//  Created by 井上晴稀 on 2023/09/09.
//

import SwiftUI

@main
struct TXMapSampleApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
