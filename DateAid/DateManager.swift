//
//  DateManager.swift
//  DateAid
//
//  Created by Aaron Williamson on 10/2/16.
//  Copyright © 2016 Aaron Williamson. All rights reserved.
//

import Foundation
import Contacts
import CoreData

class DateManager {

    var managedContext: NSManagedObjectContext = CoreDataStack().managedObjectContext
    var contacts: [CNContact?] = ContactManager().contacts

    var storedDates: [Date?] {
        return managedContext.fetch()
    }
    
    func syncDates() {
        createBirthdays()
        createAnniversaries()
        managedContext.trySave()
    }
    
    func createBirthdays() {
        contacts.forEach { contact in
            date(for: contact, of: .birthday)
        }
    }
    
    func createAnniversaries() {
        contacts.forEach { contact in
            date(for: contact, of: .anniversary)
        }
    }
    
    func createHolidays() {
        guard let path = Bundle.main.path(forResource: "Holidays", ofType: "plist"),
        let dict = NSDictionary(contentsOfFile: path) as? [String: Foundation.Date] else {
            return
        }
        
        for (givenName, givenDate) in dict {
            
            let exists = storedDates.contains { date -> Bool in
                return date?.name == givenName && date?.type == DateType.holiday.rawValue
            }
            
            if !exists {
                if let entity = NSEntityDescription.entity(forEntityName: "Date", in: managedContext) {
                    let date = Date(entity: entity, insertInto: managedContext)
                    date.type            = DateType.holiday.rawValue
                    date.name            = givenName
                    date.abbreviatedName = givenName
                    date.date            = givenDate
                    date.equalizedDate   = givenDate.formatted
                }
            }
        }
    }
    
    func date(for contact: CNContact?, of type: DateType) {
        
        let exists = storedDates.contains { date -> Bool in
            return date?.name == contact?.fullName && date?.type == type.rawValue
        }
        
        if !exists {
            if let entity = NSEntityDescription.entity(forEntityName: "Date", in: managedContext),
                let contact = contact {
                
                let date = Date(entity: entity, insertInto: managedContext)
                date.type            = type.rawValue
                date.name            = contact.fullName
                date.abbreviatedName = contact.abbreviatedName
                
                switch type {
                case .birthday:
                    date.date            = contact.birthdate
                    date.equalizedDate   = contact.birthdate?.formatted
                case .anniversary:
                    date.date            = contact.anniversary
                    date.equalizedDate   = contact.anniversary?.formatted
                case .holiday:
                    return // Fix later
                }
                
                if let address = contact.postalAddress {
                    date.address = create(address, for: date)
                }
            }
        }
    }
    
    func create(_ postalAddress: CNPostalAddress, for date: Date) -> Address? {
        
        if let entity = NSEntityDescription.entity(forEntityName: "Date", in: managedContext) {
            let address = Address(entity: entity, insertInto: managedContext)
            address.date = date
            address.street = postalAddress.street
            address.region = "\(postalAddress.city) \(postalAddress.state), \(postalAddress.postalCode)"
            return address
        } else {
            return nil
        }
    }
}
