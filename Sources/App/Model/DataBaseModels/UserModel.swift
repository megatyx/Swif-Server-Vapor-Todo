//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/10/20.
//

import Vapor
import Fluent

final class User: Model, Content {
    static let schema = "users"

    // Unique identifier for this Galaxy.
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }
    init(id: UUID? = nil, name: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema).id()
        .field("name", .string, .required).unique(on: "name", name: "no_duplicate_names")
        .field("created_at", .date)
        .field("updated_at", .date)
        .create()
    }
    
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
