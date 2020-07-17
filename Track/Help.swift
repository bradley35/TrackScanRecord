//
//  Help.swift
//  Track
//
//  Created by Bradley on 7/14/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit
class Help:UICollectionViewController, UICollectionViewDelegateFlowLayout
{
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    var xmlData:HelperXmlDelegate!
    override func viewDidLoad() {
        let xmlReader = XMLParser(contentsOf: Bundle.main.url(forResource: "HelpScreens", withExtension: "xml")!)!
        xmlData = HelperXmlDelegate()
        xmlReader.delegate = xmlData
        xmlReader.parse()
        self.collectionView.delaysContentTouches = false
    }
    
    var first = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //collectionView.contentInset.top = 354
        collectionView.contentInset.top = max((collectionView.frame.height - self.navigationController!.navigationBar.frame.height - collectionView.contentSize.height -  self.navigationController!.tabBarController!.tabBar.frame.height) / 2, 50)
        collectionView.contentInset.left = max((collectionView.frame.width - collectionView.contentSize.width) / 2, 0)
        if(first){
            collectionView.scrollRectToVisible(CGRect(x:0,y:0,width:1,height:1), animated: false)
            first = false
        }
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return xmlData.cards.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! HelperCell
        cell.prepare(dict: xmlData.cards[indexPath.item], parent:self)
        return cell
    }
    static func downloadAnchor(vc:UIViewController, sender:UIView){
        var alert = UIAlertController(title: "Anchor", message: "Please print out the following image so that the black outline makes a 7\" x 7\" square and place it somewhere visible in your space", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default){ action in
            let url = URL(fileURLWithPath: Bundle.main.path(forResource: "TrackAnchor7x7", ofType: "pdf")!)
            let items = [url]
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityVC.popoverPresentationController!.sourceView = sender
            vc.present(activityVC, animated: true, completion: nil)
        })
        vc.present(alert, animated: true, completion: nil)
    }
}
class HelperCell:UICollectionViewCell{
    unowned var parent:Help!
    var dict:[String:String]!
    var action:(()->())?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    func prepare(dict:[String:String], parent:Help){
        self.parent = parent
        self.dict = dict
        let colors = dict["color"]!.replacingOccurrences(of: " ", with: "").split(separator: ",").map({ (str) -> Float in
            return Float(str)!
        })
        self.contentView.backgroundColor = UIColor(displayP3Red: CGFloat(colors[0]/255), green: CGFloat(colors[1]/255), blue: CGFloat(colors[2]/255), alpha: 1)
        titleLabel.text = dict["title"]
        imageView.image = UIImage(named: dict["image"] ?? "")
        
        self.clipsToBounds = false
        self.contentView.clipsToBounds = false
        self.contentView.layer.cornerRadius = 15
        self.contentView.layer.shadowRadius = 15
        self.contentView.layer.shadowColor = self.contentView.backgroundColor!.withAlphaComponent(0.8).cgColor
        self.contentView.layer.shadowOpacity = 1
        self.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        if(dict["id"] == "down"){
            action = {
                Help.downloadAnchor(vc:parent, sender: self)
            }
        }else if(dict["pdf"] != nil){
            action = {
                let pd = PDFPop()
                pd.addPDF(pdf: dict["pdf"]!)
                pd.title = dict["title"]
                self.parent.present(pd, animated: true, completion: nil)
            }

        }
        self.isMultipleTouchEnabled = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        shrink()
        action?()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        grow()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        shrink()
    }
    @objc func grow(){
        let anim = CABasicAnimation(keyPath: "transform")
        anim.fromValue = CATransform3DMakeScale(1, 1, 1)
        anim.toValue = CATransform3DMakeScale(1.02, 1.02, 1)
        anim.duration = 0.1
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        self.contentView.layer.add(anim, forKey: nil)
    }
    @objc func shrink(){
        let anim = CABasicAnimation(keyPath: "transform")
        anim.fromValue = CATransform3DMakeScale(1.02, 1.02, 1)
        anim.toValue = CATransform3DMakeScale(1, 1, 1)
        anim.duration = 0.1
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        self.contentView.layer.add(anim, forKey: nil)
    }
}
class HelperXmlDelegate:NSObject, XMLParserDelegate{
    var cards = [[String:String]]()
    var currentElement = ""
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if(elementName == "card"){
            cards.append([String:String]())
        }else{
            currentElement = elementName
        }
        
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if(cards.count <= 0 || currentElement == "cards"){
            return
        }
        if(string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == ""){
            return
        }
        cards[cards.count-1][currentElement] = cards[cards.count-1][currentElement] == nil ? string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : cards[cards.count-1][currentElement]! + string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
