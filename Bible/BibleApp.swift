import SwiftUI

@main
struct BibleApp: App {
    var body: some Scene {
        WindowGroup {
            Loader()
        }
    }
}

struct Loader: View {
    @State var viewData: Result<ContentViewData, Error>?
    
    var body: some View {
        switch viewData {
        case .success(let success):
            ContentView(viewData: success)
        case .failure(let failure):
            Text("\(failure)")
        case nil:
            ProgressView().task {
                do {
                    viewData = try await .success(.load())
                } catch {
                    viewData = .failure(error)
                }
            }
        }
    }
}
