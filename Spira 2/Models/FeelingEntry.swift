//
//  FeelingEntry.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import Foundation
import CoreData

@objc(FeelingEntry)
public final class FeelingEntry: NSManagedObject {}

extension FeelingEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeelingEntry> {
        NSFetchRequest<FeelingEntry>(entityName: "FeelingEntry")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var stateRaw: String
}
