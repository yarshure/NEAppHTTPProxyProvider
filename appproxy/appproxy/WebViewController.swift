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
