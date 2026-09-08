//
//  ContentView.swift
//  NanoMD
//
//  Created by Siavash Bonakdar on 9/8/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: NanoMDDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(NanoMDDocument()))
}
