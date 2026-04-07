//
//  Persistence.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "SpiraStore", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let feelingEntry = NSEntityDescription()
        feelingEntry.name = "FeelingEntry"
        feelingEntry.managedObjectClassName = NSStringFromClass(FeelingEntry.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false

        let stateRawAttr = NSAttributeDescription()
        stateRawAttr.name = "stateRaw"
        stateRawAttr.attributeType = .stringAttributeType
        stateRawAttr.isOptional = false

        feelingEntry.properties = [idAttr, dateAttr, stateRawAttr]
        model.entities = [feelingEntry]
        return model
    }
}
