//
//  RecordButton.swift
//  Track
//
//  Created by Bradley on 6/29/20.
//  Copyright © 2020 Bradley. All rights reserved.
//

import Foundation
import UIKit

class RecordButton:UIButton{
    let record = CAShapeLayer()
    let outline = CAShapeLayer()
    var delegate: RecordButtonDelegate?
    var toggle = false
    
    let circlePath = circlePathWithCenter(center: CGPoint(x:50, y:50), radius: 37.5).cgPath//CGPath(ellipseIn: CGRect(x: 12.5, y: 12.5, width: 75, height: 75), transform: nil)
    let squarePath = squarePathWithCenter(center: CGPoint(x:50, y:50), side: 40, radius: 10).cgPath//CGPath(roundedRect: CGRect(x: 30, y: 30, width: 40, height: 40), cornerWidth: 10, cornerHeight: 10, transform: nil)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let record_path = circlePath
        record.path = record_path
        record.fillMode = .forwards
        record.fillColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1).cgColor
        self.layer.addSublayer(record)

        let outline = CAShapeLayer()
        let outline_path = CGPath(ellipseIn: CGRect(x: 5, y: 5, width: 90, height: 90), transform: nil)
        outline.path = outline_path
        outline.strokeColor = UIColor.white.cgColor
        outline.lineWidth = 10
        outline.fillColor = nil
        self.layer.addSublayer(outline)
        
        self.addTarget(self, action: #selector(down(sender:)), for: .touchDown)
        self.addTarget(self, action: #selector(click(sender:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(exit(sender:)), for: .touchDragExit)
        self.addTarget(self, action: #selector(enter(sender:)), for: .touchDragEnter)
        self.layer.transform = CATransform3DMakeScale(0.75, 0.75, 1)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    @objc func down(sender:UIButton){
        push()
    }
    @objc func click(sender:UIButton){
        unpush()
        if !toggle{
            if (delegate?.start() == true){
                square()
                toggle = true
            }
        }else{
            if (delegate?.stop() == true){
                circle()
                toggle = false
            }
        }
        
    }
    @objc func exit(sender:UIButton){
        unpush()
    }
    @objc func enter(sender:UIButton){
        push()
    }
    
    func push(){
        let darken = CABasicAnimation(keyPath: "fillColor")
        darken.fromValue = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1).cgColor
        darken.toValue = UIColor(displayP3Red: 0.9, green: 0, blue: 0, alpha: 1).cgColor
        darken.duration = 0.05
        darken.fillMode = .forwards
        darken.isRemovedOnCompletion = false
        record.add(darken, forKey: nil)
    }
    func unpush(){
        let lighten = CABasicAnimation(keyPath: "fillColor")
        lighten.fromValue = UIColor(displayP3Red: 0.9, green: 0, blue: 0, alpha: 1).cgColor
        lighten.toValue = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1).cgColor
        lighten.duration = 0.1
        lighten.fillMode = .forwards
        lighten.isRemovedOnCompletion = false
        record.add(lighten, forKey: nil)
    }
    func square(){
        let toSquare = CABasicAnimation(keyPath: "path")
        toSquare.fromValue = circlePath
        toSquare.toValue = squarePath
        toSquare.duration = 0.1
        toSquare.fillMode = .forwards
        toSquare.isRemovedOnCompletion = false
        record.add(toSquare, forKey: nil)
    }
    func circle(){
        let toCircle = CABasicAnimation(keyPath: "path")
        toCircle.fromValue = squarePath
        toCircle.toValue = circlePath
        toCircle.duration = 0.1
        toCircle.fillMode = .forwards
        toCircle.isRemovedOnCompletion = false
        record.add(toCircle, forKey: nil)
    }
    
    static func circlePathWithCenter(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let circlePath = UIBezierPath()
        circlePath.move(to: CGPoint(x: center.x-radius, y: center.y-radius))
        circlePath.addLine(to: circlePath.currentPoint)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: -CGFloat(M_PI), endAngle: -CGFloat(3*M_PI/2), clockwise: false)
        circlePath.addLine(to: circlePath.currentPoint)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: -CGFloat(3*M_PI/2), endAngle: 0, clockwise: false)
        circlePath.addLine(to: circlePath.currentPoint)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: -CGFloat(M_PI/2), clockwise: false)
        circlePath.addLine(to: circlePath.currentPoint)
        circlePath.addArc(withCenter: center, radius: radius, startAngle: -CGFloat(M_PI/2), endAngle: -CGFloat(M_PI), clockwise: false)
        circlePath.close()
        return circlePath
    }

    static func squarePathWithCenter(center: CGPoint, side: CGFloat, radius:CGFloat) -> UIBezierPath {
        let squarePath = UIBezierPath()
        squarePath.move(to: CGPoint(x: center.x - side / 2, y: center.y - side / 2 + radius))
        squarePath.addLine(to: CGPoint(x: center.x - side / 2, y: center.y + side / 2 - radius))
        squarePath.addArc(withCenter: CGPoint(x: center.x - side / 2+radius, y: center.y + side / 2-radius), radius: radius, startAngle: -CGFloat.pi, endAngle: -3*CGFloat.pi/2, clockwise: false)
        squarePath.addLine(to: CGPoint(x: center.x + side / 2-radius, y: center.y + side / 2))
        squarePath.addArc(withCenter: CGPoint(x: center.x + side / 2-radius, y: center.y + side / 2-radius), radius: radius, startAngle: -3*CGFloat.pi/2, endAngle: 0, clockwise: false)
        squarePath.addLine(to: CGPoint(x: center.x + side / 2, y: center.y - side / 2+radius))
        squarePath.addArc(withCenter: CGPoint(x: center.x + side / 2-radius, y: center.y - side / 2+radius), radius: radius, startAngle: 0, endAngle: -CGFloat.pi/2, clockwise: false)
        squarePath.addLine(to: CGPoint(x: center.x - side / 2+radius, y: center.y - side / 2))
        squarePath.addArc(withCenter: CGPoint(x: center.x - side / 2+radius, y: center.y - side / 2+radius), radius: radius, startAngle: -CGFloat.pi/2, endAngle: -CGFloat.pi, clockwise: false)
        squarePath.close()
        return squarePath
    }
}

protocol RecordButtonDelegate {
    func start() -> Bool
    func stop() -> Bool
}
