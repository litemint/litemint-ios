//
//  ViewController.swift
//  Litemint
//
//  Copyright © 2019 Litemint LLC All rights reserved.
//

import UIKit
import WebKit
import QRCodeReader
import AVFoundation
import JavaScriptCore
import UserNotifications

class ViewController: UIViewController, WKScriptMessageHandler,QRCodeReaderViewControllerDelegate, UIGestureRecognizerDelegate,WKNavigationDelegate{

    //MARK:- INITIALIZE QRCODE CONTROLLER
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            
            // Configure the view controller (optional)
            $0.showTorchButton        = true
            $0.showSwitchCameraButton = true
            $0.showCancelButton       = true
            $0.showOverlayView        = true
        }
        return QRCodeReaderViewController(builder: builder)
    }()
    
    //MARK:- PROPERTY
    var webView: WKWebView!
    let notifications = Notification()
    
    let imgviewSplash = UIImageView()
    
    
    
   
        //MARK:- SETUP WEBVIEW
    private func setupWebView() {
        
        let contentController = WKUserContentController()
        let userScript = WKUserScript(
            source: "evaluateJavascript()",
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.add(self, name: "callbackHandler")
        contentController.add(self, name: "supportStorePolicy")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
     
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
         
        webView.navigationDelegate = self
    }
    
    //MARK:- VIEW LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setupWebView()
        self.view.addSubview(self.webView)
        
        if let url = URL(string: "https://app.litemint.com/?flavor=pepper&os=ios&v=131") {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
        
        self.navigationController?.navigationBar.isHidden = true
        self.webView.scrollView.bounces = false
        
        self.swipeToPop()

        imgviewSplash.image = #imageLiteral(resourceName: "splash")
        imgviewSplash.translatesAutoresizingMaskIntoConstraints = false
        imgviewSplash.contentMode = .scaleAspectFill
        self.view.addSubview(imgviewSplash)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[imgviewSplash]|", options: [], metrics: nil, views: ["imgviewSplash":imgviewSplash]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imgviewSplash]|", options: [], metrics: nil, views: ["imgviewSplash":imgviewSplash]))

        imgviewSplash.bringSubview(toFront: self.view)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func swipeToPop() {
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self;
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer == self.navigationController?.interactivePopGestureRecognizer {
            
            self.webView.evaluateJavaScript("onBackButtonPressed()", completionHandler: nil)
            
            return true
        }
        return true
    }
    
    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "callbackHandler" {
            print("JavaScript is sending a message \(message.body)")

            if let dict = message.body as? NSDictionary{
                
                if let name = dict.value(forKey: "name") as? String{
                    
                    if(name == EventHandlerType.ready.rawValue){
                        
                        self.imgviewSplash.isHidden = true
                    }
                    if(name == EventHandlerType.copyToClipboard.rawValue){
                        
                        self.copyClipboardData(dict: dict)
                       
                    }else if(name == EventHandlerType.share.rawValue){
                        
                        self.shareEventAction(dict: dict)
                        
                    }else if(name == EventHandlerType.rate.rawValue){
                        
                        self.rateToApp()
                        
                    }else if(name == EventHandlerType.showToast.rawValue){
                        
                        self.view.makeToast(dict.value(forKey: "message") as? String ?? "")
                        
                    }else if(name == EventHandlerType.scanQRCode.rawValue){
                        
                        self.scanQRAction()
                        
                    }else if(name == EventHandlerType.retrieveClipboardData.rawValue){
                        
                        self.retrieveClipboardData()
                        
                    }else if(name == EventHandlerType.showNotification.rawValue){
                        
                        self.view.makeToast(dict.value(forKey: "message") as? String ?? "")
                        
                        self.notifications.scheduleNotification(notificationType: dict.value(forKey: "message") as? String ?? "", title: "LITEMINT")
                    }
                    else if(name == EventHandlerType.lockOrientation.rawValue){
                     AppUtility.lockOrientation(.portrait)
                    }
                    else if(name == EventHandlerType.unlockOrientation.rawValue)
                    {
                        
                     AppUtility.lockOrientation(.all)

                        self.webView.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.flexibleWidth.rawValue | UIViewAutoresizing.flexibleHeight.rawValue)
                    
                    }
                      
                }
            }
        }
    }
    
    //MARK:- WKNavigation Delegate Mehtod
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var action: WKNavigationActionPolicy?
        
        defer {
            decisionHandler(action ?? .allow)
        }
        
        guard let url = navigationAction.request.url else { return }
        
        print(url)
        
        if(url != URL(string: "https://app.litemint.com/?flavor=pepper&os=ios&v=131")){
            
            if ((navigationAction.navigationType == .linkActivated || navigationAction.navigationType  == .other) && url.absoluteString.range(of: "litemint.store") == nil)  {
                
                action = .cancel // Stop in WebView
                UIApplication.shared.open(url, options: [:], completionHandler: nil) // Open in Safari
            }
        }
       
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code != NSURLErrorCancelled {
            webView.loadHTMLString("404 - Page Not Found", baseURL: URL(string: "https://www.litemint.com/"))
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(String(describing: webView.url))
    }

    // MARK: - QRCodeReaderViewController Delegate Methods
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    //This is an optional delegate method, that allows you to be notified when the user switches the cameraName
    //By pressing on the switch camera button
    func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
//        if let cameraName = newCaptureDevice.device.localizedName {
            print("Switching capture to: \(newCaptureDevice.device.localizedName)")
//        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    //MARK:- EVENT HANDLE ACTION
    func shareEventAction(dict:NSDictionary){
        var strShareContent = ""
        if let code = dict.value(forKey: "code") as? String{
            strShareContent.append(code)
        }
        if let deposite = dict.value(forKey: "deposit") as? String{
            strShareContent.append("\n\(deposite)")
        }
        if let issuer = dict.value(forKey: "issuer") as? String{
            strShareContent.append("\n\(issuer)")
        }
        
        print(strShareContent)
        let vc = UIActivityViewController(activityItems: [strShareContent], applicationActivities: [])
        vc.title = dict.value(forKey: "title") as? String ?? ""
        self.present(vc, animated: true, completion: nil)
    }
    
    func scanQRAction(){
        
        readerVC.delegate = self
        
        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            
            if let result = result{
                
                let jsSource = "\"\(result.value)\""
                print(jsSource)
                
                print("onQRCodeReceived(\(jsSource))")
                self.webView.evaluateJavaScript("onQRCodeReceived(\(jsSource))", completionHandler: nil)
            }
        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
        
    }
    
    func copyClipboardData(dict:NSDictionary){
        
        if let dataAddress = dict.value(forKey: "data") as? String{
            print(dataAddress)
            UIPasteboard.general.string = dataAddress
            self.view.makeToast(dict.value(forKey: "message") as? String ?? "")
        }
    }
    
    func retrieveClipboardData(){
        
        if let myString = UIPasteboard.general.string {
            self.view.makeToast(myString)
            
            let jsSource = "\"\(myString)\""
            print("onRetrieveClipboardData(\(jsSource))")
            self.webView.evaluateJavaScript("onRetrieveClipboardData(\(jsSource))", completionHandler: nil)
        }
    }
    
    func rateToApp(){
        
        print("onBackButtonPressed()")
        self.webView.evaluateJavaScript("onBackButtonPressed()", completionHandler: nil)
        
    }
    
    //MARK:- ALERT CONTROLLER
    func showAlertController(title:String,message:String){
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)
    }
    
}

