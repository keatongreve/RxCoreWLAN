//
//  NetworkStateObservable.swift
//  RxNetworking
//
//  Created by Keaton on 11/21/18.
//  Copyright © 2018 Keaton. All rights reserved.
//

import Cocoa
import CoreWLAN
import RxCocoa
import RxSwift

class RxCWEventDelegateProxy : DelegateProxy<CWWiFiClient, CWEventDelegate>, DelegateProxyType, CWEventDelegate {

    public weak private(set) var client: CWWiFiClient?

    init(client: CWWiFiClient) {
        self.client = client
        super.init(parentObject: client, delegateProxy: RxCWEventDelegateProxy.self)
        try! self.client?.startMonitoringEvent(with: .ssidDidChange)
        try! self.client?.startMonitoringEvent(with: .linkQualityDidChange)
    }

    public static func registerKnownImplementations() {
        self.register { RxCWEventDelegateProxy(client: $0) }
    }

    fileprivate let ssidSubject = PublishSubject<String?>()
    fileprivate let qualitySubject = PublishSubject<(Int, Double)>()

    // MARK: - CWEventDelegate

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        ssidSubject.on(.next(self.client?.interface()?.ssid()))
    }

    func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) {
        qualitySubject.on(.next((rssi, transmitRate)))
    }


    // MARK: Delegate proxy methods

    /// For more information take a look at `DelegateProxyType`.
    open class func currentDelegate(for object: ParentObject) -> CWEventDelegate? {
        return object.delegate as? CWEventDelegate
    }

    /// For more information take a look at `DelegateProxyType`.
    open class func setCurrentDelegate(_ delegate: CWEventDelegate?, to object: ParentObject) {
        object.delegate = delegate
    }


}

extension Reactive where Base: CWWiFiClient {

    public var delegate: DelegateProxy<CWWiFiClient, CWEventDelegate> {
        return RxCWEventDelegateProxy.proxy(for: base)
    }

    public var ssid: Observable<String?> {
        let delegate = RxCWEventDelegateProxy.proxy(for: base)
        return Observable.deferred {
            let ssid = delegate.client?.interface()?.ssid()
            return delegate.ssidSubject.asObservable().startWith(ssid)
        }
    }

    public var linkQuality: Observable<(Int, Double)> {
        let delegate = RxCWEventDelegateProxy.proxy(for: base)
        return Observable.deferred {
            let interface = delegate.client?.interface()
            let rssi = interface?.rssiValue() ?? 0
            let transmitRate = interface?.transmitRate() ?? 0.0
            return delegate.qualitySubject.asObservable().startWith((rssi, transmitRate))
        }
    }

}

