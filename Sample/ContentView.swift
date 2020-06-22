//
//  ContentView.swift
//  Sample
//
//  Created by nori on 2020/06/18.
//  Copyright © 2020 1amageek. All rights reserved.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift


struct Model: Codable, Identifiable {

    var id: String { self.documentID ?? "" }

    typealias ID = String

    @DocumentID var documentID: String?

    @ServerTimestamp var createTime: Timestamp!

}

struct ContentView: View {

    @ObservedObject(initialValue: DataSourceGroup([
        Firestore.firestore().collection("tests0")
            .order(by: "createTime")
            .limit(to: 3),
        Firestore.firestore().collection("tests1")
            .order(by: "createTime")
            .limit(to: 3)
    ])) var group: DataSourceGroup

    func next(id: String) {
        print(" next", id)
        self.group.sources.forEach { source in
            if let querySnapshot = source.querySnapshot {
                if let lastDocumentSnapshot = source.documents.sorted(by: sort).last,
                    lastDocumentSnapshot.id == id {
                    source.get(query: querySnapshot.query.start(afterDocument: lastDocumentSnapshot))
                }
            }
        }
    }

    var sort: (DocumentSnapshot, DocumentSnapshot) -> Bool = { s0 , s1 in
        let t0 = s0.data(with: .estimate)?["createTime"] as! Timestamp
        let t1 = s1.data(with: .estimate)?["createTime"] as! Timestamp
        return t0.dateValue() < t1.dateValue()
    }

    var dataSource: [Model] {
        return self.group
            .sorted(by: sort)
            .map { snapshot in try! Firestore.Decoder().decode(Model.self, from: snapshot.data(with: .estimate)!, in: snapshot.reference) }
    }

    var body: some View {
        NavigationView {
            List(dataSource) { snapshot in
                HStack {
                    VStack(alignment: .leading) {
                        Text(snapshot.id).onAppear {
                            self.next(id: snapshot.id)
                        }
                        Text("\(snapshot.createTime)").font(.system(size: 10))
                    }

                    if self.isLast(id: snapshot.id) {
                        Spacer()
                        Text("Last")
                    }
                }
            }.onAppear {
                self.group.get()
            }.navigationBarItems(trailing: HStack {
                Button("+") {
                    Firestore.firestore().collection("tests0").document()
                        .setData(["createTime": FieldValue.serverTimestamp()])
                }
                Button("+") {
                    Firestore.firestore().collection("tests1").document()
                        .setData(["createTime": FieldValue.serverTimestamp()])
                }
            })
        }
    }

    func isLast(id: String) -> Bool {
        print("isLast", id, self.group.sources.compactMap { $0.documents.sorted(by: sort).last?.id }, self.group.sources.compactMap { $0.documents.sorted(by: sort).last?.id }.contains(id))
        return self.group.sources.compactMap { $0.documents.sorted(by: sort).last?.id }.contains(id)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
