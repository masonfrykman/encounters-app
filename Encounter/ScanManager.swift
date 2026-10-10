//
//  ScanManager.swift
//  Encounter
//
//  Created by Mason Frykman on 9/19/26.
//

import CoreBluetooth
import CoreLocation

protocol ScanManagerViewer {
    func scanManagerBluetoothUnsupported(_ manager: ScanManager);
    func scanManagerBluetoothReady(_ manager: ScanManager);
    func scanManagerEntry(_ manager: ScanManager, peripheral: CBPeripheral, rssi: NSNumber);
    func scanManagerNotifyError(error message: String);
    func scanManagerUpdateMessage(_ message: String);
}

extension ScanManagerViewer {
    func scanManagerBluetoothReady(_ manager: ScanManager) {}
    func scanManagerEntry(_ manager: ScanManager, peripheral: CBPeripheral, rssi: NSNumber) {}
    func scanManagerNotifyError(error message: String) {}
}

class ScanManager: NSObject, CLLocationManagerDelegate, ScanDelegate {
    private let _scanner: Scanner = Scanner()
    private var _locationManager: CLLocationManager!
    
    private var _reporter: Reporter?
    private var _localReporter: LocalReporter!
    private var _localReporterPeriodic: PeriodicLocalReporter?
    static var deviceID: String = ""
    
    // prevents starting the scan before all components are ready
    private var locationReady = false
    private var btReady = false
    
    private var mostRecentLocation: CLLocation?
    
    var delegate: ScanManagerViewer?
    
    override init() {
        super.init()
        _scanner.delegate = self
        lmSetup()
        lrSetup()
    }
    
    init(delegate: ScanManagerViewer?) {
        super.init()
        _scanner.delegate = self
        self.delegate = delegate
        lmSetup()
        lrSetup()
    }
    
    private func lmSetup() {
        _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.distanceFilter = kCLDistanceFilterNone
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    
    private func lrSetup() {
        _localReporter = LocalReporter()
    }
    
    func saveEvery(_ timeInterval: TimeInterval) {
        if let _localReporterPeriodic = _localReporterPeriodic {
            _localReporterPeriodic.interval = timeInterval
            return
        }
        
        _localReporterPeriodic = PeriodicLocalReporter()
        _localReporterPeriodic!.interval = timeInterval
        _localReporterPeriodic!.localReporter = _localReporter
        _localReporterPeriodic!.start()
    }
    
    // self methods
    func start() -> Bool {
        if(!locationReady || !btReady) {
            return false
        }
        
        _scanner.start()
        bootkickLocation()
        //_reporter = Reporter(reportEvery: 10)
        //_reporter!.start()
        
        saveEvery(300)
        return true
    }
    
    func stop() {
        _scanner.stop()
        //_reporter!.cancel()
        //_reporter = nil
        
        _localReporterPeriodic?.cancel()
        _localReporter.save(filename: "encounters-\(Date.now.timeIntervalSince1970).csv", headers: true)
    }
    
    private func handlePeripheral(_ peripheral: CBPeripheral, rssi: NSNumber) {
        // Tell the delegate
        delegate?.scanManagerEntry(self, peripheral: peripheral, rssi: rssi)
        
        // Tell the reporter
        // Before telling the reporter, we need to somehow get the coordinates of the device.
        let locationNow = mostRecentLocation
        guard let locationNow = locationNow else { return } // TODO: handle this error
        
        // TODO: get a device ID from the user
        let report = Report(timestamp: Date(timeIntervalSinceNow: .zero), reportingDevice: ScanManager.deviceID.isEmpty ? "unspecified" :  ScanManager.deviceID, bluetoothId: peripheral.identifier.uuidString, bluetoothName: peripheral.name, rssi: rssi, location: locationNow)
        
        if let _reporter = _reporter {
            _reporter.add(report: report)
        }
        
        _localReporter.reports.append(report)
    }
    
    private func bootkickLocation() {
        _locationManager.startUpdatingLocation()
    }
    
    func notifyErrorToUI(_ message: String) {
        delegate?.scanManagerNotifyError(error: message)
    }
    
    func updateUIStatus(_ message: String) {
        delegate?.scanManagerUpdateMessage(message)
    }
    
    // MARK: ScanDelegate methods
    func scannerRecievedPeripheral(_ scanner: Scanner, peripheral: CBPeripheral, rssi: NSNumber) {
        handlePeripheral(peripheral, rssi: rssi)
    }
    
    func scannerUnsupported(_ scanner: Scanner) {
        // Core Bluetooth is unsupported on the device, need to notify the user.
        delegate?.scanManagerBluetoothUnsupported(self)
    }
    
    func scannerReady(_ scanner: Scanner) {
        btReady = true
        delegate?.scanManagerBluetoothReady(self)
    }
    
    // MARK: CLLocationManagerDelegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager == _locationManager else { return }
        
        switch(manager.authorizationStatus) {
        case .notDetermined:
            DispatchQueue.main.async {
                self._locationManager.requestAlwaysAuthorization()
            }
            NSLog("Requested")
        case .authorizedWhenInUse:
            // TODO: tell the UI
            DispatchQueue.main.async {
                self._locationManager.requestAlwaysAuthorization()
            }
            locationReady = false
            NSLog("WHEN IN USE")
        case .authorizedAlways:
            locationReady = true
            NSLog("ALWAYS")
        case .denied:
            // TODO: tell the UI
            locationReady = false
            NSLog("DENIED LOCATION")
        case .restricted:
            // TODO: tell the UI
            locationReady = false
            NSLog("LOCATION RESTRICTED")
        default:
            locationReady = false
            NSLog("UNKNOWN CLLOCMGR STATE")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard manager == _locationManager else { return }
        
        mostRecentLocation = locations.last
    }
    
    
}
