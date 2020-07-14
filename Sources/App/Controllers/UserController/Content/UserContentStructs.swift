//
//  UserContentStructs.swift
//  
//
//  Created by Tyler Wells on 7/12/20.
//

import Vapor
import Fluent

struct UserRouteResponse: Content {
    let user: UserResponse
    let message: String
}

struct UserResponse: Content {
    let id: UUID?
    let name: String
    
    init(user: User) {
        self.id = user.id
        self.name = user.name
    }
}

struct UserRequsts {
    struct UpdateUserRequest: Decodable {
        let id: UUID
        let name: String
    }

    struct DeleteUserRequest: Decodable {
        let id: UUID
        let forceDelete: Bool = false
    }

    struct CreateUserModel: Decodable {
        let name: String
    }
}
