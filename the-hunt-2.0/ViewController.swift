//
//  ViewController.swift
//  the-hunt
//
//  Created by John Maddock on 12/12/18.
//  Copyright © 2018 John Maddock. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate  {
    
    //variable declarations!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var picker: UIPickerView!
    
    var textNode = SCNNode()
    
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //enables horitzontal plane detection
        
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch detected")
        if let touchLocation = touches.first?.location(in:sceneView){
            let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
            if let hitResult = hitTestResults.first{
                // addDot(at: hitResult)
                let alert = UIAlertController(title: "Scavenger Hunt", message: "Add a clue!", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.text = ""
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                    self.updateText(text: textField?.text ?? "", hitResult: hitResult)
                }))
                // 4. Present the alert.
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func updateText(text: String, hitResult: ARHitTestResult) {
        
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.magenta
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        textNode.constraints = [SCNBillboardConstraint()]
        sceneView.scene.rootNode.addChildNode(textNode)
        
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake{
            if self.loadButton.alpha==0{
                self.loadButton.alpha = 1
                self.saveButton.alpha = 1
                self.resetButton.alpha = 1
            }else{
                self.loadButton.alpha = 0
                self.saveButton.alpha = 0
                self.resetButton.alpha = 0
            }
            saveButton.layer.cornerRadius = 15
            saveButton.clipsToBounds = true
            loadButton.layer.cornerRadius = 10
            //loadButton.clipsToBounds = true
            resetButton.layer.cornerRadius = 5
            //resetButton.clipsToBounds = true
        }
        
        
    }
    
    
    @IBAction func saveExperience(_ button: UIButton) {
        
        
    }
    
    @IBAction func loadExperience(_ button: UIButton) {
        
        
    }
    
    @IBAction func reset(_ button: UIButton) {
        
    }
    
}

