//
//  OSDCoreDataStack.swift
//  Test
//
//  Created by Skylar Schipper on 6/11/14.
//  Copyright (c) 2014 OpenSky, LLC. All rights reserved.
//

import Foundation
import CoreData

class OSDCoreDataStack: NSObject {
    let OSDCoreDataErrorDomain = "OSDCoreDataErrorDomain"
    
    enum OSDCoreDataError: Int {
        case NoModel = 1
        case NoDatabaseURL = 2
    }
    
    var databaseURL: NSURL?
    var model: NSManagedObjectModel?
    var coordinator: NSPersistentStoreCoordinator?
    var context: NSManagedObjectContext?
    
    convenience init(path: String) {
        self.init(path: path, managedObjectModel: nil)
    }
    convenience init(path: String, managedObjectModelName: String) {
        let bundle = NSBundle.mainBundle()
        var URL: NSURL? = bundle.URLForResource(managedObjectModelName, withExtension: "mom")
        if !URL? {
            URL = bundle.URLForResource(managedObjectModelName, withExtension: "momd")
        }
        
        var model: NSManagedObjectModel? = nil
        
        if let modelURL = URL {
            model = NSManagedObjectModel(contentsOfURL: URL)
        }
        
        self.init(url: NSURL(fileURLWithPath: path), managedObjectModel: model)
    }
    convenience init(path: String, managedObjectModel: NSManagedObjectModel?) {
        self.init(url: NSURL(fileURLWithPath: path), managedObjectModel: managedObjectModel)
    }
    init(url: NSURL, managedObjectModel: NSManagedObjectModel?) {
        databaseURL = url
        model = managedObjectModel
    }
    
    func connect() -> Bool {
        var connectErr: NSError?
        let success = connect(&connectErr)
        if let error = connectErr {
            println("Connection Error: \(error)")
        }
        return success
    }
    func connect(error: NSErrorPointer) -> Bool {
        return connect(.MainQueueConcurrencyType, error: error)
    }
    func connect(concurencyType: NSManagedObjectContextConcurrencyType, error: NSErrorPointer) -> Bool {
        return connect(concurencyType, mergePolicy: NSErrorMergePolicy, error: error)
    }
    func connect(concurencyType: NSManagedObjectContextConcurrencyType, mergePolicy: AnyObject!, error: NSErrorPointer) -> Bool {
        if coordinator? && context? {
            return true
        }
        if !model? {
            if error {
                error.memory = NSError(domain: OSDCoreDataErrorDomain, code: OSDCoreDataError.NoModel.toRaw(), userInfo: nil)
            }
            return false
        }
        if !databaseURL? {
            if error {
                error.memory = NSError(domain: OSDCoreDataErrorDomain, code: OSDCoreDataError.NoDatabaseURL.toRaw(), userInfo: nil)
            }
            return false
        }
        
        let coord = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        var coordError: NSError?
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        if !coord.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: databaseURL, options: options, error: &coordError) {
            if let err = coordError {
                if error {
                    error.memory = err
                }
            }
            return false
        }
        
        coordinator = coord
        
        let ctx = NSManagedObjectContext(concurrencyType: concurencyType)
        ctx.persistentStoreCoordinator = coord
        ctx.mergePolicy = mergePolicy
        context = ctx
        
        return true
    }
    
    func performBlock(block: ((ctx: NSManagedObjectContext!) -> ())) {
        if let ctx = context {
            ctx.performBlock {
                block(ctx: ctx)
            }
        }
    }
    func performBlockAndWait(block: ((ctx: NSManagedObjectContext!) -> ())) {
        if let ctx = context {
            ctx.performBlockAndWait {
                block(ctx: ctx)
            }
        }
    }
    
    func save() -> Bool {
        var err: NSError?
        let success = save(&err)
        if let error = err {
            println("Save Error: \(error)")
        }
        return success
    }
    func save(error: NSErrorPointer) -> Bool {
        var success = false
        performBlockAndWait { ctx in
            if ctx.hasChanges {
                success = ctx.save(error)
            } else {
                success = true
            }
        }
        return success
    }
}
