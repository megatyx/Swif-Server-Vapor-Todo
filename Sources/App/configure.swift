import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    //JOBS
    
    //LifeCycle Handlers
    app.lifecycle.use(InitLifeCycleHandler())
    
    // register routes
    try routes(app)
    
    //Databases
    /* *********** TYLER'S NOTE ************
    The following has been set up for Postgres
    Replace the ## with your database server Configuration
    let hostName:     String =    ##HOST_NAME##   (you can put "localhost" for your local Machine)
    let portNumber:   Int    =    ##PORT_NUMBER## (by default it's 5432 for postgres)
    let username:     String =    ##username##    (by default, on your local machine, it's your computer's username)
    let password:     String =    ##password##    (by default it's nil)
    let databaseName: String =    ##database##    (by default it's your local machine's computer's username)
    let postgresConfiguration = PostgresConfiguration(hostname: hostName,
                                                      port: portNumber,
                                                      username: username,
                                                      password: password,
                                                      database: databaseName)
    app.databases.use(.postgres(configuration: postgresConfiguration), as: .psql)
     */
    
    //Migreations
    app.migrations.add(UserMigration())
    app.migrations.add(TodoMigration())
    app.migrations.add(ChecklistItemsMigration())
    
    //AUTO MIGRATE
    //NOTE: ****** Only uncomment if working with a blank database ******
    //try app.autoMigrate().wait()
}
