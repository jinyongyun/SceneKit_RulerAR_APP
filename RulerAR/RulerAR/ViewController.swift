//
//  ViewController.swift
//  RulerAR
//
//  Created by jinyong yun on 2/20/24.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
      var dotNodes = [SCNNode]()  //점을 찍기 위한 노드 (2개라 배열로)
      var textNode = SCNNode()  // 공중에 텍스트를 띄우기 위한 Node
      
      override func viewDidLoad() {
          super.viewDidLoad()
          
          // Set the view's delegate
          sceneView.delegate = self
          
      }
      
      override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          
          // Create a session configuration
          let configuration = ARWorldTrackingConfiguration()
          
          configuration.planeDetection = .horizontal // 바닥, 즉 수평 감지를 위한 코드
          // Run the view's session
          sceneView.session.run(configuration)
      }
      
      override func viewWillDisappear(_ animated: Bool) {
          super.viewWillDisappear(animated)
          
          // Pause the view's session
          sceneView.session.pause()
      }
      
      override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
          
          resetDot() // 점 3개 찍히면 안되니까, 2개 이상이면 reset 해줘야 한다!!
          
          //첫번째 터치 이벤트가 발생할 때까지 못넘어가
          guard let touch = touches.first else { return }
          
          // sceneView안에서 터치되는 위치 얻기
          let touchLocation = touch.location(in: sceneView)
          
          // 핸드폰 화면(2D) -> 3D로 위에서 얻은 touchLocation을 변환하여 공간 좌표 요청인 쿼리로 변환
          guard let locationQuery = sceneView.raycastQuery(from: touchLocation,
                                                   allowing: .existingPlaneGeometry,
                                                   alignment: .any) else { return }
          
          // 공간 좌표 요청을 위치 좌표로!
          let locationResults = sceneView.session.raycast(locationQuery)
          
          // 터치시 3D공간의 위치결과
          guard let locationResult = locationResults.first else { return }
          
          //받은 위치결과를 바탕으로 화면에 점을 추가
          addDot(at: locationResult)
      }
      
    
      //화면에 점을 추가하는 메서드
      //ARKit에서의 형상변환 과정은 앞에서 했던 태양계 AR 앱에서 많이 다뤘다!
      func addDot(at location: ARRaycastResult) {
          
          let dotGeometry = SCNSphere(radius: 0.01)
          
          let material = SCNMaterial()
          material.diffuse.contents = UIColor.black
          
          dotGeometry.materials = [material]
          
          let dotNode = SCNNode()
          
          dotNode.geometry = dotGeometry
          
          dotNode.position = SCNVector3(location.worldTransform.columns.3.x,
                                        location.worldTransform.columns.3.y,
                                        location.worldTransform.columns.3.z)
          
          sceneView.scene.rootNode.addChildNode(dotNode)
          
          // 점 초기화에서 한꺼번에 초기화 하려면 배열 전역변수에 담아야 함
          dotNodes.append(dotNode)
          
          // 점을 두번 찍으면 계산하게 만들었습니다.
          if dotNodes.count >= 2 {
              calculate() // 공간상에서 두 점 사이의 거리를 구하는 메서드
          }
      }
      
      func calculate() {
          
          let startDot = dotNodes[0]
          let endDot = dotNodes[1]
          
          // 3차원 좌표계에서 두 점 사이의 거리 공식
          let distance = sqrtf(powf(endDot.position.x - startDot.position.x, 2) +
                               powf(endDot.position.y - startDot.position.y, 2) +
                               powf(endDot.position.z - startDot.position.z, 2))
          
          // cm로 변환, 기본은 m라고 앞에서 말했죠?!
          let distanceCm = String(format: "%.2f", distance * 100)
          
          //화면상에서 텍스트 노드 띄우기 (cm 사용자에게 알려주기, 위치 기준은 엔드포인트)
          updateText(text: distanceCm + "cm", atPosition: endDot.position)
      }
    
    
      //공중에 입체 텍스트 띄우기
      func updateText(text: String, atPosition position: SCNVector3) {
          
          // 업데이트 될 때 마다 텍스트 지우기
          textNode.removeFromParentNode()
          
          // 입체 텍스트 노드 타입
          let textGeometry = SCNText(string: text, extrusionDepth: 2.0)
          
          // 텍스트 노드 색상, 입체감 있는 텍스트를 생성할 때는 material 따로 만들 필요 없다
          textGeometry.firstMaterial?.diffuse.contents = UIColor.black
          
          // 노드로 생성
          textNode = SCNNode(geometry: textGeometry)
          
          // 텍스트 위치 선정
          textNode.position = SCNVector3(position.x + 0.05, position.y  , position.z - 0.25)
          
          // 기본 단위가 미터라 스케일 줄여야 함!
          textNode.scale = SCNVector3(0.009, 0.009, 0.009)
          
         // 마지막에 루트노드에 추가
          sceneView.scene.rootNode.addChildNode(textNode)
      }
    
    
      // dotNode 배열의 수가 2 이상이면, 부모 노드로부터 제외
      func resetDot() {
          if dotNodes.count >= 2 {
              dotNodes.forEach { $0.removeFromParentNode() }
              dotNodes = [SCNNode]() //새로운 배열로 초기화!
          }
      }
    
    
}
