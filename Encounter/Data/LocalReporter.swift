//
//  LocalReporter.swift
//  Encounter
//
//  Created by Mason Frykman on 9/20/26.
//

import Foundation
import Combine

class LocalReporter {
    var reports: [Report] = []
    
    func save(filename: String, headers: Bool = true) -> Bool {
        NSLog("SAVING!")
        
        let snap = reports
        reports = []
        
        // Collate the list of reports
        var output = headers ? Report.csvHeader() : ""
        
        for report in snap {
            output += report.genericFormat(",") + "\n"
        }
        
        // Write to disk
        let data = Data(output.utf8)
        let url = URL.documentsDirectory.appending(path: filename)
        
        do {
            try data.write(to: url, options: [.withoutOverwriting, .noFileProtection])
        } catch {
            NSLog(error.localizedDescription)
            // prepend the failed reports
            let rs = reports
            reports = snap
            reports.append(contentsOf: rs)
            return false
        }
        
        return true
    }
}

class PeriodicLocalReporter: Thread {
    weak var localReporter: LocalReporter?
    var interval: TimeInterval = 60
    
    override func main() {
        guard !Thread.isMainThread else { return }
        
        while(!Thread.current.isCancelled) {
            Thread.sleep(forTimeInterval: interval)
            guard !Thread.current.isCancelled else { return } // time interval can be really long.
            guard let localReporter = localReporter else {
                Thread.current.cancel()
                continue
            }
            
            _ = localReporter.save(filename: "encounters-\(Date.now.timeIntervalSince1970).csv", headers: true)
        }
    }
}
