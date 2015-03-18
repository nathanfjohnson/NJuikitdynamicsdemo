//
//  ViewController.swift
//  uikitdynamics demo
//
//  Created by Nathan Johnson on 3/16/15.
//
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var handleImageView: UIImageView!
    @IBOutlet weak var sceneImageView: UIImageView!
    @IBOutlet weak var scene2ImageView: UIImageView!
    @IBOutlet weak var scene3ImageView: UIImageView!
    @IBOutlet weak var screenView: UIVisualEffectView!
    @IBOutlet weak var interactiveHandleView: UIView!

    @IBAction func scene1ButtonPressed(sender: AnyObject) {
        switchToScene(1)
    }
    @IBAction func scene2ButtonPressed(sender: AnyObject) {
        switchToScene(2)
    }
    @IBAction func scene3ButtonPressed(sender: AnyObject) {
        switchToScene(3)
    }
    
    private var handleTouch: UITouch?
    private var dynamicAnimator: UIDynamicAnimator?
    private var currentBehavior: UIDynamicBehavior?
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch:UITouch in touches.allObjects as [UITouch]{
            let point = touch.locationInView(interactiveHandleView)
            if rectContainsPoint(interactiveHandleView.frame, point: point) {
                handleTouch = touch as UITouch;
                dynamicAnimator?.removeAllBehaviors()
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        for touch:UITouch in touches.allObjects as [UITouch]{
            if touch == handleTouch{
                
                let newPoint = CGPointMake(interactiveHandleView.frame.origin.x, max(touch.locationInView(self.view).y,screenView.frame.origin.y));
                
                interactiveHandleView.frame = CGRectMake(newPoint.x, newPoint.y, interactiveHandleView.frame.width, interactiveHandleView.frame.height)
                
                updateScreenPosition()
            }
        }
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        for touch:UITouch in touches.allObjects as [UITouch]{
            if touch == handleTouch{
                letGoOfHandle()
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch:UITouch in touches.allObjects as [UITouch]{
            if touch == handleTouch{
                letGoOfHandle()
            }
        }
    }
    
    private func switchToScene(scene: Int){
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.sceneImageView.alpha = 0
            self.scene2ImageView.alpha = 0
            self.scene3ImageView.alpha = 0
            
            switch scene{
            case 1:
                self.sceneImageView.alpha = 1
            case 2:
                self.scene2ImageView.alpha = 1
            default:
                self.scene3ImageView.alpha = 1
            }
        });
    }
    
    private func updateScreenPosition(){
        var screenFrame = screenView.frame
        screenFrame.size.height = max(CGFloat(1), interactiveHandleView.frame.origin.y - screenFrame.origin.y + interactiveHandleView.frame.size.height)
        screenView.frame = screenFrame
        handleImageView.updateConstraints()
    }
    
    override func viewDidLoad() {
        dynamicAnimator = UIDynamicAnimator(referenceView: view)
    }
    
    
    private func rectContainsPoint(rect: CGRect, point: CGPoint) -> Bool{
        return point.x >= 0 && point.y >= 0 && point.x < rect.size.width && point.y < rect.size.height
    }

    
    private func letGoOfHandle(){
        let factor = getScreenPositionFactor()
        dynamicAnimator?.removeAllBehaviors()
        currentBehavior = nil
        
        let topOfWindow = sceneImageView.frame.origin.y
        let bottomOfWindow = CGRectGetMaxY(sceneImageView.frame)
        
        //is handle below window
        if factor>1.3{
            //we want to snap to the top
            currentBehavior = UISnapBehavior(item: interactiveHandleView, snapToPoint: CGPointMake(desiredHandleX()+interactiveHandleView.frame.size.width/2, sceneImageView.frame.origin.y+interactiveHandleView.frame.size.height/2))
        }else if factor > 1{
            //fall up to bottom
            let gravityBehavior = UIGravityBehavior(items: [interactiveHandleView])
            gravityBehavior.gravityDirection = CGVectorMake(0, -1)
            currentBehavior = gravityBehavior
            let collisionBehavior = UICollisionBehavior(items: [interactiveHandleView])
            collisionBehavior.collisionMode = UICollisionBehaviorMode.Boundaries
            collisionBehavior.addBoundaryWithIdentifier("barrier", fromPoint: CGPointMake(0, bottomOfWindow-interactiveHandleView.frame.size.height), toPoint: CGPointMake(view.frame.size.width, bottomOfWindow-interactiveHandleView.frame.size.height))
            dynamicAnimator?.addBehavior(collisionBehavior)
        }else if factor > 0.25{
            //fall to bottom
            currentBehavior = UIGravityBehavior(items: [interactiveHandleView])
            let collisionBehavior = UICollisionBehavior(items: [interactiveHandleView])
            collisionBehavior.collisionMode = UICollisionBehaviorMode.Boundaries
            collisionBehavior.addBoundaryWithIdentifier("barrier", fromPoint: CGPointMake(0, bottomOfWindow), toPoint: CGPointMake(view.frame.size.width, bottomOfWindow))
            dynamicAnimator?.addBehavior(collisionBehavior)
        }else{
            //fall to top
            let gravityBehavior = UIGravityBehavior(items: [interactiveHandleView])
            gravityBehavior.gravityDirection = CGVectorMake(0, -1)
            currentBehavior = gravityBehavior
        }
        
        let collisionBehavior = UICollisionBehavior(items: [interactiveHandleView])
        collisionBehavior.collisionMode = UICollisionBehaviorMode.Boundaries
        collisionBehavior.addBoundaryWithIdentifier("barrier", fromPoint: CGPointMake(0, topOfWindow), toPoint: CGPointMake(view.frame.size.width, topOfWindow))
        dynamicAnimator?.addBehavior(collisionBehavior)
        
        currentBehavior?.action = {() in
            self.updateScreenPosition()
            self.keepHandleOnTrack()
        }
        
        dynamicAnimator?.addBehavior(currentBehavior)
    }

    private func keepHandleOnTrack(){
        interactiveHandleView.transform = CGAffineTransformIdentity
        interactiveHandleView.frame = CGRectMake(desiredHandleX(), max(interactiveHandleView.frame.origin.y,sceneImageView.frame.origin.y-20), interactiveHandleView.frame.size.width, interactiveHandleView.frame.size.height)
    }
    
    private func desiredHandleX() -> CGFloat{
        return CGFloat(Float(self.view.frame.size.width/2) - Float(interactiveHandleView.frame.size.width/2))
    }
    
    
    private func getScreenPositionFactor() -> CGFloat{
        let screenHeight = screenView.frame.height
        let windowHeight = sceneImageView.frame.height
        return screenHeight/windowHeight
    }

}

