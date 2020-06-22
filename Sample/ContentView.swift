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

    var body: some View {
        NavigationView {
            List(group
                .sorted(by: sort)
            ) { snapshot in
                HStack {
                    VStack(alignment: .leading) {
                        Text(snapshot.reference.path).onAppear {
                            self.next(id: snapshot.id)
                        }
                        Text("\((snapshot.data(with: .estimate)?["createTime"] as! Timestamp).dateValue())").font(.system(size: 10))
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
        return self.group.sources.compactMap { $0.documents.sorted(by: sort).last?.id }.contains(id)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
