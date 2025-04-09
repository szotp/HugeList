import SwiftUI
import Combine

final class Bible: Decodable {
    struct Book: Codable {
        let abbrev: String
        let chapters: [Chapter]
        let name: String
    }
    
    typealias Chapter = [String]
    
    let books: [Book]
    
    init(from decoder: any Decoder) throws {
        self.books = try [Bible.Book].init(from: decoder)
    }

    static func load() async throws -> Bible {
        let url = URL(string: "https://raw.githubusercontent.com/thiagobodruk/bible/refs/heads/master/json/en_bbe.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let result = try decoder.decode(Bible.self, from: data)

        return result
    }
}

struct ContentViewData {
    struct Link: Identifiable {
        let title: String
        let index: Int
        
        var id: Int {
            index
        }
    }
    
    enum Item {
        case line(String)
        case header(String)
    }
    
    let items: [Item]
    let links: [Link]
    
    static func load() async throws -> ContentViewData {
        let bible = try await Bible.load().books
        
        var items: [Item] = []
        var links: [Link] = []
        
        for book in bible {
            links.append(.init(title: book.name, index: items.count))
            items.append(.header(book.name))
            for chapter in book.chapters {
                items.append(contentsOf: chapter.map({ Item.line($0) }))
            }
        }
        
        return ContentViewData(items: items, links: links)
    }
}



struct ContentView: View {
    let viewData: ContentViewData
    
    @StateObject var proxy = HugeListProxy()
    
    var body: some View {
        NavigationView {
            HugeList(proxy: proxy, count: viewData.items.count) { x in
                switch viewData.items[x] {
                case .header(let title):
                    Text(title).bold()
                case .line(let string):
                    Text(string)
                }
            }.ignoresSafeArea().navigationTitle("Bible").toolbar {
                menu
            }
        }
    }
    
    var menu: some View {
        Menu {
            ForEach(viewData.links) { link in
                Button(link.title) {
                    proxy.scrollToIndex(link.index)
                }
            }
        } label: {
            Text("Jump to...")
        }
    }
}
