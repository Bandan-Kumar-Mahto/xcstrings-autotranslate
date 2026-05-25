//
//  Strings+Extensions.swift
//  StringTranslatorDemo
//
//  Created by iOS Department on 25/05/26.
//

import Foundation

// MARK: - Approach 1: Simple .localized property
//
// Wraps NSLocalizedString. Works with both Localizable.strings and .xcstrings.
// Best for UIKit where you need a plain String quickly.
//
// ❌ XCODE DOES NOT AUTO-EXTRACT KEYS when you use "key".localized.
//    The extension body calls NSLocalizedString(self, ...) where `self` is a
//    runtime value — Xcode's extractor cannot see through that at build time.
//    You must make sure the key already exists in .xcstrings (either added
//    manually, or used elsewhere in your project via a recognized API).
//
// Usage:
//   label.text = "Cancel".localized
//   label.text = "hello_key".localized
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

// MARK: - Approach 2: L() free function (Recommended for non-SwiftUI)
//
// Uses the modern LocalizedStringResource API introduced in iOS 16.
// Supports interpolation out of the box.
//
// ✅ XCODE AUTO-EXTRACTS KEYS (Xcode 15+).
//    Because the parameter type is LocalizedStringResource, the string literal
//    you pass ("Cancel", "Save", etc.) is recognized by Xcode's extractor and
//    added to Localizable.xcstrings automatically when you build.
//    This is one of the main advantages of LocalizedStringResource over plain String.
//
// Usage:
//   label.text = L("Cancel")
//   label.text = L("Hello \(userName)")   // interpolation works
@inline(__always)
func L(_ resource: LocalizedStringResource) -> String {
    String(localized: resource)
}

// MARK: - Approach 3: LanguageManager — dynamic in-app language switching
//
// Override the system language inside the app at runtime without requiring
// the user to go to iPhone Settings. Stores the chosen language in UserDefaults
// and loads the matching .lproj bundle manually.
//
// Works with .xcstrings: Xcode compiles .xcstrings → en.lproj/Localizable.strings,
// fr.lproj/Localizable.strings, etc. at build time, so the .lproj folders exist
// in the app bundle even though the source is a single .xcstrings file.
//
// ❌ XCODE DOES NOT AUTO-EXTRACT KEYS when you use .dynamicLocalized.
//    localizedString(for:) takes a plain String — Xcode's extractor cannot
//    distinguish a localization key from any other string at the call site.
//    Ensure keys already exist in .xcstrings before using them here.
//
// Important caveat: SwiftUI Text() and String(localized:) use the system language,
// not LanguageManager.currentLanguage. You must call .dynamicLocalized or
// LanguageManager.shared.localizedString(for:) explicitly to get the dynamic value.
//
// Usage:
//   LanguageManager.shared.currentLanguage = "fr"  // switch to French
//   label.text = "Cancel".dynamicLocalized          // reads from chosen language
final class LanguageManager {

    static let shared = LanguageManager()

    private init() {}

    var currentLanguage: String {
        get {
            UserDefaults.standard.string(forKey: "SelectedLanguage")
                ?? Locale.current.language.languageCode?.identifier
                ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SelectedLanguage")
        }
    }

    func localizedString(for key: String, tableName: String? = nil) -> String {
        guard
            let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, tableName: tableName, comment: "")
        }
        return NSLocalizedString(key, tableName: tableName, bundle: bundle, comment: "")
    }
}

extension String {
    var dynamicLocalized: String {
        LanguageManager.shared.localizedString(for: self)
    }
}

// MARK: - Approach 4: Enum-based type-safe keys
//
// Centralise all string keys as static LocalizedStringResource properties.
// Gives you autocomplete and compile-time checking — no typos at runtime.
// Pass directly to SwiftUI Text or convert with String(localized:) for UIKit.
//
// ✅ XCODE AUTO-EXTRACTS KEYS from the static property definitions.
//    Each `static let x: LocalizedStringResource = "key"` line is a
//    LocalizedStringResource literal — Xcode extracts "key" at build time.
//    When you use AppStrings.cancel in your views, the key is already in
//    .xcstrings from the definition. No duplicate extraction needed.
//
// Usage (SwiftUI):
//   Text(AppStrings.cancel)
//
// Usage (UIKit):
//   label.text = String(localized: AppStrings.cancel)
enum AppStrings {
    static let cancel: LocalizedStringResource        = "Cancel"
    static let back: LocalizedStringResource          = "Back"
    static let camera: LocalizedStringResource        = "Camera"
    static let bookmarks: LocalizedStringResource     = "Bookmarks"
    static let changeLanguage: LocalizedStringResource = "Change Language"
    static let aiTranslate: LocalizedStringResource   = "AI Translate"
    static let continueAction: LocalizedStringResource = "Continue"
    static let conversation: LocalizedStringResource  = "Conversation"
}
