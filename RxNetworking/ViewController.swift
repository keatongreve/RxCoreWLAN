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

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        CWWiFiClient.shared().delegate = self

        let cwRx = CWWiFiClient.shared().rx
        Observable
            .combineLatest(cwRx.ssid, cwRx.linkQuality) { ssid, tup -> (String?, Int, Double) in
                let (rssi, transmitRate) = tup
                return (ssid, rssi, transmitRate)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] ssid, rssi, transmitRate in
                let data: [String: Any] = [
                    "SSID": ssid ?? "disconnected",
                    "RSSI": rssi,
                    "TransmitRate": transmitRate,
                ]
                self?.textViewContents.string = String(describing: data)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - CWEventDelegate

    // Dev note: Generally not useful in conjunction with the subscribe code above.
    // This is to demonstrate how _forwardToDelegate works in RxCocoa.

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        print("original delegate received ssid change for network interface \(interfaceName)")
    }

    func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) {
        print("original delegate received link quality change for network interface \(interfaceName)")
    }

}

