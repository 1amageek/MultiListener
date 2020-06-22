# MultiListener

MultiListener is a library that bundles multiple collections of Cloud Firestore into a single DataSource.

<img src="https://github.com/1amageek/MultiListener/blob/master/docs/concept.png" width="100%">


## Usage

```swift
struct ContentView: View {

    @ObservedObject(initialValue: DataSourceGroup([
        Firestore.firestore().collection("YOUR_COLLECTION_0")
            .order(by: "createTime")
            .limit(to: 30),
        Firestore.firestore().collection("YOUR_COLLECTION_1")
            .order(by: "createTime")
            .limit(to: 30)
    ])) var dataSource: DataSourceGroup

    var body: some View {
        NavigationView {
            List(dataSource) { snapshot in
                Text(snapshot.reference.path)
            }.onAppear {
                self.group.get()
            }
        }
    }
}

```
