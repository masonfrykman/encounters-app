//
//  ViewController.swift
//  Encounter
//
//  Created by Mason Frykman on 9/17/26.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, ScanManagerViewer {
    var titleLbl: UILabel!
    var btnStart, btnEnd: UIButton!
    var quickStatus: UILabel!
    
    var tbox: UITextView!
    
    var btnToConfig: UIButton!
    var configPage: ConfigViewController?
    
    var scanMgr: ScanManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        titleLbl = UILabel()
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.text = "Encounter"
        titleLbl.font = .systemFont(ofSize: 24, weight: .heavy)
        
        btnStart = UIButton()
        btnStart.translatesAutoresizingMaskIntoConstraints = false
        btnStart.configuration = .prominentGlass()
        btnStart.setTitle("Start", for: .normal)
        btnStart.addTarget(nil, action: #selector(startScan(_:)), for: .primaryActionTriggered)
        btnStart.isEnabled = false
        
        btnEnd = UIButton()
        btnEnd.translatesAutoresizingMaskIntoConstraints = false
        btnEnd.configuration = .glass()
        btnEnd.setTitle("End", for: .normal)
        btnEnd.addTarget(nil, action: #selector(stopScan(_:)), for: .primaryActionTriggered)
        btnEnd.isEnabled = false
        
        btnToConfig = UIButton()
        btnToConfig.translatesAutoresizingMaskIntoConstraints = false
        btnToConfig.configuration = .glass()
        btnToConfig.setTitle("Config", for: .normal)
        btnToConfig.addTarget(nil, action: #selector(showConfigPage(_:)), for: .primaryActionTriggered)
        
        quickStatus = UILabel()
        quickStatus.text = "Everything's fine."
        quickStatus.font = .systemFont(ofSize: 16)
        quickStatus.translatesAutoresizingMaskIntoConstraints = false
        
        tbox = UITextView()
        tbox.translatesAutoresizingMaskIntoConstraints = false
        tbox.isEditable = false
        tbox.isScrollEnabled = true
        
        view.addSubview(titleLbl)
        view.addSubview(btnStart)
        view.addSubview(btnEnd)
        view.addSubview(btnToConfig)
        view.addSubview(quickStatus)
        view.addSubview(tbox)
        
        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            titleLbl.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            titleLbl.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            
            btnStart.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 10),
            btnStart.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            
            btnEnd.topAnchor.constraint(equalTo: btnStart.topAnchor),
            btnEnd.leftAnchor.constraint(equalTo: btnStart.rightAnchor, constant: 5),
            
            btnToConfig.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            btnToConfig.topAnchor.constraint(equalTo: btnStart.topAnchor),
            
            quickStatus.topAnchor.constraint(equalTo: btnStart.bottomAnchor, constant: 10),
            quickStatus.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            quickStatus.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            
            tbox.topAnchor.constraint(equalTo: quickStatus.bottomAnchor, constant: 10),
            tbox.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            tbox.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            tbox.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
        
        if scanMgr == nil {
            scanMgr = ScanManager(delegate: self)
        }
    }
    /*
    func scannerRecievedPeripheral(_ scanner: Scanner, peripheral: CBPeripheral, rssi: NSNumber) {
        DispatchQueue.main.async {
            self.tbox.text.append("\(peripheral.name ?? "<unnamed>"), UUID:\(peripheral.identifier), RSSI: \(rssi)")
        }
    }*/
    
    @objc private func showConfigPage(_ sender: Any?) {
        if configPage == nil {
            configPage = ConfigViewController()
        }
        
        navigationController?.pushViewController(configPage!, animated: true)
    }
    
    @objc private func startScan(_ sender: Any?) {
        btnStart.isEnabled = false
        btnEnd.isEnabled = true
        btnEnd.configuration = .prominentGlass()
        
        // copy over info from the config page over to the reporter
        if let configPage = configPage {
            var vals = configPage.values()
            if vals.0 == nil || vals.0!.isEmpty {
                vals.0 = "10.9.212.72"
            }
            
            Reporter.serverAddress = "http://\(vals.0 ?? "10.9.212.72"):\(vals.1)"
            
            if let psk = vals.2 {
                NSLog(psk)
                Reporter.psk = psk
            }
            
            ScanManager.deviceID = configPage.deviceId()
        }
        
        NSLog(Reporter.serverAddress)
        
        scanMgr.start()
    }
    
    @objc private func stopScan(_ sender: Any?) {
        scanMgr.stop()
        btnEnd.configuration = .glass()
        btnEnd.isEnabled = false
        
        btnStart.configuration = .prominentGlass()
        btnStart.isEnabled = true
    }
    
    // ScanManager delegate functions
    
    func scanManagerBluetoothUnsupported(_ manager: ScanManager) {
        DispatchQueue.main.async {
            self.tbox.text = "FATAL ERROR! Bluetooth is unsupported on this device."
            self.tbox.textColor = .red
            self.btnEnd.isEnabled = false
            self.btnStart.isEnabled = false
        }
    }
    
    func scanManagerBluetoothReady(_ manager: ScanManager) {
        DispatchQueue.main.async {
            self.tbox.text.append("Ready\n")
            self.btnStart.isEnabled = true
        }
    }
    
    func scanManagerEntry(_ manager: ScanManager, peripheral: CBPeripheral, rssi: NSNumber) {
        DispatchQueue.main.async {
            self.tbox.text = "[DISCOVER] \(peripheral.identifier.uuidString)\n\tname: \(peripheral.name ?? "")\n\tRSSI: \(rssi)\n" + self.tbox.text // prepend text
        }
    }
    
    func scanManagerNotifyError(error message: String) {
        DispatchQueue.main.async {
            self.quickStatus.text = message
            self.quickStatus.textColor = .red
        }
    }
    
    func scanManagerUpdateMessage(_ message: String) {
        DispatchQueue.main.async {
            self.quickStatus.text = message;
            self.quickStatus.textColor = .white
        }
    }
}

