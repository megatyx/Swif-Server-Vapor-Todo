//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/14/20.
//

import Vapor

struct ChecklistItemRequests {
    struct CreateRequest: Decodable {
        let name: String
        let isDone: Bool = false
        let todoID: UUID
    }
    
    struct UpdateRequest: Decodable {
        let name: String
        let isDone: Bool = false
        let itemID: UUID
    }
    
    struct DeleteRequest: Decodable {
        let itemID: UUID
        let shouldForceDelete = false
    }
}

struct ChecklistRouteResponse: Content {
    let message: String
    let checklistItem: ChecklistItem
}
