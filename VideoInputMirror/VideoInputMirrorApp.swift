//
//  VideoInputMirrorApp.swift
//  VideoInputMirror
//
//  Created by Mike Mahon on 2/4/24.
//

import SwiftUI

@main
struct VideoInputMirrorApp: App {
    @StateObject var viewModel = ContentViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }.commands {
            CommandMenu("Camera") {
                ForEach(viewModel.availableCameras.indices, id: \.self) { index in
                    let name = viewModel.availableCameras[index].localizedName
                    
                    Button {
                        viewModel.selectedCameraIndex = index
                    } label: {
                        HStack {
                            Text(name)
                            Spacer()
                            if viewModel.selectedCameraIndex == index {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}
