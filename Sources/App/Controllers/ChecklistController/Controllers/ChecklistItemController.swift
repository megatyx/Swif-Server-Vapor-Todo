//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/11/20.
//

import Vapor
import Fluent

struct ChecklistItemController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let checklistGroup = routes.grouped("CheckListItem")
        checklistGroup.post("create") {req -> EventLoopFuture<Response> in
            let checklistRequest = try req.content.decode(ChecklistItemRequests.CreateRequest.self)
            return try ChecklistItemController.createChecklistItem(req, checklistItem: checklistRequest).flatMap({
                return ChecklistRouteResponse(message: "Created", checklistItem: $0).encodeResponse(for: req)
            })
        }
        checklistGroup.get("toggleDone", ":checklistID") {req -> EventLoopFuture<Response> in
            guard let parameterID = req.parameters.get("checklistID"),
                let checklistID = UUID(uuidString: parameterID) else {throw Abort(.badRequest)}
            return try ChecklistItemController.getChecklistItemsBy(req, id: checklistID).flatMap({ item -> EventLoopFuture<Response> in
                item.isDone.toggle()
                return item.update(on: req.db).transform(to:item.encodeResponse(for: req))
            })
        }

        checklistGroup.post("update") {req -> EventLoopFuture<Response> in
            let updateRequest = try req.content.decode(ChecklistItemRequests.UpdateRequest.self)
            return try self.updateChecklistItemBy(req, updateRequest: updateRequest)
                .flatMap({
                    ChecklistRouteResponse(message: "updated", checklistItem: $0).encodeResponse(for: req)
                })
        }
        
        checklistGroup.post("delete") { req -> EventLoopFuture<Response> in
            let deleteRequest = try req.content.decode(ChecklistItemRequests.DeleteRequest.self)
            return try ChecklistItemController
                .deleteChecklistItemBy(req, id: deleteRequest.itemID, shouldForceDelete: deleteRequest.shouldForceDelete)
                .flatMap({GenericResponse(message: "deleted").encodeResponse(for: req)})
        }
    }
}

extension ChecklistItemController {
    
    static func createChecklistItem(_ req: Request, checklistItem: ChecklistItemRequests.CreateRequest) throws -> EventLoopFuture<ChecklistItem> {
        let connectedTodo = Todo()
        connectedTodo.id = checklistItem.todoID
        guard connectedTodo.$id.exists else {throw Abort(HTTPResponseStatus(statusCode: 404, reasonPhrase: "Todo with ID is not found"))}
        let checklistItem = ChecklistItem(name: checklistItem.name, todoID: checklistItem.todoID)
        return checklistItem.create(on: req.db).transform(to: checklistItem)
    }
    
    static func getChecklistItemsBy(_ req: Request, id: UUID) throws -> EventLoopFuture<ChecklistItem> {
        return ChecklistItem.find(id, on: req.db).flatMapThrowing({
            guard let checklistItem = $0 else {throw Abort.generateNotFound(objectNotFoundString: "Checklist Item")}
            return checklistItem
        })
    }
    
    func updateChecklistItemBy(_ req: Request, updateRequest: ChecklistItemRequests.UpdateRequest) throws -> EventLoopFuture<ChecklistItem> {
        return try ChecklistItemController.getChecklistItemsBy(req, id: updateRequest.itemID)
            .flatMap({ item -> EventLoopFuture<ChecklistItem> in
                item.name = updateRequest.name
                item.isDone = updateRequest.isDone
                return item.update(on: req.db).transform(to: item)
            })
    }
    
    static func getChecklistItemsBy(_ req: Request, todoId: UUID) throws -> EventLoopFuture<[ChecklistItem]> {
        return ChecklistItem.query(on: req.db).filter(\.$todo.$id == todoId).all()
    }
    
    static func deleteChecklistItemBy(_ req: Request, id: UUID, shouldForceDelete: Bool = false) throws -> EventLoopFuture<Void> {
        return try ChecklistItemController.getChecklistItemsBy(req, id: id)
            .flatMap({$0.delete(force: shouldForceDelete, on: req.db)})
    }
    
    static func deleteAllChecklistItemsBy(_ req: Request, todoID: UUID, shouldForceDelete: Bool) throws -> EventLoopFuture<Void> {
        return try ChecklistItemController.getChecklistItemsBy(req, todoId: todoID).flatMap({$0.delete(force: shouldForceDelete, on: req.db)})
    }
}

