//
//  AppHTTPProxyProvider.swift
//
//  Created by Tomasen on 2/5/16.
//  Copyright © 2016 PINIDEA LLC. All rights reserved.
//


import NetworkExtension
import CocoaAsyncSocket

struct HTTPProxySet {
    var host: String
    var port: UInt16
}

var proxy = HTTPProxySet(host: "192.168.2.90", port: 8000)

/// A AppHTTPProxyProvider sub-class that implements the client side of the http proxy tunneling protocol.
class AppHTTPProxyProvider: NEAppProxyProvider {
    
    let q = DispatchQueue.init(label: "com.yarshure.socket")
    let qq = DispatchQueue.init(label: "com.yarshure.delegate")
    /// Begin the process of establishing the tunnel.
    var clients:[ClientAppHTTPProxyConnection] = []
    func prepare(){
        
    }
    override init() {
        super.init()
        NSLog("AppHTTPProxyProvider init")
    }
    override func startProxy(options: [String : Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        NSLog("AppHTTPProxyProvider startProxy")
        let newSettings = NETunnelNetworkSettings(tunnelRemoteAddress: "192.168.2.1")
        newSettings.dnsSettings = NEDNSSettings(servers: ["192.168.2.1","180.168.255.118"])
        var excludedRoutes = [NEIPv4Route]()
        excludedRoutes.append(NEIPv4Route.init(destinationAddress: "192.168.2.0", subnetMask: "255.255.255.0"))
        //newSettings.ipv4Settings?.excludedRoutes = excludedRoutes
        self.setTunnelNetworkSettings(newSettings) { error in
            if let e = error{
                NSLog("setTunnelNetworkSettings error \(e.localizedDescription)")
            }
            completionHandler(error)
        }
        
    }
    
    
    /// Begin the process of stopping the tunnel.
   
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
         NSLog("AppHTTPProxyProvider stopProxy")
        completionHandler()
    }
    /// Handle a new flow of network data created by an application.
    override func handleNewFlow(_ flow: (NEAppProxyFlow?)) -> Bool {
        
        if let TCPFlow = flow as? NEAppProxyTCPFlow {
             NSLog("AppHTTPProxyProvider NEAppProxyTCPFlow \(TCPFlow.metaData.sourceAppSigningIdentifier)")
            let conn = ClientAppHTTPProxyConnection(flow: TCPFlow)
            clients.append(conn)
            conn.open(q: q, qq: qq)
        }
        
        return false
    }
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        completionHandler!(messageData)
    }
}

/// An object representing the client side of a logical flow of network data in the SimpleTunnel tunneling protocol.
class ClientAppHTTPProxyConnection : NSObject, GCDAsyncSocketDelegate {
    
    // MARK: Constants
    let bufferSize: UInt = 4096
    let timeout    = 30.0
    let pattern    = "\n\n".data(using: String.Encoding.utf8)
    
    // MARK: Properties
    
    /// The NEAppProxyFlow object corresponding to this connection.
    let TCPFlow: NEAppProxyTCPFlow
    
    // MARK: Initializers
    var sock: GCDAsyncSocket!
    
    init(flow: NEAppProxyTCPFlow) {
        TCPFlow = flow
    }
    deinit {
         NSLog("ClientAppHTTPProxyConnection deinit")
    }
    
    func open(q:DispatchQueue,qq:DispatchQueue) {
        sock = GCDAsyncSocket.init(delegate: self, delegateQueue: q, socketQueue: qq)
        do {
            try sock.connect(toHost: proxy.host, onPort: proxy.port, withTimeout: 30.0)
        } catch let e  {
            NSLog("GCDAsyncSocket error \(e.localizedDescription)")
            TCPFlow.closeReadWithError(NSError(domain: NEAppProxyErrorDomain, code: NEAppProxyFlowError.notConnected.rawValue, userInfo: nil))
            return
        }
    }
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?){
        if let e = err {
             NSLog("GCDAsyncSocket error \(e.localizedDescription)")
        }
       
    }
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host:String, port p:UInt16) {
        
        NSLog("AppHTTPProxyProvider didConnectToHost")
        print("Connected to \(host) on port \(p).")
        
        let remoteHost = (TCPFlow.remoteEndpoint as! NWHostEndpoint).hostname
        let remotePort = (TCPFlow.remoteEndpoint as! NWHostEndpoint).port
        
        // 1. send CONNECT
        // CONNECT www.google.com:80 HTTP/1.1
        sock.write(
            "CONNECT \(remoteHost):\(remotePort) HTTP/1.1\n\n"
                .data(using: String.Encoding.utf8),
            withTimeout: timeout,
            tag: 1)
        
    }
    
    
    func didReadFlow(data: Data?, error: NSError?) ->Void{
        // 7. did read from flow
        // 8. write flow data to proxy
        sock.write(data! as Data, withTimeout: timeout, tag: 0)
        
        // 9. keep reading from flow
        TCPFlow.readData(completionHandler: self.didReadFlow as! (Data?, Error?) -> Void)
        
    }
    
    func socket(_ sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        if tag == 1 {
            // 2. CONNECT header sent
            // 3. begin to read from proxy server
            sock.readData(toLength: bufferSize, withTimeout: timeout, tag: 1)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
        if tag == 1 {
            // 4. read 1st proxy server response of CONNECT
//            let range = data.range(of:pattern!,
//                                         options: NSData.SearchOptions(rawValue: 0),
//                range: NSMakeRange(0, data.length))
            let range = data.range(of: pattern!, options: .init(rawValue: 0), in: 0..<data.count)
            if let range = range {
                if let _ = data.range(of:"200".data(using: .utf8)!,
                                           options: .init(rawValue: 0),
                                           in: 0..<range.upperBound){
                    //let loc = range.upperBound
                    if data.count > range.upperBound {
                        // 5. write to flow if there is data already
                        let left = data.subdata(in: range.lowerBound..<data.count)
                        NSLog("#### proxy write data \(left)" )
                        TCPFlow.write(left, withCompletionHandler: { error in })
                    }
                    
                    // 6. begin to read from Flow
                    TCPFlow.readData(completionHandler: self.didReadFlow as! (Data?, Error?) -> Void)
                    
                    // 6.5 keep reading from proxy server
                    sock.readData(toLength: bufferSize, withTimeout: timeout, tag: 0)
                    return
                }
                
            }
            
            // Error: CONNECT failed
            TCPFlow.closeReadWithError(NSError(domain: NEAppProxyErrorDomain, code: NEAppProxyFlowError.notConnected.rawValue, userInfo: nil))
            sock.disconnect()
            return
        }
        
        // 10. writing any data followed to flow
        TCPFlow.write(data as Data, withCompletionHandler: { error in })
        
        // 11. keep reading from proxy server
        sock.readData(toLength: bufferSize, withTimeout: timeout, tag: 0)
    }
    
}
