//
//  Place+CoreDataProperties.swift
//  
//
//  Created by Geek on 5/3/19.
//
//

import Foundation
import CoreData
import UIKit

extension Place {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        return NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var desc: String?
    @NSManaged public var icon: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photo: UIImage?
    @NSManaged public var place_id: String?
    @NSManaged public var title: String?
    @NSManaged public var place: Place?
    @NSManaged public var places: NSSet?

}

// MARK: Generated accessors for places
extension Place {

    @objc(addPlacesObject:)
    @NSManaged public func addToPlaces(_ value: Place)

    @objc(removePlacesObject:)
    @NSManaged public func removeFromPlaces(_ value: Place)

    @objc(addPlaces:)
    @NSManaged public func addToPlaces(_ values: NSSet)

    @objc(removePlaces:)
    @NSManaged public func removeFromPlaces(_ values: NSSet)

}
