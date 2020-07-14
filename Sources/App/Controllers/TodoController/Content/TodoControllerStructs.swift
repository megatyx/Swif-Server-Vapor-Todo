//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/14/20.
//

import Vapor

struct TodoResponse: Content {
    let message: String
    let todo: Todo
}

struct TodoRequest {
    struct CreateRequest: Decodable {
        let name: String
        let description: String?
        let userID: UUID
    }

    struct UpdateRequest: Decodable {
        let name: String
        let description: String?
        let todoID: UUID
    }

    struct DeleteRequest: Decodable {
        let todoID: UUID
        let shouldCascade: Bool = true
        let shouldForceDelete: Bool = false
    }
}
