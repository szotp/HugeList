import SwiftUI
import Combine

class HugeListProxy: ObservableObject {
    fileprivate let actions = PassthroughSubject<(UITableView) -> Void, Error>()
    
    func scrollToIndex(_ index: Int) {
        actions.send { tableView in
            tableView.scrollToRow(at: [0, index], at: .top, animated: true)
        }
    }
}

struct HugeList<T: View>: UIViewRepresentable {
    let proxy: HugeListProxy
    let count: Int
    @ViewBuilder let getCell: (Int) -> T
    
    func makeUIView(context: Context) -> TableView {
        let view =  TableView()
        view.setup(owner: self)
        return view
    }
    
    func updateUIView(_ uiView: TableView, context: Context) {
        assert(proxy === uiView.owner?.proxy)
        let newCount = count != uiView.owner?.count
        uiView.owner = self
        
        if newCount {
            uiView.reloadData()
        }
    }
    
    class TableView: UITableView, UITableViewDataSource, UITableViewDelegate {
        fileprivate var owner: HugeList<T>?
        private var cancellable: AnyCancellable?
        
        func setup(owner: HugeList<T>) {
            self.owner = owner
            register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
            dataSource = self
            delegate = self
            separatorStyle = .none
            allowsSelection = false
            cancellable = owner.proxy.actions.sink(receiveCompletion: {_ in }, receiveValue: { [weak self] action in
                if let self {
                    action(self)
                }
            })
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            owner?.count ?? 0
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            if let owner {
                cell.contentConfiguration = UIHostingConfiguration {
                    owner.getCell(indexPath.row)
                }
            }

            return cell
        }
    }
    
}
