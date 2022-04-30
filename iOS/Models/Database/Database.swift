//
//  Database.swift
//  Overo
//
//  Created by cnlab on 2021/08/05.
//

import Foundation
import SQLite3

class Database {
    
    enum DatabaseError: Error {
        case connectionError
        case executionError(errorMessage: String)
        case preparingError(errorMessage: String)
        case stepError(errorMessage: String)
        case bindError(errorMessage: String)
        case readError(errorMessage: String)
    }
    
    var database: OpaquePointer?
    
    var isOpened: Bool {
        get {
            return database != nil
        }
    }
    
    init() {
    }
    
    init(_ databaseFilePath: URL) throws {
        try open(databaseFilePath)
    }
    
    
    func open(_ filePath: URL) throws {
        let result = sqlite3_open(filePath.path, &database)
        
        if result != SQLITE_OK {
            database = nil
            throw DatabaseError.connectionError
        }
    }
    
    func close() {
        sqlite3_close(database)
        database = nil
    }
    
    func execute(_ queryString: String) throws {
        let result = sqlite3_exec(database, queryString, nil, nil, nil)
        
        if result != SQLITE_OK {
            let errorMessage: String = String(cString: sqlite3_errmsg(database))
            
            throw DatabaseError.executionError(errorMessage: errorMessage)
        }
    }
    
    func prepare(_ queryString: String) throws -> OpaquePointer {
        var statement: OpaquePointer? = nil
        
        let result = sqlite3_prepare_v2(database, queryString, -1, &statement, nil)
        
        if result != SQLITE_OK {
            statement = nil
            let errorMessage: String = String(cString: sqlite3_errmsg(database))
            
            throw DatabaseError.preparingError(errorMessage: errorMessage)
        }
        
        return statement!
    }
    
    func step(_ statement: OpaquePointer) throws {
        let result = sqlite3_step(statement)

        if result != SQLITE_DONE {
            let errorMessage: String = String(cString: sqlite3_errmsg(database))
            
            throw DatabaseError.stepError(errorMessage: errorMessage)
        }
    }
    
    func finalize(_ statement: OpaquePointer) {
        sqlite3_finalize(statement)
    }
    
    
    func insert(_ queryString: String, _ callback: (InsertContext) -> Void) throws {
        let statement: OpaquePointer = try prepare(queryString)
        
        let context = InsertContext(statement)
        
        callback(context)
        
        try step(statement)
        
        finalize(statement)
    }
    
    class InsertContext {
        
        var statement: OpaquePointer?
        
        init(_ statement: OpaquePointer?) {
            self.statement = statement
        }
        
        func bind(_ index: Int, int: Int) {
            sqlite3_bind_int(statement, Int32(index), Int32(int))
        }
        
        func bind(_ index: Int, text: String?) {
            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

            sqlite3_bind_text(statement, Int32(index), text, -1, SQLITE_TRANSIENT)
        }

        func bind(_ index: Int, double: Double) {
            sqlite3_bind_double(statement, Int32(index), double)
        }
    }
    
    func getLastInsertRowId() -> Int {
        return Int(sqlite3_last_insert_rowid(database))
    }
    
    
    func query(_ queryString: String, _ callback: (QueryContext) -> Void) throws {
        let statement: OpaquePointer = try prepare(queryString)
        
        let context = QueryContext(statement)
        
        callback(context)
        
        finalize(statement)
    }
    
    class QueryContext {
        
        let statement: OpaquePointer
        
        init(_ statement: OpaquePointer) {
            self.statement = statement
        }
        
        
        func next() -> Bool {
            return sqlite3_step(statement) == SQLITE_ROW
        }
        
        func readInt(_ index: Int) -> Int {
            return Int(sqlite3_column_int(statement, Int32(index)))
        }
        
        func readText(_ index: Int) -> String? {
            let result = sqlite3_column_text(statement, Int32(index))
            
            return result == nil ? nil : String(cString: result!)
        }
        
        func readDouble(_ index: Int) -> Double {
            return sqlite3_column_double(statement, Int32(index))
        }
    }
}
