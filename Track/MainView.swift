//
//  MainView.swift
//  Track
//
//  Created by Bradley on 7/8/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit
import Zip
import AVFoundation
import AVKit
import ARKit

class MainView:UICollectionViewController, UICollectionViewDelegateFlowLayout{
    var welcomeView:UIView!
    override func viewDidLoad() {
        self.collectionView.delaysContentTouches = false
        let welcomeVC = UIStoryboard(name: "Additional", bundle: nil).instantiateViewController(withIdentifier: "emptyViewController")
        welcomeView = welcomeVC.view
        welcomeView.isHidden = true
        self.view.addSubview(welcomeView)
    }
    override func viewWillAppear(_ animated: Bool) {
        
        self.collectionView.reloadData()
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = sharedFileHolder.listProjects().count
        if count <= 0{
            welcomeView.isHidden = false
        }else{
            welcomeView.isHidden = true
        }
        return count
    }
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "main", for: indexPath) as! MainCell
        cell.contentView.layer.cornerRadius = 10
        cell.ready(project: sharedFileHolder.listProjects()[indexPath.item])
        cell.parent = self
        cell.indexPath = indexPath
        return cell
    }
    
    @IBSegueAction func addVideoSegue(_ coder: NSCoder, sender: [String:Any]) -> VideoRecordViewController? {
        
        let vrc = VideoRecordViewController(coder: coder)!
        if sender["project"] != nil{
            
            vrc.project = sender["project"] as! Project
            vrc.index = sender["index"] as! Int
            vrc.parentCell = sender["cell"] as! MainCell
            vrc.title = "Record Tracked Video: "+(sender["project"] as! Project).name
        }
        vrc.hidesBottomBarWhenPushed = true
        return vrc
    }
    
    @IBSegueAction func previewModelSegue(_ coder: NSCoder, sender: [String:Any]) -> ViewerSave? {
        let vs = ViewerSave(coder: coder)!
        vs.viewing = true
        let project = sender["project"] as! Project
        let (asset, map) = sharedFileHolder.loadModel(project: project)
        vs.asset = asset
        vs.verticesCount = project.vertices
        vs.project = project
        vs.worldMap = map
        vs.isModalInPresentation = false
        vs.anchorFound = project.modelHasAnchor
        vs.rescanFunc = { proj in
            MainView.confirmVideoPermission { (allowed) in
                if(!allowed){ self.alertVideoPermission(); return }
                if(!ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)){
                           var alert = UIAlertController(title: "LIDAR", message: "This feature is not supported on your device", preferredStyle: .alert)
                           alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                           self.present(alert, animated: true, completion: nil)
                           return
                       }
                let vc = self.storyboard!.instantiateViewController(withIdentifier: "roomScan") as! ViewController
                vc.workingProject = project
                vc.hidesBottomBarWhenPushed = true
                self.navigationController!.pushViewController(vc, animated: true)
            }
        }
        
        return vs
    }
    
    
    @IBSegueAction func nProjectSegue(_ coder: NSCoder) -> PopupView? {
        let popupView = PopupView(coder: coder)
        
        popupView?.parentVC = self
        return popupView
    }
    @objc func newScan(_ sender: Any) {
        if(!ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)){
            var alert = UIAlertController(title: "LIDAR", message: "This feature is not supported on your device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        MainView.confirmVideoPermission { (allowed) in
            if(!allowed){ self.alertVideoPermission(); return }
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "roomScan")
            vc.hidesBottomBarWhenPushed = true
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }
    @objc func newVid(_ sender: Any) {
        MainView.confirmVideoPermission { (allowed) in
            if(!allowed){ self.alertVideoPermission(); return }
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "vidScan")
            vc.hidesBottomBarWhenPushed = true
            self.navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    static func confirmVideoPermission(response:@escaping (Bool)->()){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            response(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (allowed) in
                response(allowed)
            }
        default:
            //Not allowed
            response(false)
        }
    }
    func alertVideoPermission(){
        var alert = UIAlertController(title: "Video Permission", message: "You must grant camera access to use this feature", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let cellWidth:CGFloat = 375
        let spacingWidth:CGFloat = 25

        let perRow = ((self.view.frame.width-CGFloat(50)) / CGFloat((cellWidth+spacingWidth))).rounded(.towardZero)
        let contentWidth = cellWidth*perRow + spacingWidth*(perRow-1)
               let leftInset = (collectionView.layer.frame.size.width - contentWidth) / 2
               let rightInset = leftInset

        return UIEdgeInsets(top: 25, left: leftInset, bottom: 25, right: rightInset)
    }
    
    
}

