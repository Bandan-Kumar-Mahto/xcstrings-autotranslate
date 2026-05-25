//
//  ContentView.swift
//  StringTranslatorDemo
//
//  Created by iOS Department on 20/05/26.
//
//  This view demonstrates the four main approaches to iOS localization.
//  All approaches read from the Localizable.xcstrings file (or .strings files).
//  See Strings+Extensions.swift for implementation details of each approach.
//

import SwiftUI

struct ContentView: View {

    @State private var dynamicLanguage = LanguageManager.shared.currentLanguage

    let supportedLanguages: [(code: String, label: String)] = [
        ("en", "English"),
        ("fr", "French — Français"),
        ("hi", "Hindi — हिन्दी"),
        ("de", "German — Deutsch"),
        ("es", "Spanish — Español"),
    ]

    var body: some View {
        NavigationStack {
            List {

                // ----------------------------------------------------------------
                // APPROACH 1 — SwiftUI native (no code needed)
                // SwiftUI's Text() takes LocalizedStringKey and auto-localises.
                // ✅ XCODE EXTRACTS KEYS — string literals inside Text("...") are
                //    recognized and added to Localizable.xcstrings at build time.
                // Use Text(verbatim: "...") when you do NOT want localisation.
                // ----------------------------------------------------------------
                Section {
                    demoRow(
                        label: "Text(\"Cancel\") ✅",
                        value: Text("Cancel")
                    )
                    demoRow(
                        label: "Text(\"Camera\") ✅",
                        value: Text("Camera")
                    )
                    demoRow(
                        label: "Text(verbatim: \"v1.0\") ❌",  // verbatim = no localisation
                        value: Text(verbatim: "v1.0")
                    )
                } header: {
                    sectionHeader(
                        number: "1",
                        title: "SwiftUI Native",
                        subtitle: "Text() auto-localises — no extra code needed"
                    )
                }

                // ----------------------------------------------------------------
                // APPROACH 2 — .localized extension (NSLocalizedString)
                // Wraps NSLocalizedString for UIKit or anywhere a plain String
                // is required. Simple and widely compatible.
                // ❌ XCODE DOES NOT EXTRACT KEYS — Xcode sees NSLocalizedString(self)
                //    at the call site but cannot resolve what `self` is statically.
                //    Keys must already exist in .xcstrings (added manually or via
                //    another recognized API used elsewhere in the project).
                // ----------------------------------------------------------------
                Section {
                    demoRow(
                        label: "\"Cancel\".localized ❌",
                        value: Text("Cancel".localized)
                    )
                    demoRow(
                        label: "\"Back\".localized ❌",
                        value: Text("Back".localized)
                    )
                    demoRow(
                        label: "\"AI Translate\".localized ❌",
                        value: Text("AI Translate".localized)
                    )
                } header: {
                    sectionHeader(
                        number: "2",
                        title: ".localized Extension",
                        subtitle: "NSLocalizedString wrapper — great for UIKit"
                    )
                }

                // ----------------------------------------------------------------
                // APPROACH 3 — L() free function (Recommended for non-SwiftUI)
                // Uses the modern LocalizedStringResource API (iOS 16+).
                // ✅ XCODE EXTRACTS KEYS (Xcode 15+) — the parameter type is
                //    LocalizedStringResource so string literals you pass to L()
                //    are recognized and added to Localizable.xcstrings at build time.
                // Also supports string interpolation: L("Hello \(name)").
                // ----------------------------------------------------------------
                Section {
                    demoRow(
                        label: "L(\"Continue\") ✅",
                        value: Text(L("Continue"))
                    )
                    demoRow(
                        label: "L(\"Change Language\") ✅",
                        value: Text(L("Change Language"))
                    )
                    demoRow(
                        label: "L(\"Conversation\") ✅",
                        value: Text(L("Conversation"))
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Interpolation ✅")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(L("Hello \("Bandan")"))
                            .font(.body)
                    }
                } header: {
                    sectionHeader(
                        number: "3",
                        title: "L() Function",
                        subtitle: "LocalizedStringResource — recommended for Swift code"
                    )
                }

                // ----------------------------------------------------------------
                // APPROACH 4 — Enum-based type-safe keys (AppStrings)
                // All keys are centralised as static LocalizedStringResource properties.
                // ✅ XCODE EXTRACTS KEYS from the static definitions in AppStrings —
                //    each `static let x: LocalizedStringResource = "key"` adds "key"
                //    to Localizable.xcstrings. Usage here (AppStrings.cancel) does
                //    not re-extract because the key is already registered.
                // Gives autocomplete + compile-time safety — no typos at runtime.
                // ----------------------------------------------------------------
                Section {
                    demoRow(
                        label: "AppStrings.cancel ✅",
                        value: Text(AppStrings.cancel)
                    )
                    demoRow(
                        label: "AppStrings.bookmarks ✅",
                        value: Text(AppStrings.bookmarks)
                    )
                    demoRow(
                        label: "AppStrings.aiTranslate ✅",
                        value: Text(AppStrings.aiTranslate)
                    )
                    HStack {
                        Text("UIKit: String(localized: AppStrings.camera) ✅")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(localized: AppStrings.camera))
                            .font(.body)
                    }
                } header: {
                    sectionHeader(
                        number: "4",
                        title: "AppStrings Enum",
                        subtitle: "Type-safe keys — autocomplete, no typos"
                    )
                }

                // ----------------------------------------------------------------
                // APPROACH 5 — LanguageManager (dynamic in-app switching)
                // Lets users switch language inside the app without going to
                // iPhone Settings. Works with .xcstrings — Xcode compiles it
                // into en.lproj/Localizable.strings etc. in the app bundle.
                // ❌ XCODE DOES NOT EXTRACT KEYS from .dynamicLocalized calls —
                //    the key is a plain String at the call site, invisible to the
                //    extractor. Keys must already exist in .xcstrings.
                // ⚠️  SwiftUI Text() ignores LanguageManager — it always uses the
                //    system language. Use .dynamicLocalized explicitly.
                // ----------------------------------------------------------------
                Section {
                    Picker("Language", selection: $dynamicLanguage) {
                        ForEach(supportedLanguages, id: \.code) { lang in
                            Text(lang.label).tag(lang.code)
                        }
                    }
                    .onChange(of: dynamicLanguage) { _, newCode in
                        LanguageManager.shared.currentLanguage = newCode
                    }

                    demoRow(
                        label: "\"Cancel\".dynamicLocalized",
                        value: Text("Cancel".dynamicLocalized)
                    )
                    demoRow(
                        label: "\"Camera\".dynamicLocalized",
                        value: Text("Camera".dynamicLocalized)
                    )

                    Text("Works with .xcstrings — Xcode compiles it into en.lproj/Localizable.strings, fr.lproj/… at build time, so the bundle lookup succeeds.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Caveat: SwiftUI Text() still uses the system language. Use .dynamicLocalized or LanguageManager explicitly.")
                        .font(.caption)
                        .foregroundStyle(.orange)

                } header: {
                    sectionHeader(
                        number: "5",
                        title: "LanguageManager",
                        subtitle: "Dynamic in-app language switching at runtime"
                    )
                }
            }
            .navigationTitle("Localization Demo")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func demoRow(label: String, value: Text) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
            value
                .font(.body)
        }
    }

    @ViewBuilder
    private func sectionHeader(number: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(number)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(nil)
        }
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
}
