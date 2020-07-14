//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/12/20.
//

import Vapor

struct GenericResponse: Content {
    let message: String
    let error: Bool = false
    
    init(message: String) {
        self.message = message
    }
}
