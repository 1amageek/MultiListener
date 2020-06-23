//
//  DataSource.swift
//  DataSource
//
//  Created by nori on 2020/06/15.
//  Copyright © 2020 nori. All rights reserved.
//

import FirebaseFirestore
import Combine

public typealias SortDiscriptor<Value> = (Value, Value) -> Bool

public final class DataSource {

    public let query: Query

    public var querySnapshot: QuerySnapshot?

    @Published public var documents: [DocumentSnapshot] = []

    @Published public var error: Error?

    var listener: ListenerRegistration?

    public init(_ query: Query) {
        self.query = query
    }

    public func get(source: FirestoreSource = .default) {
        self.get(source: source, query: self.query)
    }

    public func get(source: FirestoreSource = .default, query: Query) {
        query.getDocuments(source: source) { [weak self] (querySnapshot, error) in
            if let error = error {
                print(error)
                self?.error = error
                return
            }
            self?.querySnapshot = querySnapshot
            self?.documents += querySnapshot?.documents ?? []
        }
    }

    public func listen(includeMetadataChanges: Bool = true) -> ListenerRegistration {
        return self.listen(includeMetadataChanges: includeMetadataChanges, query: self.query)
    }

    public func listen(includeMetadataChanges: Bool = true, query: Query) -> ListenerRegistration {
        let listener = query.addSnapshotListener(includeMetadataChanges: includeMetadataChanges) { [weak self] (querySnapshot, error) in
            if let error = error {
                print(error)
                self?.error = error
                return
            }
            self?.querySnapshot = querySnapshot
            self?.documents += querySnapshot?.documents ?? []
        }
        self.listener = listener
        return listener
    }

    deinit {
        self.listener?.remove()
    }
}

public final class DataSourceGroup {

    public let sources: [DataSource]

    @Published var documents: [DocumentSnapshot] = []

    private var _cancellable: Cancellable?

    private var _listeners: [ListenerRegistration] = []

    public init(_ queries: [Query]) {
        self.sources = queries.map { DataSource.init($0) }
    }

    public func get(source: FirestoreSource = .default) {
        let publishers = Publishers.MergeMany(sources.compactMap { $0.$documents })
        self._cancellable = publishers
            .collect(sources.count)
            .map { $0.combine.unique }
            .map { $0.filter { !self.documents.map { $0.id }.contains($0.id) } }
            .sink { documents in self.documents += documents }
        sources.forEach { $0.get(source: source) }
    }

    public func listen(includeMetadataChanges: Bool = true) {
        let publishers = Publishers.MergeMany(sources.map { $0.$documents })
        self._cancellable = publishers
            .collect(sources.count)
            .map { $0.combine.unique }
            .map { $0.filter { !self.documents.map { $0.id }.contains($0.id) } }
            .sink { documents in self.documents += documents }
        self._listeners = sources.map { $0.listen(includeMetadataChanges: includeMetadataChanges) }
    }

    deinit {
        self._listeners.forEach { $0.remove() }
    }

}

extension Array where Element == [DocumentSnapshot] {

    var combine: [DocumentSnapshot] {
        self.reduce([], +)
    }
}

extension Array where Element == DocumentSnapshot {

    var unique: Self {
        self.reduce([]) { $0.map{ $0.id }.contains($1.id) ? $0 : $0 + [$1] }
    }
}

extension DocumentSnapshot: Identifiable {

    public typealias ID = String

    public var id: String { self.reference.documentID }
}

extension DataSource: ObservableObject {

}

extension DataSource: RandomAccessCollection {

    public typealias Element = DocumentSnapshot

    public typealias Index = Int

    public subscript(position: Int) -> DocumentSnapshot { documents[position] }

    public var startIndex: Int { 0 }

    public var endIndex: Int { documents.count }
}

extension DataSourceGroup: ObservableObject {

}

extension DataSourceGroup: RandomAccessCollection {

    public typealias Element = DocumentSnapshot

    public typealias Index = Int

    public subscript(position: Int) -> DocumentSnapshot { documents[position] }

    public var startIndex: Int { 0 }

    public var endIndex: Int { documents.count }
}
