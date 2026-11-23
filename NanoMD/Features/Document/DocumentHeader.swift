import SwiftUI

struct DocumentHeader: View {
    let filename: String
    let font: ReaderFont
    let theme: AppTheme
    let navigation: DocumentNavigation
    var inEditor = false

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                Text("nano.md")
                    .font(Font(font.font(size: 12, weight: font.headingWeight)))
                Spacer(minLength: 0)
                Text(filename).truncationMode(.middle)
            }
            .font(Font(font.font(size: 12)))
            .lineLimit(1)
            .padding(.horizontal, 17)
            .padding(.vertical, 12)
            .foregroundStyle(Color(nsColor: theme.headerText))
            .opacity(navigation.findBarView == nil ? 1 : 0)
            .accessibilityHidden(navigation.findBarView != nil)

            if let findBar = navigation.findBarView {
                FindBarView(findBar: findBar) {
                    guard navigation.findBarView === findBar else { return }
                    navigation.performFindAction(.showFindInterface, inEditor: inEditor)
                }
                .frame(height: navigation.findBarHeight)
            }
        }
        .frame(minHeight: 44)
        .background(Color(nsColor: theme.header))
    }
}
