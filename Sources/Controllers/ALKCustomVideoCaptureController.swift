//
//  CustomVideoCaptureController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 06/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

final class ALKCustomVideoViewController: ALKBaseViewController {

    //delegate
    var customCamDelegate:ALKCustomCameraProtocol!
    var camera = ALKCameraType.Back
    var videoFileOutput = AVCaptureMovieFileOutput()
    var filePath: URL?
    //photo library
    var asset: PHAsset!
    var allPhotos: PHFetchResult<PHAsset>!
    var selectedImage:UIImage!
    var cameraMode:ALKCameraPhotoType = .NoCropOption
    let option = PHImageRequestOptions()

    @IBOutlet private var previewView: UIView!
    @IBOutlet private var btnCapture: UIButton!
    @IBOutlet private var btnSwitchCam: UIButton!

    private var captureSession = AVCaptureSession()
    private let stillImageOutput = AVCaptureStillImageOutput()
    private var previewLayer : AVCaptureVideoPreviewLayer?
    // If we find a device we'll store it here for later use
    private var captureDevice : AVCaptureDevice?
    private var captureDeviceInput: AVCaptureDeviceInput?
    fileprivate var isUserControlEnable = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Camera"
        btnSwitchCam.isHidden = true
        reloadCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        if let outputs = captureSession.outputs, let output = outputs.first as? AVCaptureOutput {
            captureSession.removeOutput(output)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //ask for permission
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch authStatus {
        case .denied:

            // ask for permissions
            let camNotAvailable = NSLocalizedString("CamNotAvaiable", value: SystemMessage.Warning.CamNotAvaiable,  comment: "")
            let pleaseAllowCamera = NSLocalizedString("PleaseAllowCamera", value: SystemMessage.Camera.PleaseAllowCamera,  comment: "")
            let alertController = UIAlertController (title: camNotAvailable, message: pleaseAllowCamera, preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: {(success) in
                            //
                        })
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(settingsUrl)
                    }
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        default:()
        }

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


    override func viewDidLayoutSubviews()
    {
        //set frame
        self.previewLayer?.frame = self.previewView.frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Set protocol and Observer
    func setCustomCamDelegate(camMode:ALKCameraPhotoType, camDelegate:ALKCustomCameraProtocol)
    {
        self.cameraMode = camMode
        self.customCamDelegate = camDelegate
    }

    //MARK: - UI control
    private func setupNavigation() {
        self.navigationController?.title = title
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(color: .main, alpha: 0.6), for: .default)
        guard let navVC = self.navigationController else {return}
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
    }

    private func reloadCamera()
    {
        //stop previous capture session
        captureSession.stopRunning()
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) else {
            return
        }
        previewLayer.removeFromSuperlayer()
        self.previewLayer?.removeFromSuperlayer()

        // Do any additional setup after loading the view.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh

