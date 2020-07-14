//
//  File.swift
//  
//
//  Created by Tyler Wells on 7/10/20.
//

import Vapor

struct InitLifeCycleHandler: LifecycleHandler {
    // Called before application boots.
    func willBoot(_ app: Application) throws {
        app.logger.info("Todo's Server Started")
    }
}
