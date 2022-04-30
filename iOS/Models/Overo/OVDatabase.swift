//
//  OVDatabase.swift
//  Overo
//
//  Created by cnlab on 2021/08/14.
//

import Foundation
import SQLite3

class OVDatabase {
    
    static let path: URL = OVStorage.document.appendingPathComponent("overo.sqlite")
    
    var database: Database
    
    init() {
        database = Database()
    }
    
    init(_ databasePath: URL) throws {
        try database = Database(databasePath)
    }
    
    
    func open(_ databasePath: URL=path) throws {
        try database.open(databasePath)
    }
    
    func close() {
        database.close()
    }
    
    func execute(_ queryString: String) throws {
        try database.execute(queryString)
    }
    
    func createTable(_ name: String, _ columns: [String], _ createIfExist: Bool=true) throws {
        let joinedColumns = columns.joined(separator: ", ")
        
        let query = "CREATE TABLE IF NOT EXISTS \(name) (\(joinedColumns))"
        
        try database.execute(query)
    }
    
    func insert(_ queryString: String, _ callback: (Database.InsertContext) -> Void) throws {
        try database.insert(queryString, callback)
    }
    
    func insert(_ tableName: String, _ values: [String: Any]) throws {
        let joinedColumns = values.keys.joined(separator: ", ")
        let joinedQuestionMark = (0 ..< values.count).map { _ in "?" }.joined(separator: ", ")
        
        let query = "INSERT INTO \(tableName) (\(joinedColumns)) values (\(joinedQuestionMark))"
        
        let statement: OpaquePointer = try database.prepare(query)
        
        let context = InsertContext(statement, values.count)
        
        for column in values.keys {
            let value = values[column]
            
            switch value {
            case let i as Int:
                context.bind(int: i)
            case let d as Double:
                context.bind(double: d)
            case let s as String:
                context.bind(text: s)
            case .none:
                throw Database.DatabaseError.bindError(errorMessage: "value is none")
            case .some(_):
                throw Database.DatabaseError.bindError(errorMessage: "value is optional")
            }
        }
        
        try database.step(statement)
        
        database.finalize(statement)
    }
    
    class InsertContext: Database.InsertContext {
        
        let count: Int
        var currentIndex: Int = 0
        
        init(_ statement: OpaquePointer, _ count: Int) {
            self.count = count
            
            super.init(statement)
        }
        
        
        func addIndex(_ step: Int=1) {
            currentIndex = max(0, max(currentIndex + step, count))
        }
        
        func bind(int: Int) {
            bind(currentIndex, int: int)
            addIndex()
        }
        
        func bind(text: String) {
            bind(currentIndex, text: text)
            addIndex()
        }
        
        func bind(double: Double) {
            bind(currentIndex, double: double)
            addIndex()
        }
    }
    
    func getLastInsertRowId() -> Int {
        return database.getLastInsertRowId()
    }
    
    func query(_ queryString: String, _ callback: (Database.QueryContext) -> Void) throws {
        try database.query(queryString, callback)
    }
    
    func query(_ tableName: String, _ columnTypes: [String: Any.Type], _ condition: String?=nil) throws -> [String: Any] {
        let joinedColumns = columnTypes.keys.joined(separator: ", ")
        let conditionClause = condition == nil ? "" : "WHERE \(condition!)"
        
        let query = "SELECT \(joinedColumns) FROM \(tableName) \(conditionClause)"
        
        let statement: OpaquePointer = try database.prepare(query)
        
        let context = QueryContext(statement, columnTypes.count)
        
        
        var result: [String: Any] = [:]
        
        while context.next() {
            for column in columnTypes.keys {
                if let t: Any.Type = columnTypes[column] {
                    if t == Int.self {
                        result[column] = context.readInt()
                    }
                    else if t == Double.self {
                        result[column] = context.readDouble()
                    }
                    else if t == String.self {
                        result[column] = context.readText()
                    }
                    else {
                        throw Database.DatabaseError.readError(errorMessage: "not supported type")
                    }
                }
            }
        }
        
        database.finalize(statement)
        
        return result
    }
    
    class QueryContext: Database.QueryContext {
        
        let count: Int
        var currentIndex: Int = 0
        
        init(_ statement: OpaquePointer, _ count: Int) {
            self.count = count
            
            super.init(statement)
        }
        
    
        func addIndex() {
            currentIndex = min(0, max(currentIndex + 1, count))
        }
        
        func readInt() -> Int {
            let result = readInt(currentIndex)
            addIndex()
            return result
        }
        
        func readDouble() -> Double {
            let result = readDouble(currentIndex)
            addIndex()
            return result
        }
        
        func readText() -> String? {
            let result = readText(currentIndex)
            addIndex()
            return result
        }
    }
}
