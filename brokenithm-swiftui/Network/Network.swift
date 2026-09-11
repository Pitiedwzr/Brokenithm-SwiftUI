//
//  Network.swift
//  brokenithm-swiftui
//
//  Created by Owen Cramer on 8/30/24.
//

import Foundation
import Network

@Observable
class Listener {
    var listener: NWListener?
    var status = "Not Connected"
    var connection: NWConnection?
    var ledArray: [UInt8] = Array(repeating: 0, count: 96)
    var airOn: Bool = false
    var testPressed: UInt8 = 0
    var servicePressed: UInt8 = 0
    var lastLane: [UInt8] = Array(repeating: 0, count: 32)
    var lastAir: [UInt8] = Array(repeating: 0, count: 6)

    init() {
        start()
    }

    func start() {
        do {
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.enableKeepalive = true
            tcpOptions.keepaliveIdle = 2

            let params = NWParameters(tls: nil, tcp: tcpOptions)
            params.allowLocalEndpointReuse = true
            params.includePeerToPeer = true

            let listener = try NWListener(using: params, on: 24864)
            listener.service = .init(type: "_brokenithm._tcp.")

            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("Listener ready on port 24864")
                case .failed(let error):
                    print("Listener failed: \(error)")
                    self?.status = "Failed"
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] conn in
                guard let self = self else { return }
                self.connection?.cancel()
                self.connection = conn
                self.setupConnection(conn)
            }

            self.listener = listener
            listener.start(queue: .main)
        } catch {
            print("Failed to start listener: \(error)")
            status = "Error"
        }
    }

    private func setupConnection(_ conn: NWConnection) {
        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.status = "Connected"
                self.sendInitialMessage()
                self.enableAir(enabled: self.airOn)
                self.readNextPacket()
            case .cancelled, .failed:
                self.status = "Not Connected"
                self.connection = nil
                self.ledArray = Array(repeating: 0, count: 96)
            default:
                break
            }
        }
        conn.start(queue: .main)
    }

    func restart() {
        connection?.cancel()
        connection = nil
        listener?.cancel()
        listener = nil
        status = "Not Connected"
        start()
    }

    func sendInitialMessage() {
        guard let conn = connection else { return }
        let byteArray: [UInt8] = [3, 87, 69, 76]
        conn.send(content: byteArray, completion: .contentProcessed { error in
            if let sad = error {
                print("sender: send failed, error: \(sad)")
            }
        })
    }

    func insertCoin() {
        guard let conn = connection else { return }
        let byteArray: [UInt8] = [4, 70, 78, 67, 1]
        conn.send(content: byteArray, completion: .contentProcessed { error in
            if let sad = error {
                print("sender: send failed, error: \(sad)")
            }
        })
    }

    func tapCard() {
        guard let conn = connection else { return }
        let byteArray: [UInt8] = [4, 70, 78, 67, 2]
        conn.send(content: byteArray, completion: .contentProcessed { error in
            if let sad = error {
                print("sender: send failed, error: \(sad)")
            }
        })
    }

    func enableAir(enabled: Bool) {
        self.airOn = enabled
        guard let conn = connection else { return }
        let byteArray: [UInt8] = [4, 65, 73, 82, enabled ? 1 : 0]
        conn.send(content: byteArray, completion: .contentProcessed { error in
            if let sad = error {
                print("sender: send failed, error: \(sad)")
            }
        })
    }

    func sendInput(arrayLane: [UInt8], arrayAir: [UInt8]) {
        self.lastLane = arrayLane
        self.lastAir = arrayAir
        sendCurrentInput()
    }

    func sendCurrentInput() {
        guard let conn = connection else { return }
        let header: [UInt8] = [43, 73, 78, 80]
        let footer: [UInt8] = [testPressed, servicePressed]
        let packet = header + lastAir + lastLane + footer
        conn.send(content: packet, completion: .contentProcessed { error in
            if let sad = error {
                print("sender: send failed, error: \(sad)")
            }
        })
    }

    func triggerTest() {
        testPressed = 1
        sendCurrentInput()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.testPressed = 0
            self?.sendCurrentInput()
        }
    }

    func triggerService() {
        servicePressed = 1
        sendCurrentInput()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.servicePressed = 0
            self?.sendCurrentInput()
        }
    }

    private func readNextPacket() {
        guard let conn = connection else { return }
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty, error == nil else {
                if isComplete { self?.connection?.cancel() }
                return
            }
            let length = Int(data[0])
            self.readPacketPayload(length: length)
        }
    }

    private func readPacketPayload(length: Int) {
        guard let conn = connection else { return }
        conn.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, data.count >= length, error == nil else {
                if isComplete { self?.connection?.cancel() }
                return
            }
            if length >= 99 && data[0] == 76 && data[1] == 69 && data[2] == 68 {
                let rgbData = Array(data[3 ..< 99])
                self.ledArray = rgbData
            }
            self.readNextPacket()
        }
    }
}
