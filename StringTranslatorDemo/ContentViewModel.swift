//
//  ContentViewModel.swift
//  StringTranslatorDemo
//
//  Created by Bandan's MacBook Pro on 17/06/26.
//

import Combine
import Foundation

class ContentViewModel: ObservableObject {

    var someList: [String] = ["1 Misisipi", "2 Mississippi", "3 Mississippi", "Some other string", "Test String", "This is the context", "You my pumpkin pumpkin", "Hello Honey Bunny"]
}


enum SomeEnum: String {
    case value


    func fetLocLcaliseTwexy() -> String {
        switch self {
        case .value:
            L("Hello")
        }
    }
}
