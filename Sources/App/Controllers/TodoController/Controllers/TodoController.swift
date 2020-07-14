//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/11/20.
//

import Vapor
import Fluent

struct TodoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todoGroup = routes.grouped("Todos")
        todoGroup.post("create") {req -> EventLoopFuture<Response> in
            let createRequest = try req.content.decode(TodoRequest.CreateRequest.self)
            guard !createRequest.name.isEmpty else {throw Abort(.badRequest)}
            return try TodoController
                .createTodo(req, createTodo: createRequest).flatMap({
                    TodoResponse(message: "created", todo: $0).encodeResponse(for: req)
                })
        }
        
        todoGroup.post("update") {req -> EventLoopFuture<Response> in
            return try self.updateTodoWith(req, updateTodoRequest: try req.content.decode(TodoRequest.UpdateRequest.self))
                .flatMap({TodoResponse(message: "updated", todo: $0).encodeResponse(for: req)})
        }
        
        todoGroup.post("delete") {req -> EventLoopFuture<Response> in
            let deleteRequest = try req.content.decode(TodoRequest.DeleteRequest.self)
            return try TodoController.deleteTodoWith(req,
                                                     id: deleteRequest.todoID,
                                                     shouldForceDelete: deleteRequest.shouldForceDelete,
                                                     shouldCascade: deleteRequest.shouldCascade)
                .flatMap({GenericResponse(message: "Deleted").encodeResponse(for: req)})
        }
        
        todoGroup.get(":userID") {req -> EventLoopFuture<Response> in
            guard let userIDParam = req.parameters.get("userID"),
                let userID = UUID(uuidString: userIDParam) else {throw Abort(.badRequest)}
            return try TodoController.findTodosBy(req, userID: userID).flatMap({$0.encodeResponse(for: req)})
        }
    }
}

extension TodoController {
    static func createTodo(_ req: Request, createTodo: TodoRequest.CreateRequest) throws -> EventLoopFuture<Todo> {
        guard User(id: createTodo.userID, name: "").$id.exists else {throw Abort(HTTPResponseStatus(statusCode: 404, reasonPhrase: "UserID isn't valid"))}
        let newTodo = Todo(name: createTodo.name, user: createTodo.userID, description: createTodo.description)
        return newTodo.create(on: req.db).transform(to: newTodo)
    }
    
    static func findTodosBy(_ req: Request, userID: UUID) throws -> EventLoopFuture<[Todo]> {
        return Todo.query(on: req.db).filter(\.$user.$id == userID).all()
    }
    
    static func findTodoby(_ req: Request, id: UUID) throws -> EventLoopFuture<Todo> {
        return Todo.find(id, on: req.db).unwrap(or: Abort.generateNotFound(objectNotFoundString: "todo"))
    }
    
    func updateTodoWith(_ req: Request, updateTodoRequest updatedTodo: TodoRequest.UpdateRequest) throws -> EventLoopFuture<Todo> {
        return try TodoController.findTodoby(req, id: updatedTodo.todoID).flatMap({ todo -> EventLoopFuture<Todo> in
            todo.name = updatedTodo.name
            todo.description = updatedTodo.description
            return todo.update(on: req.db).transform(to: todo)
        })
    }
    
    static func deleteTodoWith(_ req: Request, id: UUID, shouldForceDelete: Bool = false, shouldCascade: Bool = true) throws -> EventLoopFuture<Void> {
        
        let todoToBeDeleted = try TodoController.findTodoby(req, id: id)
        let deleteTodo = {todoToBeDeleted.flatMap({return $0.delete(on: req.db)})}
        
        let deleteChecklistItems = { () -> EventLoopFuture<Void> in
                return try ChecklistItemController
                    .deleteAllChecklistItemsBy(req, todoID: id, shouldForceDelete: shouldCascade)
                    .flatMap(deleteTodo)
        }
        
        return shouldCascade ? try deleteChecklistItems() : deleteTodo()
    }
    
    static func deleteAllTodosWith(_ req: Request, userId: UUID, shouldForceDelete: Bool = false, shouldCascade: Bool = true) throws -> EventLoopFuture<Void> {
        let allTodos = Todo.query(on: req.db).filter(\.$user.$id == userId).all()
        let deleteChecklistItems = { (todoID: UUID) -> EventLoopFuture<Void> in
                return try ChecklistItemController
                    .deleteAllChecklistItemsBy(req, todoID: todoID, shouldForceDelete: shouldCascade)
        }
        
        return allTodos.flatMapEachThrowing({ todo throws -> EventLoopFuture<Void> in
            return try deleteChecklistItems(try todo.requireID())
                .flatMap({todo.delete(force: shouldForceDelete, on: req.db)})
            }).flatMap({$0.flatten(on: req.eventLoop)})
    }
    
    func restoreUserWith(_ req: Request, id: UUID) throws -> EventLoopFuture<Void> {
        let notFoundError = Abort(HTTPResponseStatus(statusCode: 404, reasonPhrase: "user not found"))
        return User.query(on: req.db).filter(\.$id == id).withDeleted().first().unwrap(or: notFoundError)
            .flatMap({$0.restore(on: req.db)})
    }
}
