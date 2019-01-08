//
//  ViewController.swift
//  RxNetworking
//
//  Created by Keaton on 11/21/18.
//  Copyright © 2018 Keaton. All rights reserved.
//

import Cocoa
import CoreWLAN
import RxCocoa
import RxSwift

class ViewController: NSViewController, CWEventDelegate {

    @IBOutlet private var textViewContents: NSTextView!
    @IBOutlet weak var textViewUpdateViaDelegate: NSTextView!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        CWWiFiClient.shared().delegate = self

        let cwRx = CWWiFiClient.shared().rx
        Observable
            .combineLatest(cwRx.ssid, cwRx.linkQuality) { ssid, linkQuality -> String in
                let (rssi, transmitRate) = linkQuality
                let data: [String: Any] = [
                    "SSID": ssid ?? "disconnected",
                    "RSSI": rssi,
                    "TransmitRate": transmitRate,
                    ]
                return String(describing: data)
            }
            .map { "Rx binding: \($0)" }
            .observeOn(MainScheduler.instance)
            .bind(to: self.textViewContents.rx.string)
            .disposed(by: disposeBag)

        initWifiValues()
    }

    // MARK: - CWEventDelegate

    // Dev note: Generally not useful in conjunction with the subscribe code above.
    // This is to demonstrate how _forwardToDelegate works in RxCocoa.

    private var ssid: String? = nil
    private var rssi: Int = 0
    private var transmitRate: Double = 0

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        self.ssid = CWWiFiClient.shared().interface()?.ssid()
        DispatchQueue.main.async {
            self.updateText()
        }
    }

    func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) {
        self.rssi = rssi
        self.transmitRate = transmitRate
        DispatchQueue.main.async {
            self.updateText()
        }
    }

    private func initWifiValues() {
        let interface = CWWiFiClient.shared().interface()
        self.ssid = interface?.ssid()
        self.rssi = interface?.rssiValue() ?? 0
        self.transmitRate = interface?.transmitRate() ?? 0
        updateText()
    }

    private func updateText() {
        let data: [String: Any] = [
            "SSID": self.ssid ?? "disconnected",
            "RSSI": self.rssi,
            "TransmitRate": self.transmitRate,
        ]
        self.textViewUpdateViaDelegate.string = "Delegate binding: \(data)"
    }

}

