//
//  TodoModel.swift
//  
//
//  Created by Tyler Wells on 7/8/20.
//

import Vapor
import Fluent

final class Todo: Model, Content {
    static let schema: String = "todos"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String?
    
    //relational key
    @Parent(key: "user_id")
    var user: User
    
    @Children(for: \.$todo)
    var checklistItems: [ChecklistItem]
    
    //TimeStamps
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    init(id: UUID? = nil, name: String, user: UUID, createdAt: Date? = nil, updatedAt: Date? = nil, description: String?) {
        self.id = id
        self.name = name
        self.$user.id = user
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct TodoMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Todo.schema)
            .id()
            .field("user_id", .uuid, .references("users", "id"))
            .field("description", .string)
            .field("name", .string, .required)
            .field("created_at", .date)
            .field("updated_at", .date)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Todo.schema).delete()
    }
}
