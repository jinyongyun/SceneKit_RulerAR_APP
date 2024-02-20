# SceneKit_RulerAR_APP
📐 공대생 필수, AR 길이 측정 앱

오늘 만들어 볼 앱은 AR 길이 측정 앱이다!

왜 실험 실습에서 자가 없거나 부족해서 곤란했던 경험…공대생이라면 누구나 한 번씩 있을 것이다.

그럴 때 자연스럽게 켜서 사용하면 무척이나 유용할 것 같다.

# 📐 제작 과정

프로젝트 이름은 RulerAR로 지었고, 저번과 마찬가지로 초기설정은 SceneKit를 이용한다.

touchesBegan 메서드를 오버라이드해서 우리가 터치한 두 점 사이의 거리를 구하는 방식으로 앱을 만들 것이다.

만들어 준 전역변수들이다. 

```swift
      var dotNodes = [SCNNode]()  //점을 찍기 위한 노드 (점 2개라 배열로)
      var textNode = SCNNode()  // 공중에 텍스트를 띄우기 위한 Node
```

sceneView의 raycastQuery 메서드를 통해 화면을 터치 시, 터치한 그 부분의 공간좌표 요청을(쿼리) 받아서

sceneView.session.raycast 메서드 인자로 쿼리를 넣어주면 ARRaycastResult 형태로 공간 좌표 결과를 얻을 수 있다!

```swift
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
```

위에서 마지막에 쓰인 addDot 즉 실제 공간에 점을 추가하는 메서드는 다음과 같이 구상했다.

이전에 진행했던 태양계 AR 앱 제작에서 사용했던 ARKit에서의 형상 변환 과정이다.

```swift
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
```

이번에도 마지막에 쓰인 calculate를 그 다음에 구상했다. 사실 제일 처음 만든 메서드가 calculate이지만 구조를 이해하기 편하도록 addDot 이후에 배치했다.

내용은 중학교 때 배우는 3차원 좌표상에서의 두 점 사이의 거리를 구하는 공식을 이용했다.

```swift
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
```

마지막에 계산이 될 때마다 새로 텍스트를 업데이트 해주기 위한 함수 updateText가 들어갔다.

```swift
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
```

태양계에서도 위에서 점을 만들 때도 사용한 형상 변환 과정과 똑같다 (물론 SCNText 생성 시 따로 Material 객체를 만들 필요가 없다.)

마지막으로 오버라이드 했던 touchesBegan 메서드에서 맨 처음에 사용됐던 resetDot 메서드를 작성했다.

터치를 시작하기 전에 점이 2개 이상인지 검사한 후, 만약 두 개 이상이면 리셋시키는 것이다.

```swift
// dotNode 배열의 수가 2 이상이면, 부모 노드로부터 제외
      func resetDot() {
          if dotNodes.count >= 2 {
              dotNodes.forEach { $0.removeFromParentNode() }
              dotNodes = [SCNNode]() //새로운 배열로 초기화!
          }
      }
```

## 실제 구동 화면


https://github.com/jinyongyun/SceneKit_RulerAR_APP/assets/102133961/1540f004-d3e6-4d32-af05-5b091d045190



실제 저 토이스토리 마우스패드의 길이는 13.50cm이다. 꽤 정확도가 있는 것을 알 수 있다.

3차원 공간을 바탕으로 거리를 측정하기 때문에 

먼 거리라고 하더라도 대략적으로 수치가 맞는다.

키보드는 42cm이고(측정값 42.32)

이것도 1cm 이내의 오차를 보이는 것을 알 수 있다.
