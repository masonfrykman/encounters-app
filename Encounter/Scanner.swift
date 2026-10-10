//
//  Scanner.swift
//  Encounter
//
//  Created by Mason Frykman on 9/18/26.
//

import Foundation
import CoreBluetooth

protocol ScanDelegate {
    func scannerRecievedPeripheral(_ scanner: Scanner, peripheral: CBPeripheral, rssi: NSNumber);
    func scannerUnsupported(_ scanner: Scanner);
    func scannerReady(_ scanner: Scanner);
}

class Scanner: NSObject, CBCentralManagerDelegate {
    var currentState: CBManagerState = .unknown
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("STATE: \(central.state)")
        
        currentState = central.state
        
        switch(central.state) {
        case .poweredOn:
            NSLog("STATE powered on")
            delegate?.scannerReady(self)
        case .poweredOff:
            NSLog("STATE powered off")
        case .resetting:
            NSLog("STATE resetting")
        case .unauthorized:
            NSLog("STATE unauthorized")
        case .unknown:
            NSLog("STATE unknown")
        case .unsupported:
            NSLog("STATE unsupported")
            // Notify the user
            delegate?.scannerUnsupported(self)
        default:
            NSLog("STATE default switch case :: \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // found a device!
        
        //NSLog("NEW DEVICE: \(peripheral.name ?? "[no name]") (\(peripheral.identifier)), RSSI \(RSSI)")
        delegate?.scannerRecievedPeripheral(self, peripheral: peripheral, rssi: RSSI)
    }
    
    private var btScr: CBCentralManager!
    var delegate: ScanDelegate?
    
    override init() {
        super.init()
        btScr = CBCentralManager(delegate: self, queue: .global(qos: .userInitiated))
    }
    
    func start() {
        guard currentState != .unsupported else {
            delegate?.scannerUnsupported(self)
            return
        }
        
        btScr.scanForPeripherals(withServices: nil)
    }
    
    func stop() {
        if(btScr.isScanning) {
            btScr.stopScan()
        }
    }
}
