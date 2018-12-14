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
    
    let defaults = UserDefaults.standard
    var currentHunt = "First Hunt"
    
    var textNode = SCNNode()
    
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
//        let configuration = ARWorldTrackingConfiguration()
        
        //enables horitzontal plane detection
        
//        configuration.planeDetection = .horizontal
        
        // Run the view's session
//        sceneView.session.run(configuration)
        resetTrackingConfiguration()
    }
    
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
        } else {
            return
        }
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
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
                let anchor = ARAnchor(transform: hitResult.worldTransform)
                sceneView.session.add(anchor: anchor)
                // addDot(at: hitResult)
                let alert = UIAlertController(title: "Scavenger Hunt", message: "Add a clue!", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.text = ""
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                    guard !(anchor is ARPlaneAnchor) else { return }
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
        let alertController = UIAlertController(title: "Add New Name", message: "", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "\(self.currentHunt)"
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            self.currentHunt = firstTextField.text!
            print(self.currentHunt)
            self.getTheCurrentWorldMap()
            
        })
        
        alertController.addAction(saveAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func getTheCurrentWorldMap() {
        
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                return
            }
            
            
            do {
                try self.archive(worldMap: worldMap)
                DispatchQueue.main.async {
                }
            } catch {
                fatalError("Error saving world map: \(error.localizedDescription)")
            }
        }
    }
    
    func archive(worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        let dictionary : NSDictionary = [
            "name": "\(self.currentHunt)",
            "data": data]
        
        if var allHunts = defaults.array(forKey: "allHunts") {
            print(allHunts)
            UserDefaults.standard.removeObject(forKey: "allHunts")
            allHunts.append(self.currentHunt)
            defaults.set(allHunts, forKey: "allHunts")
            print(defaults.array(forKey: "allHunts"))
        } else {
            defaults.set(["\(self.currentHunt)"], forKey: "allHunts")
        }
        
        defaults.set(dictionary, forKey: "\(self.currentHunt)")
        
    }
    
    @IBAction func loadExperience(_ button: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let maps = defaults.array(forKey: "allHunts") {
            if maps.count > 0 {
                let saved1 = maps[0]
                alert.addAction(UIAlertAction(title: "\(saved1)", style: .default) { _ in
                    let dict = self.defaults.dictionary(forKey: "\(saved1)")
                    let worldMapData = dict?["data"]! as? Data
                    let worldMap = self.unarchive(worldMapData: worldMapData!)
                    self.resetTrackingConfiguration(with: worldMap)
                })
            }
            
            if maps.count > 1 {
                let saved2 = maps[1]
                alert.addAction(UIAlertAction(title: "\(saved2)", style: .default) { _ in
                    
                    let dict = self.defaults.dictionary(forKey: "\(saved2)")
                    let worldMapData = dict?["data"]! as? Data
                    let worldMap = self.unarchive(worldMapData: worldMapData!)
                    self.resetTrackingConfiguration(with: worldMap)
                })
            }
            
            if maps.count > 2 {
                let saved3 = maps[2]
                alert.addAction(UIAlertAction(title: "\(saved3)", style: .default) { _ in
                    
                    let dict = self.defaults.dictionary(forKey: "\(saved3)")
                    let worldMapData = dict?["data"]! as? Data
                    let worldMap = self.unarchive(worldMapData: worldMapData!)
                    self.resetTrackingConfiguration(with: worldMap)
                })
            }
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancel")
        })
        
        present(alert, animated: true)
        
    }
    
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
            let worldMap = unarchievedObject else { return nil }
        return worldMap
    }
    
    @IBAction func reset(_ button: UIButton) {
        resetTrackingConfiguration()
    }
    
}

