//
//  Report.swift
//  Encounter
//
//  Created by Mason Frykman on 9/20/26.
//

import Foundation
import CoreLocation

struct Report {
    var timestamp: Date
    var reportingDevice: String
    var bluetoothId: String
    var bluetoothName: String?
    var rssi: NSNumber
    var location: CLLocation
    
    func serverFormat() -> String {
        return "\(timestamp.timeIntervalSince1970)|\(reportingDevice)|\(bluetoothId)|\(bluetoothName ?? "")|\(rssi)|\(location.coordinate.latitude)|\(location.coordinate.longitude)" // TODO: location
    }
    
    func genericFormat(_ seperator: String) -> String{
        return "\(timestamp.timeIntervalSince1970)\(seperator)\(reportingDevice)\(seperator)\(bluetoothId)\(seperator)\(bluetoothName ?? "")\(seperator)\(rssi)\(seperator)\(location.coordinate.latitude)\(seperator)\(location.coordinate.longitude)"
    }
    
    static func csvHeader() -> String {
        return "Timestamp,Reporting Device,Bluetooth ID,Bluetooth Name,RSSI,Latitude,Longitude\n"
    }
}