class MainCell:UICollectionViewCell, UITextFieldDelegate{
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var titleBar: UITextField!
    
    var indexPath:IndexPath!
    var project:Project!
    var parent: MainView!
    func ready(project: Project) {
        self.project = project
        button1.subviews.forEach({ $0.removeFromSuperview() })
        button1.removeTarget(nil, action: nil, for: .allEvents)
        button2.subviews.forEach({ $0.removeFromSuperview() })
        button2.removeTarget(nil, action: nil, for: .allEvents)
        button3.subviews.forEach({ $0.removeFromSuperview() })
        button3.removeTarget(nil, action: nil, for: .allEvents)
        button4.subviews.forEach({ $0.removeFromSuperview() })
        button4.removeTarget(nil, action: nil, for: .allEvents)
        
        
        titleBar.text = project.name
        titleBar.delegate = self
        button1.layer.borderWidth = 2
        var image1:UIImageView!
        if(project.hasModel){
            image1 = (try? UIImageView(image: UIImage(data: Data(contentsOf: project.modelThumb!)))) ?? UIImageView()
            button1.addTarget(self, action: #selector(previewModel(sender:)), for: .touchUpInside)
        }else{
            image1 = UIImageView(image: UIImage(named: "Scan Model"))
            button1.addTarget(self, action: #selector(scanModel(sender:)), for: .touchUpInside)
        }
        
        image1.frame = CGRect(origin: CGPoint.zero, size: button1.frame.size)
        image1.contentMode = .scaleAspectFill
        button1.addSubview(image1)
        
        let label = UILabel(frame: CGRect(x:0, y:button1.frame.height-25, width:button1.frame.width, height:25))
        label.backgroundColor = UIColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8)
        if(project.hasModel){
            label.isHidden = false
            label.text = "Model"
        }else{
            label.isHidden = true
        }
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.adjustsFontSizeToFitWidth = false
        
        button1.addSubview(label)
        
        
        
        button1.layer.borderColor = UIColor.black.cgColor
        button1.clipsToBounds = true
        button1.layer.cornerRadius = 10
        button1.enableGrow()
        
        let buttons:[UIButton] = [button2, button3, button4]
        let imageAddVideo = UIImageView(image: UIImage(named: "Record Video"))
        imageAddVideo.frame = CGRect(origin: CGPoint.zero, size: button2.frame.size)
        imageAddVideo.contentMode = .scaleAspectFill
        //        button2.addSubview(image2)
        
        let labelAddVideo = UILabel(frame: CGRect(x:0, y:button1.frame.height-25, width:button1.frame.width, height:25))
        labelAddVideo.backgroundColor = UIColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8)
        
        labelAddVideo.text = "Add Tracked Video"
        labelAddVideo.textAlignment = .center
        labelAddVideo.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        labelAddVideo.adjustsFontSizeToFitWidth = false
        
        //               button2.addSubview(label2)
        for (index, video) in project.videos.enumerated(){
            
            let imageVideo = UIImageView(image: UIImage(contentsOfFile: sharedFileHolder.getVideoThumbSaveURL(index: video, uuid: project.id).path))
            imageVideo.frame = CGRect(origin: CGPoint.zero, size: button2.frame.size)
            imageVideo.contentMode = .scaleAspectFill
            //        button2.addSubview(image2)
            
            let labelVideo = UILabel(frame: CGRect(x:0, y:button1.frame.height-25, width:button1.frame.width, height:25))
            labelVideo.backgroundColor = UIColor(displayP3Red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8)
            
            labelVideo.text = "Tracked Video "+String(index+1)
            labelVideo.textAlignment = .center
            labelVideo.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            labelVideo.adjustsFontSizeToFitWidth = false
            
                        let play = UIImageView(frame: buttons[index].bounds)
            play.image = UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .medium))
            play.contentMode = .center
            play.alpha = 0.6
            play.tintColor = UIColor.gray
            