        if let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] {
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    if(camera == .Back)
                    {
                        if(device.position == AVCaptureDevicePosition.back) {
                            captureDevice = device
                            if captureDevice != nil {
                                checkCameraPermission()
                            }
                        }
                    }
                    else
                    {
                        if(device.position == AVCaptureDevicePosition.front) {
                            captureDevice = device
                            if captureDevice != nil {
                                checkCameraPermission()
                            }
                        }
                    }

                }
            }
        }
    }



    private func checkCameraPermission()
    {
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch authStatus {
        case .authorized:
            btnSwitchCam.isHidden = false
            beginSession()
        case .denied:
            // ask for permissions
            let camNotAvailable = NSLocalizedString("CamNotAvaiable", value: SystemMessage.Warning.CamNotAvaiable,  comment: "")
            let pleaseAllowCamera = NSLocalizedString("PleaseAllowCamera", value: SystemMessage.Camera.PleaseAllowCamera,  comment: "")
            let alertController = UIAlertController (title: camNotAvailable, message: pleaseAllowCamera, preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: {(success) in
                            //
                        })
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(settingsUrl)
                    }
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        case .notDetermined:
            // ask for permissions
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [weak self] (isGrant) in
                guard let weakSelf = self else{return}
                if isGrant {
                    DispatchQueue.main.async {
                        weakSelf.btnSwitchCam.isHidden = false
                    }
                }
            })
            self.beginSession()
        default:()
        }
    }

    @IBAction private func actionCameraCapture(_ sender: AnyObject) {
        saveToCamera()
    }

    private func beginSession() {

        do {
            try captureDeviceInput = AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]

            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
        }
        catch {
        }

        guard let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) else {
            return
        }

        //orientation of video
        let statusBarOrientation    = UIApplication.shared.statusBarOrientation
        var initialVideoOrientation = AVCaptureVideoOrientation.portrait
        if (statusBarOrientation != UIInterfaceOrientation.unknown) {
            initialVideoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue)!
        }

        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.connection.videoOrientation = initialVideoOrientation
        self.previewLayer = previewLayer
        //add camera view
        self.previewView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }

    private func saveToCamera() {
        if videoFileOutput.isRecording {
            videoFileOutput.stopRecording()
        } else {
            let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self

            self.captureSession.addOutput(videoFileOutput)

            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = String(format: "/VID-%f.mov", Date().timeIntervalSince1970)
            filePath = documentsURL.appendingPathComponent(fileName)

            // Do recording and save the output to the `filePath`
            videoFileOutput.startRecording(toOutputFileURL: filePath, recordingDelegate: recordingDelegate)
        }
    }


    @IBAction private func switchCamPress(_ sender: Any) {

        if isUserControlEnable {
            isUserControlEnable = false

            if(camera == .Back)
            {
                camera = .Front
            }
            else
            {
                camera = .Back
            }

            if let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] {
                for device in devices {
                    if (device.hasMediaType(AVMediaTypeVideo)) {

                        let currentCameraInput: AVCaptureInput = captureSession.inputs[0] as! AVCaptureInput
                        captureSession.removeInput(currentCameraInput)

                        let newCamera: AVCaptureDevice?
                        if(camera == .Front){
                            newCamera = self.cameraWithPosition(position: AVCaptureDevicePosition.front)
                        } else {
                            newCamera = self.cameraWithPosition(position: AVCaptureDevicePosition.back)
                        }
                        do {
                            try captureSession.addInput(AVCaptureDeviceInput(device: newCamera))
                            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
                            if captureSession.canAddOutput(stillImageOutput) {
                                captureSession.addOutput(stillImageOutput)
                            }
                        }
                        catch {
                        }
                        captureSession.commitConfiguration()

                        enableCameraControl(inSec: 1)
                        break
                    }
                }
            }
        }
    }

    private func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devices()
        for device in devices! {
            if((device as AnyObject).position == position){
                return device as! AVCaptureDevice
            }
        }
        return AVCaptureDevice(uniqueID: "")
    }


    @IBAction private func dismissCameraPress(_ sender: Any) {
        self.navigationController?.dismiss(animated: false, completion:nil)
    }

    private func enableCameraControl(inSec:Double)
    {
        let disT:DispatchTime = DispatchTime.now() + inSec
        DispatchQueue.main.asyncAfter(deadline: disT, execute: {
            self.isUserControlEnable = true
        })
    }

    //MARK: - Access to gallery images
    private func getAllImage(completion: (_ success: Bool) -> Void) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = false
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        (allPhotos != nil) ? completion(true) :  completion(false)
    }

//    private func createScrollGallery(isGrant:Bool) {
//        if isGrant
//        {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//                self.previewGallery.reloadData()
//            })
//        }
//
//    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destination = segue.destination

        if let topViewController = (destination as? UINavigationController)?.topViewController {
            destination = topViewController
        }

        if let customCameraPreviewVC = destination as? ALKCustomVideoPreviewViewController {
            guard let url = filePath else { return }
            customCameraPreviewVC.setUpPath(path: url.path)
        }
    }
}

extension ALKCustomVideoViewController: AVCaptureFileOutputRecordingDelegate {

    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    }

    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {

        self.performSegue(withIdentifier: "pushToVideoPreviewViewController", sender: nil)
    }
}
