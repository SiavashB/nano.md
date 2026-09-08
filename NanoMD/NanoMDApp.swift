//
//  NanoMDApp.swift
//  NanoMD
//
//  Created by Siavash Bonakdar on 9/8/26.
//

import SwiftUI

@main
struct NanoMDApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: NanoMDDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