            buttons[index].addSubview(imageVideo)
            buttons[index].addSubview(play)
            buttons[index].addSubview(labelVideo)
            buttons[index].tag = video
            buttons[index].addTarget(self, action: #selector(preview(sender:)), for: .touchUpInside)
            buttons[index].enableGrow()
            
            
            let x_button = UIButton()
            x_button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            //x_button.backgroundColor = UIColor.red
            x_button.tintColor = .black
            x_button.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)), for: .normal)
            x_button.addTarget(self, action: #selector(fadeDelete(sender:)), for: .touchUpInside)
            
            let export_button = UIButton()
            export_button.frame = CGRect(x: buttons[index].frame.width-50, y: 0, width: 50, height: 30)
            export_button.setTitle("export", for: .normal)
            export_button.setTitleColor(UIColor.black, for: .normal)
            export_button.titleLabel!.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            export_button.addTarget(self, action: #selector(fadeExport(sender:)), for: .touchUpInside)
            buttons[index].addSubview(x_button)
            buttons[index].addSubview(export_button)
            
            
        }
        if(project.videos.count<3){
            buttons[project.videos.count].addSubview(imageAddVideo)
            buttons[project.videos.count].addSubview(labelAddVideo)
            buttons[project.videos.count].addTarget(self, action: #selector(addVideo(sender:)), for: .touchUpInside)
            if(!project.videos.contains(1)){
                buttons[project.videos.count].tag = 1
            }else if(!project.videos.contains(2)){
                buttons[project.videos.count].tag = 2
            }else{
                buttons[project.videos.count].tag = 3
            }
            buttons[project.videos.count].enableGrow()
        }
        button2.layer.cornerRadius = 10
        button2.clipsToBounds = true
        
        button3.layer.cornerRadius = 10
        button3.clipsToBounds = true
        
        button4.layer.cornerRadius = 10
        button4.clipsToBounds = true
        
        
        
    }
    
    @objc func fadeDelete(sender:UIButton){
        let upperButton = sender.superview as! UIButton
        
        let coverView = UIVisualEffectView(frame: CGRect(origin: CGPoint.zero, size: upperButton.frame.size))//UIView(frame: CGRect(origin: CGPoint.zero, size: upperButton.frame.size))
        coverView.effect = nil
        //coverView.backgroundColor = UIColor.clear//UIColor.systemGray5
        
        UIView.animate(withDuration: 0.3) {
            coverView.effect = UIBlurEffect(style: .systemChromeMaterialDark)
            //coverView.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.8)
        }
        
        let delete = UIButton(frame: CGRect(x: upperButton.frame.width/2 - 50, y: upperButton.frame.width/2 - 30, width: 100, height: 20))
        delete.setTitle("Delete", for: .normal)
        delete.setTitleColor(UIColor.white, for: .normal)
        delete.showsTouchWhenHighlighted = true
        delete.titleLabel!.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        delete.addTarget(self, action: #selector(deleteVideo(sender:)), for: .touchUpInside)
        //delete.backgroundColor = UIColor.red
        
        let back = UIButton(frame: CGRect(x: upperButton.frame.width/2 - 50, y: upperButton.frame.width/2 + 10, width: 100, height: 20))
        back.setTitle("Undo", for: .normal)
        back.showsTouchWhenHighlighted = true
        back.titleLabel!.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        back.addTarget(self, action: #selector(undo(sender:)), for: .touchUpInside)
        //back.backgroundColor = UIColor.yellow
        //delete.backgroundColor = UIColor.red
        upperButton.addSubview(coverView)
        coverView.contentView.addSubview(delete)
        coverView.contentView.addSubview(back)
        
    }
    @objc func fadeExport(sender:UIButton){
        let upperButton = sender.superview as! UIButton
        
        let coverView = UIVisualEffectView(frame: CGRect(origin: CGPoint.zero, size: upperButton.frame.size))//UIView(frame: CGRect(origin: CGPoint.zero, size: upperButton.frame.size))
        coverView.effect = nil
        //coverView.backgroundColor = UIColor.clear//UIColor.systemGray5
        
        UIView.animate(withDuration: 0.3) {
            coverView.effect = UIBlurEffect(style: .systemChromeMaterialDark)
            //coverView.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.8)
        }
        
        let include_tracking = UISwitch(frame: CGRect(x: -5, y: 20, width: 0, height: 0))
        include_tracking.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        let include_tracking_label = UILabel(frame: CGRect(x:40, y:30, width:100, height:12))
        include_tracking_label.text = "Include Tracking Data"
        include_tracking_label.textAlignment = .left
        include_tracking_label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        include_tracking_label.textColor = UIColor.white
        
        let include_model = UISwitch(frame: CGRect(x: -5, y: 40, width: 0, height: 0))
               include_model.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
               
               let include_model_label = UILabel(frame: CGRect(x:40, y:50, width:100, height:12))
               include_model_label.text = "Include Model OBJ"
               include_model_label.textAlignment = .left
               include_model_label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
               include_model_label.textColor = UIColor.white
        
        let export = ExportButton(include_tracking, include_model, parent, project)
        export.frame = CGRect(x: 20, y: 85, width: 110, height: 20)
        export.setTitleColor(.white, for: .normal)
        export.titleLabel!.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        export.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.2)
        export.layer.cornerRadius = 5
        export.showsTouchWhenHighlighted = true
        
        let cancel = UIButton(frame: CGRect(x: 20, y: 110, width: 110, height: 20))
        cancel.setTitle("Cancel", for: .normal)
        cancel.titleLabel!.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        cancel.addTarget(self, action: #selector(undo(sender:)), for: .touchUpInside)
        coverView.contentView.addSubview(include_tracking)
        coverView.contentView.addSubview(include_tracking_label)
        
        coverView.contentView.addSubview(include_model)
        coverView.contentView.addSubview(include_model_label)
        
        coverView.contentView.addSubview(export)
        coverView.contentView.addSubview(cancel)
        upperButton.addSubview(coverView)
        
        
    }
    @objc func undo(sender:UIButton){
        UIView.animate(withDuration: 0.3, animations: {
            (sender.superview!.superview! as! UIVisualEffectView).effect = nil
            //coverView.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.8)
        }, completion: { (completed) in
            sender.superview!.superview!.removeFromSuperview()
        })
        
    }
    @objc func deleteVideo(sender:UIButton){
        let index = sender.superview!.superview!.superview!.tag
        sharedFileHolder.deleteVideo(index: index, uuid: self.project.id)
        self.project.videos.removeAll { (item) -> Bool in
            item == index
        }
        sharedFileHolder.updateProject(uuid: project.id, newProject: project)
        parent.collectionView.reloadItems(at: [parent.collectionView.indexPath(for: self)!])
    }
    @IBAction func shareButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "Exporting project", message: "Please wait...", preferredStyle: .alert)
        let loading = UIActivityIndicatorView(frame: CGRect(x: 10, y: 15, width: 50, height: 50))
        loading.hidesWhenStopped = true
        loading.style = .medium
        loading.startAnimating()
        alert.view.addSubview(loading)
        self.parent.present(alert, animated: true, completion: nil)
        DispatchQueue.global(qos: .userInitiated).async {
            let url = sharedFileHolder.newZip(uuid: self.project.id)
            let items = [url]
            DispatchQueue.main.sync {
                alert.dismiss(animated: true){
                    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    activityVC.popoverPresentationController!.sourceView = sender
                    self.parent.present(activityVC, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    @objc func previewModel(sender:UIButton){
        parent.performSegue(withIdentifier: "previewSegue", sender: ["project":project, "index":sender.tag])
    }
    @objc func scanModel(sender:UIButton){
        let vc = self.parent.storyboard!.instantiateViewController(withIdentifier: "roomScan") as! ViewController
        vc.workingProject = project
        self.parent.navigationController!.pushViewController(vc, animated: true)
    }
    @objc func addVideo(sender:UIButton){
        MainView.confirmVideoPermission { (allowed) in
            if(!allowed){ self.parent.alertVideoPermission(); return }
            self.parent.performSegue(withIdentifier: "addVideo", sender: ["project":self.project, "index":sender.tag, "cell":self])
        }
    }
    @objc func preview(sender:UIButton){
        let player = AVPlayer(url: sharedFileHolder.getVideoSaveURL(index: sender.tag, uuid: self.project.id))
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        parent.present(playerVC, animated: true) {
            player.play()
        }
        //parent.performSegue(withIdentifier: "previewSegue", sender: ["project":project, "index":sender.tag])
    }
    @IBAction func deleteButton(_ sender: UIButton) {
        titleBar.resignFirstResponder()
        let popController = self.parent.storyboard!.instantiateViewController(withIdentifier: "deletePop")
        (popController.view.subviews.first! as! UIButton).addTarget(self, action: #selector(completeDelete(sender:)), for: .touchUpInside)
        popController.modalPresentationStyle = .popover
        popController.popoverPresentationController!.permittedArrowDirections = [.up, .down]
        popController.popoverPresentationController!.sourceView = sender
        popController.popoverPresentationController!.sourceRect = sender.bounds
        self.parent.present(popController, animated: true, completion: nil)
    }
    @objc func completeDelete(sender:UIButton){
        sender.parentViewController!.dismiss(animated: true, completion: nil)
        sharedFileHolder.deleteProject(uuid: project.id)
        self.parent.collectionView.performBatchUpdates({
            self.parent.collectionView.deleteItems(at: [self.parent.collectionView.indexPath(for: self)!])
        }, completion: nil)
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        project.name = textField.text!
        sharedFileHolder.updateProject(uuid: project.id, newProject: project)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}


class CollView:UICollectionView{
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}

extension UIButton{
    func enableGrow(){
        self.addTarget(self, action: #selector(down(sender:)), for: .touchDown)
        self.addTarget(self, action: #selector(up(sender:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(up(sender:)), for: .touchDragExit)
        self.addTarget(self, action: #selector(up(sender:)), for: .touchCancel)
        self.addTarget(self, action: #selector(down(sender:)), for: .touchDragEnter)
    }
    @objc func down(sender:UIButton){
        let anim = CABasicAnimation(keyPath: "transform")
        anim.fromValue = CATransform3DMakeScale(1, 1, 1)
        anim.toValue = CATransform3DMakeScale(1.02, 1.02, 1)
        anim.duration = 0.1
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        sender.layer.add(anim, forKey: nil)
    }
    @objc func up(sender:UIButton){
        let anim = CABasicAnimation(keyPath: "transform")
        anim.fromValue = CATransform3DMakeScale(1.02, 1.02, 1)
        anim.toValue = CATransform3DMakeScale(1, 1, 1)
        anim.duration = 0.1
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        sender.layer.add(anim, forKey: nil)
    }
}

class PopupView:UIViewController{
    var parentVC:MainView!
    @IBOutlet weak var newScan: ContextMenuButton!
    
    @IBAction func newScanClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.parentVC.newScan(sender)
    }
    @IBAction func newVid(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.parentVC.newVid(sender)
    }
}

extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

class BarButton: UIBarButtonItem{
    var project:Project!
}
class ExportButton:UIButton{
    weak var trackingDataSwitch:UISwitch?
    weak var modelSwitch:UISwitch?
    weak var vc:MainView?
    var project:Project
    init(_ tracking:UISwitch, _ model:UISwitch, _ vc:MainView, _ project:Project){
        trackingDataSwitch = tracking
        modelSwitch = model
        self.vc = vc
        self.project = project
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize.zero))
        trackingDataSwitch!.addTarget(self, action: #selector(switched(sender:)), for: .valueChanged)
        modelSwitch!.addTarget(self, action: #selector(switched(sender:)), for: .valueChanged)
        self.addTarget(self, action: #selector(export(sender:)), for: .touchUpInside)
        switched(sender: modelSwitch!)
    }
    @objc func switched(sender:UISwitch){
        let zipping = trackingDataSwitch!.isOn || modelSwitch!.isOn
        self.setTitle(zipping ? "Export zip":"Export mp4", for: .normal)
    }
    @objc func export(sender:ExportButton){
        let zipping = trackingDataSwitch!.isOn || modelSwitch!.isOn
        let tdso = trackingDataSwitch!.isOn
        let mso = modelSwitch!.isOn
        let index = self.superview!.superview!.superview!.tag
        if(!zipping){
            let url = sharedFileHolder.getVideoSaveURL(index: index, uuid: project.id)
            let items = [url]
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityVC.popoverPresentationController!.sourceView = sender
            self.vc!.present(activityVC, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Building Zip", message: "Please wait...", preferredStyle: .alert)
            let loading = UIActivityIndicatorView(frame: CGRect(x: 10, y: 15, width: 50, height: 50))
            loading.hidesWhenStopped = true
            loading.style = .medium
            loading.startAnimating()
            alert.view.addSubview(loading)
            self.vc!.present(alert, animated: true, completion: nil)
            DispatchQueue.global(qos: .userInitiated).async {
                let url = sharedFileHolder.newCustomZip(uuid: self.project.id, index: index, includeObject: mso, includeTracking: tdso)
                let items = [url]
                DispatchQueue.main.sync {
                    alert.dismiss(animated: true){
                        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                        activityVC.popoverPresentationController!.sourceView = sender
                        self.vc!.present(activityVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    required init?(coder: NSCoder) {
        return nil
    }
}
