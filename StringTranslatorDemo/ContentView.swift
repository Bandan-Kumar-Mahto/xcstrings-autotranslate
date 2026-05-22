//
//  ContentView.swift
//  StringTranslatorDemo
//
//  Created by iOS Department on 20/05/26.
//

import SwiftUI


// MARK: Content View
struct ContentView: View {

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(.alert)
            myButton(text: "Some String")
        }
        .padding()
    }
    
    @ViewBuilder
    func myButton(text: String) -> some View {
        Button(.otherKey(someThing: "")) {
            
        }
    }
}

#Preview {
    ContentView()
}
