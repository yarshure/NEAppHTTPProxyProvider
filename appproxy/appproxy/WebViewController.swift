//
//  WebViewController.swift
//  appproxy
//
//  Created by Tomasen on 2/6/16.
//  Copyright © 2016 PINIDEA LLC. All rights reserved.
//

import UIKit
import NetworkExtension
class WebViewController: UIViewController ,UIWebViewDelegate{
    var proxyManager:NEAppProxyProviderManager?
    @IBOutlet weak var wv: UIWebView!
    private func startLoading() {
        // guard case .loading = self.state else { fatalError() }
        NEAppProxyProviderManager.loadAllFromPreferences { (managers, error) in
            assert(Thread.isMainThread)
            if let error = error {
                //self.state = .failed(error: error)
                print(error.localizedDescription)
            } else {
                guard let manager = managers?.first else {
                    fatalError()
                    return
                }
                
                
                //self.state = .loaded(snapshot: Snapshot(from: manager), manager: manager)
                print(manager)
                self.proxyManager = manager
                if let rs = manager.copyAppRules(){
                    print(rs)
                }
                
                self.initProviderManager()
            }
        }
    }
    private func initProviderManager() {
        guard let manager = self.proxyManager else {
            return
        }
        let session = manager.connection as! NETunnelProviderSession
        do {
            try session.startTunnel(options: nil)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object:session , queue: OperationQueue.main, using: { (t) in
            
                let sess = t.object as! NETunnelProviderSession
                print(sess)
            })
            
        }
        catch {
            print(error.localizedDescription)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        wv.delegate = self
        startLoading()
        
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        //let url:URL = URL.init(string: "https://www.google.com")!
        //wv.loadRequest(URLRequest.init(url: url))

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func query(_ sender: Any) {
        showScan()
        let url:URL = URL.init(string: "https://www.apple.com")!
        wv.loadRequest(URLRequest.init(url: url))
    }
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool{
        print(request.url!)
        return true
    }
    
    
     public func webViewDidStartLoad(_ webView: UIWebView)
     {
        print("webViewDidStartLoad")
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView){
        print("webViewDidFinishLoad")
    }
    
   
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error){
     
        print("didFailLoadWithError \(error.localizedDescription)")
    }
    func showScan(){
        let queue = DispatchQueue.init(label: ".", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        //let queue = DispatchQueue(label: "com.abigt.socket")// DISPATCH_QUEUE_CONCURRENT)
        
        
        queue.async(execute: {
            
            
            
            
            // Look up the host...
            let socketfd: Int32 = socket(Int32(AF_INET), SOCK_STREAM, Int32(IPPROTO_TCP))
            let remoteHostName = "192.168.1.64"
            //let port = Intp.serverPort
            
            guard let remoteHost = gethostbyname2((remoteHostName as NSString).utf8String, AF_INET)else {
                return
            }
            
            
            
            
            
            
            var remoteAddr = sockaddr_in()
            remoteAddr.sin_family = sa_family_t(AF_INET)
            bcopy(remoteHost.pointee.h_addr_list[0], &remoteAddr.sin_addr.s_addr, Int(remoteHost.pointee.h_length))
            let port = UInt16(8000)
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
                
                print("error:" + e)
            }else {
                
                print("connected ok!")
                close(socketfd)
            }
            
            
            
        })
    }
}
