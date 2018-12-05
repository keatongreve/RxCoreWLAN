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

class ViewController: NSViewController {

    @IBOutlet private var textViewContents: NSTextView!

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

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

}

