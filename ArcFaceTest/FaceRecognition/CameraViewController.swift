//
//  ViewController.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/1/27.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class CameraViewController: UIViewController {
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var sceneView: VirtualObjectARView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var addObjectButton: UIButton!
    var focusSquare = FocusSquare()
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    /// The view controller that displays the virtual object selection menu.
    var objectsViewController: VirtualObjectSelectionViewController?
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    @IBOutlet weak var canvas: UIView!
    @IBOutlet weak var glView: GLView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var id: UILabel!
    @IBOutlet weak var remark: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var infoStackView: UIView!
    @IBOutlet weak var cameraSwitch: UISwitch!
    
    private var ID: UInt = 0
    private var devicePosition = AVCaptureDevice.Position.front
    
    private static var cameraController = AFCameraController()
    private static var videoProcessor = AFVideoProcessor()
    private var arrayAllFaceRectView = NSMutableArray()
    private var _offscreenIn : LPASVLOFFSCREEN?
    
    private var didSetUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sceneView.delegate = self
        sceneView.session.delegate=self
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
        self.UIsetup()
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var purpose = Purpose.none
    private var _id: String?
    private var _name: String?
    private var _remark: String?
    private var attendance: String?
    private var group: String?
    
    /**
     说明使用此controller的目的
     
     - parameter purpose: 目的(CameraViewController.Purpose)
     */
    public func setPurpose(purpose: Purpose) {
        self.purpose = purpose
    }
    
    /**
     要求purpose = register
     
     注册时同时添加进attendance
     
     - parameter attendance: 考勤
     */
    public func setAttendance(attendance: String?) {
        self.attendance = attendance
    }
    
    /**
     要求purpose = register
     
     注册时同时添加进group
     
     - parameter group: 组
     */
    public func setGroup(group: String?) {
        self.group = group
    }
    
    /**
     要求purpose = register
     
     - parameter ID: ID
     */
    public func setID(ID: String?) {
        self._id = ID
    }
    
    /**
     要求purpose = register
     
     - parameter name: 姓名
     */
    public func setName(name: String?) {
        self._name = name
    }
    
    /**
     要求purpose = register
     
     - parameter remark: 更多
     */
    public func setRemark(remark: String?) {
        self._remark = remark
    }
    
    public static func removePerson(personID: UInt) -> Bool {
        return CameraViewController.videoProcessor.removePerson(personID)
    }
    
    // button register clicked
    @IBAction func registerClickd(_ sender: UIButton) {
        guard sender === self.registerButton else {
            return
        }
        
        switch purpose {
        case .register(success: let success):
            success(registerInput())
        case .photo:
            photoInput()
        default:
            break
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchDevicePosition(_ sender: UISwitch) {
        guard sender === self.cameraSwitch else {
            return
        }
        
        // 关闭控制权
        self.cameraSwitch.isEnabled = false
        self.didSetUp = false
        
        if self.cameraSwitch.isOn {
            self.devicePosition = .back
        } else {
            self.devicePosition = .front
        }
        
        // 重新打开（用另一个摄像头）
        self.setup()
        CameraViewController.cameraController.startCaptureSession()
        
        // 开启控制权
        self.cameraSwitch.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the `ARSession`.
        resetTracking()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        CameraViewController.cameraController.startCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        CameraViewController.cameraController.stopCaptureSession()
    }
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
       camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    func resetTracking() {
        virtualObjectInteraction.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }
    // MARK: - Focus Square
    
    func updateFocusSquare() {
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
            addObjectButton.isHidden = false
            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    @IBAction func backFunc(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
////////////////////
extension CameraViewController {
    enum Purpose {
        case register(success: (Bool) -> ())
        case recognition
        case photo
        case none
    }
}

extension CameraViewController: AFCameraControllerDelegate, AFVideoProcessorDelegate {
    static let IMAGE_WIDTH: CGFloat = 720
    static let IMAGE_HEIGHT: CGFloat = 1280
    
    func processRecognized(_ Id: UInt, personName: String!) {
        OperationQueue.main.addOperation {
            self.ID = Id
            self.name.text = personName
            if let person = InformationProvider.shared.personInfo(personID: Id) {
                self.id.text = person.id
                self.remark.text = person.remark
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard self.didSetUp else {
            return
        }
        
        guard let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let bufferWidth = Int32(CVPixelBufferGetWidth(cameraFrame))
        let bufferHeight = Int32(CVPixelBufferGetHeight(cameraFrame))
        
        guard let pOffscreenIn = self.offscreenFromSampleBuffer(sampleBuffer) else {
            return
        }
        
        guard let arrayFaceInfo = CameraViewController.videoProcessor.process(pOffscreenIn) as NSArray? else {
            return
        }
        
        OperationQueue.main.addOperation {
            let u32PixelArrayFormat = pOffscreenIn.pointee.u32PixelArrayFormat
            let ppu8Plane = pOffscreenIn.pointee.ppu8Plane
            
            if ASVL_PAF_RGB32_B8G8R8A8 == u32PixelArrayFormat || ASVL_PAF_RGB32_R8G8B8A8 == u32PixelArrayFormat {
                let ppu8Planes = UnsafeMutablePointer<GLubyte>(ppu8Plane.0)
                
                self.glView.render(bufferWidth, height: bufferHeight, textureData: ppu8Planes, bgra: ASVL_PAF_RGB32_B8G8R8A8 == u32PixelArrayFormat, textureName: "BACKGROUND_TEXTURE")
            } else if ASVL_PAF_NV12 == u32PixelArrayFormat {
                self.glView.render(bufferWidth, height: bufferHeight, yData: ppu8Plane.0, uvData: ppu8Plane.1)
            }
            
            if (self.arrayAllFaceRectView.count >= arrayFaceInfo.count) {
                for face in arrayFaceInfo.count..<self.arrayAllFaceRectView.count {
                    guard let faceRectView = self.arrayAllFaceRectView.object(at: face) as? UIView else {
                        continue
                    }
                    
                    faceRectView.isHidden = true
                }
            } else {
                for _ in self.arrayAllFaceRectView.count..<arrayFaceInfo.count {
                    guard let faceRectView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FaceRectVideoController").view else {
                        continue
                    }
                    self.view.addSubview(faceRectView)
                    self.arrayAllFaceRectView.add(faceRectView)
                }
            }
            
            for face in 0..<arrayFaceInfo.count {
                guard let faceRectView = self.arrayAllFaceRectView.object(at: face) as? UIView else {
                    continue
                }
                
                faceRectView.isHidden = false
                
                guard let videoFaceRect = arrayFaceInfo[face] as? AFVideoFaceRect else {
                    continue
                }
                
                faceRectView.frame = self.dataFaceRect2ViewFaceRect(videoFaceRect.faceRect)
            }
        }
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func fromLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }
    
    func takePhoto() {
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        
        guard self.ID != 0 else {
            return
        }
        updateCoreData(personID: self.ID, image: info[UIImagePickerControllerEditedImage] as? UIImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

// private methods
extension CameraViewController {
    fileprivate func UIsetup() {
        switch self.purpose {
        case .register:
            self.infoStackView.isHidden = true
        case .photo:
            self.infoStackView.isHidden = true
            self.registerButton.setTitle("photo", for: .normal)
        case .recognition, .none:
            self.registerButton.isHidden = true
        }
        
        switch self.devicePosition {
        case .front:
            self.cameraSwitch.isOn = false
        case .back:
            self.cameraSwitch.isOn = true
        case .unspecified:
            break
        }
    }
    
    fileprivate func setup() {
        let orientation = UIApplication.shared.statusBarOrientation
        guard let vorientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) else {
            return
        }
        
        let MIN = min(CameraViewController.IMAGE_WIDTH, CameraViewController.IMAGE_HEIGHT)
        let MAX = max(CameraViewController.IMAGE_WIDTH, CameraViewController.IMAGE_HEIGHT)
        
        let sizet = (orientation == .portrait || orientation == .portraitUpsideDown) ? CGSize(width: MIN, height: MAX) : CGSize(width: MAX, height: MIN)
        let sizeb = self.view.bounds.size
        
        var fwidth = sizeb.width
        var fheight = sizeb.height
        Utility.calcFitOutSize(sizet.width, oldH: sizet.height, newW: &fwidth, newH: &fheight)
        
        self.glView.frame = CGRect(x: (sizeb.width - fwidth) / 2, y: (sizeb.height - fheight) / 2, width: fwidth, height: fheight)
        self.glView.setInputSize(sizet, orientation: vorientation)
        
        // init fd switch
        // self.FDswitch.setOn(false, animated: false)
        
        // setup camera
        CameraViewController.cameraController.delegate = self
        CameraViewController.cameraController.setupCaptureSession(vorientation, position: self.devicePosition)
        
        // video processor
        CameraViewController.videoProcessor.delegate = self
        CameraViewController.videoProcessor.initProcessor()
        
        self.didSetUp = true
    }
    
    fileprivate func offscreenFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> LPASVLOFFSCREEN? {
        guard let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let bufferWidth = MInt32(CVPixelBufferGetWidth(cameraFrame))
        let bufferHeight = MInt32(CVPixelBufferGetHeight(cameraFrame))
        let pixelType = CVPixelBufferGetPixelFormatType(cameraFrame)
        
        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue: 0))
        
        if (kCVPixelFormatType_32BGRA == pixelType) {
            if let offscreenIn = _offscreenIn?.pointee {
                if offscreenIn.i32Width != bufferWidth || offscreenIn.i32Height != bufferHeight || ASVL_PAF_RGB32_B8G8R8A8 != offscreenIn.u32PixelArrayFormat {
                    Utility.freeOffscreen(_offscreenIn)
                    _offscreenIn = nil
                }
            }
            
            if _offscreenIn == nil {
                _offscreenIn = Utility.createOffscreen(bufferWidth, height: bufferHeight, format: MUInt32(ASVL_PAF_RGB32_B8G8R8A8))
            }
            
            guard let offscreenIn = _offscreenIn?.pointee else {
                return nil
            }
            
            let rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0)
            let baseAddress = CVPixelBufferGetBaseAddress(cameraFrame)
            
            if rowBytePlane0 == offscreenIn.pi32Pitch.0 {
                memcpy(offscreenIn.ppu8Plane.0, baseAddress, Int(bufferHeight * offscreenIn.pi32Pitch.0))
            } else {
                for i in 0..<Int(bufferHeight) {
                    memcpy(offscreenIn.ppu8Plane.0?.advanced(by: i * Int(offscreenIn.pi32Pitch.0)), baseAddress?.advanced(by: i * rowBytePlane0), Int(offscreenIn.pi32Pitch.0))
                }
            }
        } else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) {
            if let offscreenIn = _offscreenIn?.pointee {
                if offscreenIn.i32Width != bufferWidth || offscreenIn.i32Height != bufferHeight || ASVL_PAF_NV12 != offscreenIn.u32PixelArrayFormat {
                    Utility.freeOffscreen(_offscreenIn)
                    _offscreenIn = nil
                }
            }
            
            if _offscreenIn == nil {
                _offscreenIn = Utility.createOffscreen(bufferWidth, height: bufferHeight, format: MUInt32(ASVL_PAF_NV12))
            }
            
            guard let offscreenIn = _offscreenIn?.pointee else {
                return nil
            }
            
            let baseAddress0 = CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0)
            let baseAddress1 = CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1)
            
            let rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0)
            let rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1)
            
            // YData
            if rowBytePlane0 == offscreenIn.pi32Pitch.0 {
                memcpy(offscreenIn.ppu8Plane.0, baseAddress0, rowBytePlane0 * Int(bufferHeight))
            } else {
                for i in 0..<Int(bufferHeight) {
                    memcpy(offscreenIn.ppu8Plane.0?.advanced(by: i * Int(bufferWidth)), baseAddress0?.advanced(by: i * rowBytePlane0), Int(bufferWidth))
                }
            }
            
            // uv data
            if rowBytePlane1 == offscreenIn.pi32Pitch.1 {
                memcpy(offscreenIn.ppu8Plane.1, baseAddress1, rowBytePlane1 * Int(bufferHeight) / 2)
            } else {
                for i in 0..<Int(bufferHeight / 2) {
                    memcpy(offscreenIn.ppu8Plane.1?.advanced(by: i * Int(bufferWidth)), baseAddress1?.advanced(by: i * rowBytePlane1), Int(bufferWidth))
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue: 0))
        
        return _offscreenIn
    }
    
    fileprivate func dataFaceRect2ViewFaceRect(_ faceRect: MRECT) -> CGRect {
        let frameGLView = self.glView.frame
        let x = frameGLView.width * CGFloat(faceRect.left) / CameraViewController.IMAGE_WIDTH
        let y = frameGLView.height * CGFloat(faceRect.top) / CameraViewController.IMAGE_HEIGHT
        let width = frameGLView.width * CGFloat(faceRect.right - faceRect.left) / CameraViewController.IMAGE_WIDTH
        let height = frameGLView.height * CGFloat(faceRect.bottom - faceRect.top) / CameraViewController.IMAGE_HEIGHT
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    fileprivate func registerInput() -> Bool {
        guard let id = self._id, let name = self._name, let remark = self._remark else {
            return false
        }
        
        guard !name.isEmpty else {
            return false
        }
        
        let personID = CameraViewController.videoProcessor.registerDetectedPerson(name)
        guard personID != 0 else {
            return false
        }
        
        self.addIntoCoreData(personID: personID, id: id, name: name, remark: remark, image: nil)
        
        return true
    }
    
    /*
    fileprivate func registerInput() -> Bool {
        let ralert = UIAlertController(title: "Register", message: "", preferredStyle: .alert)
        // ID name remark
        let rok = UIAlertAction(title: "ok", style: .default) { action in
            guard let id = ralert.textFields?[0].text,
                  let name = ralert.textFields?[1].text,
                  let remark = ralert.textFields?[2].text else {
                    return false
            }
            
            guard !name.isEmpty else {
                return false
            }
            
            let personID = self.videoProcessor.registerDetectedPerson(name)
            guard personID != 0 else {
                return false
            }
            
            self.addIntoCoreData(personID: personID, id: id, name: name, remark: remark, image: nil)
            
            let sAlert = UIAlertController(title: "Register Succeed", message: "", preferredStyle: .alert)
            
            self.present(sAlert, animated: true) {
                let timer = Timer(timeInterval: 20, repeats: false) { _ in
                    sAlert.dismiss(animated: true, completion: nil)
                }
                
                timer.fire()
            }
        }
        let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        
        ralert.addAction(rok)
        ralert.addAction(cancel)
        
        ralert.addTextField { textField in
            textField.placeholder = "id"
        }
        ralert.addTextField { textField in
            textField.placeholder = "name"
        }
        ralert.addTextField { textField in
            textField.placeholder = "remark"
        }
        
        self.present(ralert, animated: true, completion: nil)
    }
     */
    
    fileprivate func photoInput() {
        let chooseAlert = UIAlertController(title: "Choose", message: nil, preferredStyle: .actionSheet)
        let fromLibrary = UIAlertAction(title: "从相册", style: .default) { action in
            self.fromLibrary()
        }
        let takingPhoto = UIAlertAction(title: "从相机", style: .default) { action in
            self.takePhoto()
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        chooseAlert.addAction(fromLibrary)
        chooseAlert.addAction(takingPhoto)
        chooseAlert.addAction(cancel)
        
        self.present(chooseAlert, animated: true, completion: nil)
    }
    
    fileprivate func addIntoCoreData(personID: UInt, id: String, name: String, remark: String, image: UIImage?) {
        let info = InformationProvider.shared
        
        guard info.add(personID: personID, id: id, name: name, password: "", remark: remark, attendance: self.attendance, group: self.group, image: image) else {
            print("save error")
            return
        }
    }
    
    fileprivate func updateCoreData(personID: UInt, image: UIImage?) {
        let info = InformationProvider.shared
        
        guard info.update(personID: personID, id: nil, name: nil, password: nil, remark: nil, attendance: nil, group: nil, image: image) else {
            print("update error")
            return
        }
    }
}
