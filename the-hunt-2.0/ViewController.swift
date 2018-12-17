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
    
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    // Storage stuff
    let defaults = UserDefaults.standard
    var currentHunt = "First Hunt"
    
    // Global var for the Text Node
    var textNode = SCNNode()
    
    
    // Lock the orientation of the app to the orientation in which it is launched
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetTrackingConfiguration()
    }
    
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
        } 
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // TOUCH BEGAN
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch detected")
        if let touchLocation = touches.first?.location(in:sceneView){
            let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
            
            if let hitResult = hitTestResults.first{
                let anchor = ARAnchor(transform: hitResult.worldTransform)
                let alert = UIAlertController(title: "Scavenger Hunt", message: "Add a clue!", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.text = ""
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert?.textFields![0]
                    // Force unwrapping because we know it exists.
                    guard !(anchor is ARPlaneAnchor) else { return }
                    self.textNode = self.generateTextNode(text: textField?.text ?? "", hitResult: hitResult)
                    self.sceneView.session.add(anchor: anchor)
                }))
                // Present the alert.
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // GENERATE TEXT NODE
    func generateTextNode(text: String, hitResult: ARHitTestResult) -> SCNNode {
        let text = SCNText(string: text, extrusionDepth: 1.0)
        let textNode = SCNNode()
        text.firstMaterial?.diffuse.contents = UIColor.magenta
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        textNode.geometry = text
        textNode.constraints = [SCNBillboardConstraint()]
        return textNode
    }
    
    // RENDERER
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard !(anchor is ARPlaneAnchor) else { return }
        DispatchQueue.main.async {
            node.addChildNode(self.textNode)
        }
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
            resetButton.layer.cornerRadius = 5
        }
    }
    
    @IBAction func saveExperience(_ button: UIButton) {
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
        try data.write(to: self.worldMapURL, options: [.atomic])
        
    }
    
    @IBAction func loadExperience(_ button: UIButton) {
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        resetTrackingConfiguration(with: worldMap)
    }
    
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
            let worldMap = unarchievedObject else { return nil }
        return worldMap
    }
    
    func retrieveWorldMapData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: self.worldMapURL)
        } catch {
            return nil
        }
    }
    
    @IBAction func reset(_ button: UIButton) {
        resetTrackingConfiguration()
    }
    
    @IBAction func deleteSaves(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "allHunts")
    }
}

