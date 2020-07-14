//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/10/20.
//

import Vapor
import Fluent

final class ChecklistItem: Model, Content {
    static let schema: String = "checklist_items"
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "isDone")
    var isDone: Bool
    
    //relational key
    @Parent(key: "todo_id")
    var todo: Todo
    
    //TimeStamps
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    init(id: UUID? = nil, name: String, todoID: UUID, isDone: Bool = false, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.isDone = isDone
        self.$todo.id = todoID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ChecklistItemsMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ChecklistItem.schema)
            .id()
            .field("todo_id", .uuid, .references("todos", "id"))
            .field("name", .string, .required)
            .field("isDone", .bool, .required)
            .field("created_at", .date)
            .field("updated_at", .date)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ChecklistItem.schema).delete()
    }
}
