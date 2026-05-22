//
//  ContentView.swift
//  StringTranslatorDemo
//
//  Created by iOS Department on 20/05/26.
//

import SwiftUI



struct data {
    var name: String
    var surname: String
    var age: String
    var jobrole: String
}

// MARK: Content View
struct ContentView: View {
    let varriable: [data] = [
        .init(name: "Moksh", surname: "Suthar", age: "", jobrole: "Developer")
    ]
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(varriable.first?.name.description ?? "")
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
