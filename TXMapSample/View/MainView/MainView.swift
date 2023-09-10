//
//  MainView.swift
//  TXMapSample
//
//  Created by 井上晴稀 on 2023/09/10.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        MainMapView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
