//
//  PDFPop.swift
//  Track
//
//  Created by Bradley on 7/15/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

class PDFPop:UIViewController{
    var pd:PDFView!
    var pdf:String!
    override func viewDidLoad() {
        pd = PDFView()
        self.view.addSubview(pd)
        pd.translatesAutoresizingMaskIntoConstraints = false
        pd.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        pd.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        pd.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
                
        pd.document = PDFDocument(url: Bundle.main.url(forResource: pdf, withExtension: "pdf")!)
        pd.backgroundColor = UIColor.white
        pd.displaysPageBreaks = false
        pd.pageShadowsEnabled = false
        pd.autoScales = true
        
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        self.view.addSubview(navBar)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        pd.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 0).isActive = true
        
        let backButton = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(back(sender:)))
        let item = UINavigationItem(title: self.title!)
        item.leftBarButtonItem = backButton
        navBar.setItems([item], animated: false)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        pd.layoutIfNeeded()
        pd.scaleFactor = pd.frame.width/pd.rowSize(for: pd.document!.page(at: 0)!).width*2
        pd.minScaleFactor = pd.frame.width/pd.rowSize(for: pd.document!.page(at: 0)!).width*2
        pd.maxScaleFactor = pd.frame.width/pd.rowSize(for: pd.document!.page(at: 0)!).width*2
        if let scrollView = pd.subviews.first as? UIScrollView {
            scrollView.contentOffset.y = 0.0
        }
        
        
        //pd.zoomIn(nil)
    }
    func addPDF(pdf:String){
        self.pdf = pdf
    }
    @objc func back(sender:UIBarButtonItem){
        self.dismiss(animated: true, completion: nil)
    }
    
}

class CreditsViewController:UIViewController{
    @IBOutlet weak var close: UIBarButtonItem!
    @IBOutlet weak var textArea: UITextView!
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        textArea.text = try? String(contentsOf: Bundle.main.url(forResource: "Credits", withExtension: nil)!)
    }
}
