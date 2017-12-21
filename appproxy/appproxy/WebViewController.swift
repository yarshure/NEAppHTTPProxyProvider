//
//  WebViewController.swift
//  appproxy
//
//  Created by Tomasen on 2/6/16.
//  Copyright © 2016 PINIDEA LLC. All rights reserved.
//

import UIKit
import NetworkExtension
extension NEVPNStatus{
    func descript() ->String{
        switch self{
        case .disconnected:
            
            return  "Disconnect"
            
            
        case .invalid:
            
            return "Please Try Again"
            
        case .connected:
            
            return "Connected"
            
            
        case .connecting:
            
            return "Connecting"
            
        case .disconnecting:
            
            return "Disconnecting"
            
        case .reasserting:
            return   "Reasserting"
            
            
            
        }
    }
}
class WebViewController: UIViewController ,UIWebViewDelegate{
    var proxyManager:NEAppProxyProviderManager?
    @IBOutlet weak var wv: UIWebView!
    @IBOutlet weak var lable:UILabel!
    func ob(_ connection:NEVPNConnection){
        self.lable.text =  connection.status.descript()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object:connection , queue: OperationQueue.main, using: { (t) in
            self.lable.text =  connection.status.descript()
            
        })
    }
    private func startLoading() {
        func xpc(){
            guard let targetManager = self.proxyManager else {
                return
            }
            if let session = targetManager.connection as? NETunnelProviderSession,
                let message = "Hello Provider".data(using: String.Encoding.utf8)
                , targetManager.connection.status != .invalid{
                do {
                    try session.sendProviderMessage(message, responseHandler: { (t) in
                        if let t = t ,let s = String.init(data: t, encoding: .utf8){
                            
                            print(s)
                        }
                    })
                }catch let e {
                    print("provider reply:\(e.localizedDescription)")
                }
            }
        }
        // guard case .loading = self.state else { fatalError() }
        NEAppProxyProviderManager.loadAllFromPreferences { (managers, error) in
            assert(Thread.isMainThread)
            if let error = error {
                //self.state = .failed(error: error)
                print(error.localizedDescription)
            } else {
                guard let manager = managers?.first else {
                    print("no MDM profile")
                    return
                }
                
                
                //self.state = .loaded(snapshot: Snapshot(from: manager), manager: manager)
                print(manager)
                self.proxyManager = manager
                if let rs = manager.copyAppRules(){
                    print(rs)
                }
                 self.ob(manager.connection)
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
        //showScan()
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
   
}
