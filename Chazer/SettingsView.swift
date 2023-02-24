//
//  SettingsView.swift
//  Chazer
//
//  Created by David Reese on 1/27/23.
//

import SwiftUI
import UIKit

struct SettingsView: View {
//    @State var showingBrowser = false
    var body: some View {
        List {
            Button {
            } label: {
                Text("Download Backup")
            }
        }.navigationTitle("Settings")
    }
    /*
    func selectFolder() {
            
            let folderChooserPoint = CGPoint(x: 0, y: 0)
            let folderChooserSize = CGSize(width: 500, height: 600)
            let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
            let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
            
            folderPicker.canChooseDirectories = true
            folderPicker.canChooseFiles = true
            folderPicker.allowsMultipleSelection = true
            folderPicker.canDownloadUbiquitousContents = true
            folderPicker.canResolveUbiquitousConflicts = true
            
            folderPicker.begin { response in
                
                if response == .OK {
                    let pickedFolders = folderPicker.urls
                    
                    self.selectedFolder.getFileList(at: pickedFolders)
                }
            }
        }
    */
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
