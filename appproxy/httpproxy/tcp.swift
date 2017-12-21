//
//  tcp.swift
//  httpproxy
//
//  Created by yarshure on 2017/12/21.
//  Copyright © 2017年 PINIDEA LLC. All rights reserved.
//

import Foundation
func showScan(){
    let queue = DispatchQueue.init(label: ".", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    //let queue = DispatchQueue(label: "com.abigt.socket")// DISPATCH_QUEUE_CONCURRENT)
    
    
    queue.async(execute: {
        
        
        
        
        // Look up the host...
        let socketfd: Int32 = socket(Int32(AF_INET), SOCK_STREAM, Int32(IPPROTO_TCP))
        let remoteHostName = proxy.host
        //let port = Intp.serverPort
        
        guard let remoteHost = gethostbyname2((remoteHostName as NSString).utf8String, AF_INET)else {
            return
        }
        
        
        
        
        
        
        var remoteAddr = sockaddr_in()
        remoteAddr.sin_family = sa_family_t(AF_INET)
        bcopy(remoteHost.pointee.h_addr_list[0], &remoteAddr.sin_addr.s_addr, Int(remoteHost.pointee.h_length))
        let port = UInt16(proxy.port)
        remoteAddr.sin_port = port.bigEndian
        
        
        
        
        
        // Now, do the connection...
        let rc = withUnsafePointer(to: &remoteAddr) {
            // Temporarily bind the memory at &addr to a single instance of type sockaddr.
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketfd, $0, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }
        
        
        if rc < 0 {
            
            //throw BlueSocketError(code: BlueSocket.SOCKET_ERR_CONNECT_FAILED, reason: self.lastError())
            
            let e =  String.init(cString: strerror(errno))
            NSLog("show scan error:" + e)
            
        }else {
            
            
            close(socketfd)
        }
        
        
        
    })
    
}
