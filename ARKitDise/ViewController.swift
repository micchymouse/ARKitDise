//
//  ViewController.swift
//  ARKitDise
//
//  Created by micchymouse on 2017/11/01.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    /// さいころの一辺の長さ
    private let diceLength: CGFloat = 0.04
    /// 床の厚み
    private let thickness: CGFloat = 0.03
    
    private var diceNode: SCNNode!
    private var isFloorRecognized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDice()
        
        sceneView.delegate = self
        
        // 平面認識の特徴点を表示
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        
        // 平面を検知するように指定
        configuration.planeDetection = .horizontal
        
        // セッション開始
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // セッション停止
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// 床を作成
    private func makeFloor(initAnchor: ARPlaneAnchor) -> SCNNode {
        
        let floorGeometry = SCNBox(width: CGFloat(initAnchor.extent.x),
                               height: thickness,
                               length: CGFloat(initAnchor.extent.z),
                               chamferRadius: 0)
        let floorNode = SCNNode(geometry: floorGeometry)
        
        // 床の位置を指定
        floorNode.position = SCNVector3Make(initAnchor.center.x, 0, initAnchor.center.z)
        // 床の判定を追加
        floorNode.physicsBody = SCNPhysicsBody(type: .kinematic,
                                               shape: SCNPhysicsShape(geometry: floorGeometry,
                                                                      options: nil))
        // 床を黒くする
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 0.0, alpha: 0.9)
        floorNode.geometry?.firstMaterial = material
        
        return floorNode
    }
    
    /// サイコロを初期化
    private func initDice() {
        
        let dice = SCNBox(width: diceLength, height: diceLength, length: diceLength, chamferRadius: 0)
        
        // テクスチャを設定
        let m1 = SCNMaterial()
        let m2 = SCNMaterial()
        let m3 = SCNMaterial()
        let m4 = SCNMaterial()
        let m5 = SCNMaterial()
        let m6 = SCNMaterial()
        m1.diffuse.contents = #imageLiteral(resourceName: "food1")
        m2.diffuse.contents = #imageLiteral(resourceName: "food2")
        m3.diffuse.contents = #imageLiteral(resourceName: "food3")
        m4.diffuse.contents = #imageLiteral(resourceName: "food4")
        m5.diffuse.contents = #imageLiteral(resourceName: "food5")
        m6.diffuse.contents = #imageLiteral(resourceName: "food6")
        dice.materials = [m1, m2, m3, m4, m5, m6]
        
        diceNode = SCNNode(geometry: dice)
        
        // サイコロの判定を追加
        let diceShape = SCNPhysicsShape(geometry: dice, options: nil)
        diceNode!.physicsBody = SCNPhysicsBody(type: .dynamic, shape: diceShape)
    }
    
    /// サイコロを出現させる
    ///
    /// - Parameter point: 作成の基準となる画面上の位置
    private func makeDice(point: CGPoint) {
        
        // 既存のサイコロに加わる力をリセット
        diceNode.physicsBody?.clearAllForces()
        // 既存のサイコロを削除
        diceNode.removeFromParentNode()
        
        // scneView上の位置を取得
        let results = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        
        guard let hitResult = results.first else {
            // タップした場所が認識された平面上でなければ何もしない
            return
        }
        
        // sceneView上のタップ座標のどこに箱を出現させるかを指定
        diceNode.position = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                           hitResult.worldTransform.columns.3.y + 0.2,
                                           hitResult.worldTransform.columns.3.z)
        
        // サイコロの回転状態を乱数で設定
        let randX = makeRandomSpinValue()
        let randY = makeRandomSpinValue()
        let randZ = makeRandomSpinValue()
        let randW = makeRandomSpinValue()
        diceNode.physicsBody?.applyTorque(SCNVector4(randX, randY, randZ, randW), asImpulse: false)
        // サイコロを少し上方向に投げる
        diceNode.physicsBody?.applyForce(SCNVector3(0, 1, 0), asImpulse: true)
        
        // ノードを追加
        sceneView.scene.rootNode.addChildNode(diceNode)
    }
    
    private func makeRandomSpinValue() -> Float {
        return Float((arc4random_uniform(UInt32(10))) + 1) / 10
    }
    
    @IBAction func didTapSceneView(_ recognizer: UITapGestureRecognizer) {
        makeDice(point: recognizer.location(in: sceneView))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        // 平面は最初に認識された１つのみ
        if !isFloorRecognized {
            node.addChildNode(makeFloor(initAnchor: planeAnchor))
            sceneView.debugOptions = []
            isFloorRecognized = true
        }
    }
}
