//
//  Reporter.swift
//  Encounter
//
//  Created by Mason Frykman on 9/19/26.
//

import Foundation
import Combine

class Reporter: Thread {
    private var unsentData: [String] = []
    private var stagingArea: [String]?

    private var reportThread: Thread!
    
    private var repeatEvery: TimeInterval!
    
    static var serverAddress = "http://10.9.212.72:41801"
    static var psk = ""
    
    weak var notifier: ScanManager?
    
    override func main() {
        guard !Thread.isMainThread else { return }
        
        while(!Thread.current.isCancelled) {
            Thread.sleep(forTimeInterval: repeatEvery)
            report()
        }
    }
    
    init(reportEvery timeInterval: TimeInterval) {
        super.init()
        repeatEvery = timeInterval
    }
    
    // MARK: Data entry
    
    func add(_ data: String) {
        unsentData.append(data)
    }
    
    func add(report: Report) {
        unsentData.append(report.serverFormat())
    }
    
    // MARK: Reporting
    
    private func concat(_ lines: [String]) -> String {
        var concatenated = ""
        for line in lines {
            concatenated += "\(line)\u{02FA}"
        }
        
        return concatenated
    }
    
    private func handleFailedData(_ failures: [Int], stagingAreaFailure: [String]) {
        for failureIndex in failures {
            guard stagingAreaFailure.count > failureIndex else { continue }
            
            unsentData.append(stagingAreaFailure[failureIndex])
        }
    }
    
    private func sendReport() {
        stagingArea = unsentData
        unsentData = []
        let schema = stagingArea!.joined(separator: "<MVF>")
        let data = schema.data(using: .utf8)
        
        NSLog("SENDING REPORT")
        
        // TODO: actually send the data
        
        let url = URL(string: Reporter.serverAddress + "/readings")!
        let urlSession = URLSession(configuration: .ephemeral)
        
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.httpBody = data
        req.setValue(Reporter.psk, forHTTPHeaderField: "X-PSK")
        NSLog(Reporter.psk)
        // TODO: implement a PSK
        
        let task = urlSession.dataTask(with: req) { [notifier, stagingArea, handleFailedData] data, response, err in
            if let err = (err as? URLError) {
                NSLog("\(type(of: err))")
                
                notifier?.notifyErrorToUI("Report URLError code \(err.code)")
                
                return
            }
            
            guard let response = (response as? HTTPURLResponse) else { return }
            
            if response.statusCode != 200 {
                notifier?.notifyErrorToUI("Report failure! \(response.statusCode)")
                return
            }
            
            guard let hasFailure = response.value(forHTTPHeaderField: "X-HasFailures") else {
                // assume there are no failures. all done!
                notifier?.updateUIStatus("Successful report at \(Date.now.ISO8601Format())")
                return
            }
            
            if hasFailure == "YES" && data != nil {
                // TODO: add the failed reports back to the unsent data
                // TODO: notify the UI
                
                
                var failures: [Int] = {
                    let dataStr = String(data: data!, encoding: .utf8)
                    guard let dataStr = dataStr else { return [] }
                    
                    let lines = dataStr.split(separator: "\n")
                    guard lines.count != 0 else { return [] }
                    
                    var col: [Int] = []
                    for line in lines {
                        let l = line.split(separator: "::")
                        guard !l.isEmpty else { continue }
                        
                        let i = Int(l.first!)
                        guard let i = i else { continue }
                        
                        col.append(i)
                    }
                    
                    return col
                }()
                
                if let stagingArea = stagingArea {
                    handleFailedData(failures, stagingArea)
                }
            }
            
            notifier?.updateUIStatus("Partial successful report at \(Date.now.ISO8601Format())")
        }
        
        stagingArea = nil
        
        task.resume()
    }
    
    private func report() -> Bool {
        if(stagingArea != nil) {
            // already in the process of reporting.
            return false
        }
        
        sendReport()
        return true
    }
    
    /*func setSchedule(to timeInterval: DispatchTimeInterval?) {
        if let reportSchedule = reportSchedule {
            reportSchedule.cancel()
        }
        
        if let timeInterval = timeInterval {
            // schedules the report function to run every [timeInterval].
            reportSchedule = reportDispatch.schedule(after: .init(.now()).advanced(by: .init(timeInterval)), interval: .init(timeInterval), tolerance: .seconds(1), options: .none, { self.report() })
        } else {
            reportSchedule = nil
        }
    }*/
}
