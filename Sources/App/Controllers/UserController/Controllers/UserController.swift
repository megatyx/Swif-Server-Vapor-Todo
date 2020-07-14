//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/8/20.
//

import Vapor
import Fluent

extension Abort {
    static func generateNotFound(objectNotFoundString descriptiveString: String) -> Abort {
        return Abort(HTTPResponseStatus(statusCode: 404, reasonPhrase: "\(descriptiveString) not found"))
    }
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let userGroup = routes.grouped("User")
        userGroup.post("create") {req -> EventLoopFuture<Response> in
            let newUser = User(name: try req.content.decode(UserRequsts.CreateUserModel.self).name)
            return newUser.create(on: req.db).transform(to:UserRouteResponse(user: UserResponse(user: newUser), message: "Created").encodeResponse(for: req))
        }
        
        userGroup.post("update") {req -> EventLoopFuture<Response> in
            let possiblePatchedUser = try req.content.decode(UserRequsts.UpdateUserRequest.self)
            return try self.updateUserWith(req, id: possiblePatchedUser.id, name: possiblePatchedUser.name).flatMap({
                UserRouteResponse(user: UserResponse(user: $0), message: "updated").encodeResponse(for: req)
            })
        }
        
        userGroup.post("delete") {req -> EventLoopFuture<Response> in
            let userToDelete = try req.content.decode(UserRequsts.DeleteUserRequest.self)
            return try self.deleteUserWith(req, id: userToDelete.id, shouldForceDelete: userToDelete.forceDelete)
                .transform(to: GenericResponse(message: "deleted").encodeResponse(for: req))
        }
        
        userGroup.post("restore") {req -> EventLoopFuture<Response> in
            let userToDelete = try req.content.decode(UserRequsts.DeleteUserRequest.self)
            return try self.deleteUserWith(req, id: userToDelete.id, shouldForceDelete: userToDelete.forceDelete)
                .transform(to: GenericResponse(message: "deleted").encodeResponse(for: req))
        }
    }
}

extension UserController {
    static func findUserby(id: UUID, req: Request) throws -> EventLoopFuture<User> {
        return User.find(id, on: req.db).unwrap(or: Abort.generateNotFound(objectNotFoundString: "user"))
    }
    
    func updateUserWith(_ req: Request, id: UUID, name: String) throws -> EventLoopFuture<User> {
        return try UserController.findUserby(id: id, req: req)
            .flatMap({ user -> EventLoopFuture<User> in
                user.name = name
                return user.update(on: req.db).transform(to: user)
        })
    }
    
    func deleteUserWith(_ req: Request, id: UUID, shouldForceDelete: Bool = false, shouldCascade: Bool = true) throws -> EventLoopFuture<Void> {
        
        let deleteUser = {
            try UserController.findUserby(id: id, req: req).flatMap({$0.delete(force: shouldForceDelete, on: req.db)})
        }
        
        let deleteTodos = {
            try TodoController.deleteAllTodosWith(req, userId: id, shouldForceDelete: shouldForceDelete, shouldCascade: shouldCascade)
        }
        
        if shouldCascade {
            let _ = try deleteTodos()
        }
        return try deleteUser()
    }
    
    func restoreUserWith(_ req: Request, id: UUID) throws -> EventLoopFuture<Void> {
        return User.query(on: req.db).filter(\.$id == id).withDeleted().first()
            .unwrap(or:  Abort.generateNotFound(objectNotFoundString: "user"))
            .flatMap({$0.restore(on: req.db)})
    }
}
