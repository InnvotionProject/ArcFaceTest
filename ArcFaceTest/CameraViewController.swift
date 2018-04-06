//
//  ViewController.swift
//  ArcFaceTest
//
//  Created by 王宇鑫 on 2018/1/27.
//  Copyright © 2018年 王宇鑫. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    @IBOutlet weak var glView: GLView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var infoStackView: UIView!
    @IBOutlet weak var cameraSwitch: UISwitch!
    
    private var ID: UInt = 0
    private var devicePosition = AVCaptureDevice.Position.front
    
    var cameraController = AFCameraController()
    var videoProcessor = AFVideoProcessor()
    var arrayAllFaceRectView = NSMutableArray()
    var _offscreenIn : LPASVLOFFSCREEN?
    
    var didSetUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.UIsetup()
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var purpose = Purpose.none
    
    func setPurpose(purpose: Purpose) {
        self.purpose = purpose
    }

    // button register clicked
    @IBAction func registerClickd(_ sender: UIButton) {
        guard sender === self.registerButton else {
            return
        }
        
        switch purpose {
        case .register:
            registerInput()
        case .photo:
            photoInput()
        default:
            break
        }
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
        
        self.setup()
        
        // 开启控制权
        self.cameraSwitch.isEnabled = true
    }
    
    @IBAction func backFunc(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension CameraViewController {
    enum Purpose {
        case register
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
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard self.didSetUp else {
            return
        }
        
        guard UIApplication.shared.applicationState == .active else {
            return // OPENGL ES commands could not be excuted in background
        }
        
        guard let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let bufferWidth = Int32(CVPixelBufferGetWidth(cameraFrame))
        let bufferHeight = Int32(CVPixelBufferGetHeight(cameraFrame))
        
        guard let pOffscreenIn = self.offscreenFromSampleBuffer(sampleBuffer) else {
            return
        }
        
        guard let arrayFaceRect = self.videoProcessor.process(pOffscreenIn) as NSArray? else {
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
            
            if (self.arrayAllFaceRectView.count >= arrayFaceRect.count) {
                for face in arrayFaceRect.count..<self.arrayAllFaceRectView.count {
                    guard let faceRectView = self.arrayAllFaceRectView.object(at: face) as? UIView else {
                        continue
                    }
                    
                    faceRectView.isHidden = true
                }
            } else {
                for _ in self.arrayAllFaceRectView.count..<arrayFaceRect.count {
                    guard let faceRectView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FaceRectVideoController").view else {
                        continue
                    }
                    self.view.addSubview(faceRectView)
                    self.arrayAllFaceRectView.add(faceRectView)
                }
            }
            
            for face in 0..<arrayFaceRect.count {
                guard let faceRectView = self.arrayAllFaceRectView.object(at: face) as? UIView else {
                    continue
                }
                
                faceRectView.isHidden = false
                
                guard let videoFaceRect = arrayFaceRect[face] as? AFVideoFaceRect else {
                    continue
                }
                
                faceRectView.frame = self.dataFaceRect2ViewFaceRect(videoFaceRect.faceRect)
            }
        }
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    fileprivate func photoInput() {
        guard self.ID != 0 else {
            return
        }
        
        // TODO: 搞清楚需求
    }
}

// private methods
extension CameraViewController {
    fileprivate func UIsetup() {
        
        switch self.purpose {
        case .register:
            self.infoStackView.isHidden = true
        case .photo:
            //self.infoStackView.isHidden = true
            /*
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.glView
            }
            */
            break
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
        
        // start camera
        self.cameraController.delegate = self
        self.cameraController.setupCaptureSession(vorientation, position: self.devicePosition)
        self.cameraController.startCaptureSession()
        
        // video processor
        self.videoProcessor.delegate = self
        self.videoProcessor.initProcessor()
        
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
    
    fileprivate func registerInput() {
        let ralert = UIAlertController(title: "Register", message: "", preferredStyle: .alert)
        // ID name remark
        let rok = UIAlertAction(title: "ok", style: .default) { action in
            guard let id = ralert.textFields?[0].text,
                  let name = ralert.textFields?[1].text,
                  let remark = ralert.textFields?[2].text else {
                    return
            }
            
            guard !name.isEmpty else {
                return
            }
            
            let personID = self.videoProcessor.registerDetectedPerson(name)
            guard personID != 0 else {
                return
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
    
    fileprivate func addIntoCoreData(personID: UInt, id: String, name: String, remark: String, image: UIImage?) {
        let info = InformationProvider.shared
        guard info.add(personID: personID, id: id, name: name, password: "", remark: remark, attendance: nil, group: nil, image: image == nil ? #imageLiteral(resourceName: "InitialFace") : image ) else {
            print("save error")
            return
        }
    }
}
