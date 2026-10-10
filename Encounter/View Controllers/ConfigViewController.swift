//
//  ConfigViewController.swift
//  Encounter
//
//  Created by Mason Frykman on 9/20/26.
//

import UIKit

class ConfigViewController: UIViewController {
    private var host, port, psk, deviceID: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        navigationItem.title = "Configuration"
        
        // initialize text fields
        host = UITextField()
        host.translatesAutoresizingMaskIntoConstraints = false
        host.placeholder = "Report Address"
        host.borderStyle = .roundedRect
        
        port = UITextField()
        port.translatesAutoresizingMaskIntoConstraints = false
        port.placeholder = "Report Port (default 41801)"
        port.borderStyle = .roundedRect
        port.keyboardType = .numberPad
        
        psk = UITextField()
        psk.translatesAutoresizingMaskIntoConstraints = false
        psk.placeholder = "Report Pre-Shared key"
        psk.borderStyle = .roundedRect
        
        deviceID = UITextField()
        deviceID.translatesAutoresizingMaskIntoConstraints = false
        deviceID.placeholder = "Device Identifier"
        deviceID.borderStyle = .roundedRect
        
        // attach fields
        view.addSubview(host)
        view.addSubview(port)
        view.addSubview(psk)
        view.addSubview(deviceID)
        
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            host.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            host.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            
            port.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            port.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            port.topAnchor.constraint(equalTo: host.bottomAnchor, constant: 5),
            
            psk.topAnchor.constraint(equalTo: port.bottomAnchor, constant: 5),
            psk.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            psk.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            
            deviceID.topAnchor.constraint(equalTo: psk.bottomAnchor, constant: 5),
            deviceID.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            deviceID.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
        ])
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resignAllKeyboards(gesture:))))
        
        loadFromDefaults()
    }
    
    /*override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        saveToDefaults()
        super.dismiss(animated: flag, completion: completion)
    }*/
    
    override func viewWillDisappear(_ animated: Bool) {
        NSLog("view disappear")
        saveToDefaults()
        super.viewWillDisappear(animated)
    }
    
    func values() -> (String?, Int, String?) {
        let pt = port.text ?? "41801"
        return (host.text, (try? Int(pt, format: .number)) ?? 41801, psk.text)
    }
    
    func deviceId() -> String {
        return deviceID.text ?? ""
    }
    
    func saveToDefaults() {
        if let hostV = host.text {
            UserDefaults.standard.set(hostV, forKey: "host")
        }
        if let portV = port.text {
            UserDefaults.standard.set(portV, forKey: "port")
        }
        if let pskV = psk.text {
            UserDefaults.standard.set(pskV, forKey: "psk")
        }
        if let did = deviceID.text {
            UserDefaults.standard.set(did, forKey: "deviceId")
        }
    }
    
    func loadFromDefaults() {
        if let h = UserDefaults.standard.string(forKey: "host") {
            host.text = h
        }
        if let p = UserDefaults.standard.string(forKey: "port") {
            port.text = p
        }
        if let ps = UserDefaults.standard.string(forKey: "psk") {
            psk.text = ps
        }
        if let did = UserDefaults.standard.string(forKey: "deviceId") {
            deviceID.text = did
        }
    }
    
    @objc func resignAllKeyboards(gesture: UITapGestureRecognizer) {
        guard gesture.view != nil else { return }
        
        host.resignFirstResponder()
        port.resignFirstResponder()
        psk.resignFirstResponder()
        deviceID.resignFirstResponder()
    }
}
