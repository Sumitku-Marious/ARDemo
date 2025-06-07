//
//  ViewController.swift
//  ARDemo
//
//  Created by sumit on 07/06/25.
//

import UIKit
import AVFoundation
import Vision


class ViewController: UIViewController {
    
    let options = ["Lips", "Eyelashes", "Eyelid", "Chin", "Cheek"]
    var selectedOption: String = ""
    
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var overlayLayer = CAShapeLayer()
    let sequenceHandler = VNSequenceRequestHandler()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraPermissionAndStart()
        setupMenu()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera),
              captureSession.canAddInput(input) else {
            print("Error setting up front camera input")
            return
        }
        
        captureSession.addInput(input)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()
    }
    
    func setupMenu() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MenuCell.self, forCellWithReuseIdentifier: "MenuCell")
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func drawLips(on face: VNFaceObservation) {
        guard selectedOption == "Lips",
              let landmarks = face.landmarks,
              let outerLips = landmarks.outerLips else { return }
        
        let outerPoints = outerLips.normalizedPoints
        let count = outerPoints.count
        guard count > 10 else { return } // Safety check
        
        // Split outer lips points into top and bottom parts
        let half = count / 2
        let topLipPoints = Array(outerPoints[0...half])
        let bottomLipPoints = Array(outerPoints[half..<count])
        
        // Helper function to create path from points
        func createLipPath(points: [CGPoint], boundingBox: CGRect) -> UIBezierPath {
            let path = UIBezierPath()
            let convertedPoints = points.map { convert($0, faceBoundingBox: boundingBox) }
            guard let first = convertedPoints.first else { return path }
            path.move(to: first)
            for pt in convertedPoints.dropFirst() {
                path.addLine(to: pt)
            }
            path.close()
            return path
        }
        
        let topPath = createLipPath(points: topLipPoints, boundingBox: face.boundingBox)
        let bottomPath = createLipPath(points: bottomLipPoints, boundingBox: face.boundingBox)
        
        // Combine paths
        let combinedPath = UIBezierPath()
        combinedPath.append(topPath)
        combinedPath.append(bottomPath)
        
        // Remove old overlay and create new layer
        overlayLayer.removeFromSuperlayer()
        overlayLayer = CAShapeLayer()
        overlayLayer.path = combinedPath.cgPath
        overlayLayer.fillColor = UIColor.red.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(overlayLayer)
    }
    
    
    func VNImagePointForFaceLandmarkPoint(_ point: CGPoint, _ width: Int, _ height: Int, _ boundingBox: CGRect) -> CGPoint {
        let x = boundingBox.origin.x + point.x * boundingBox.width
        let y = boundingBox.origin.y + point.y * boundingBox.height
        let convertedX = CGFloat(x) * CGFloat(width)
        let convertedY = (1 - CGFloat(y)) * CGFloat(height) // Flip Y
        return CGPoint(x: convertedX, y: convertedY)
    }
    
    func checkCameraPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.showCameraAccessAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraAccessAlert()
        @unknown default:
            break
        }
    }
    func showCameraAccessAlert() {
        let alert = UIAlertController(title: "Camera Access Denied",
                                      message: "Please enable camera access in Settings to use this feature.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        present(alert, animated: true)
    }
    
    
    func convert(_ point: CGPoint, faceBoundingBox: CGRect) -> CGPoint {
        // Face bounding box is normalized (0..1) coordinates in image
        // point is normalized inside bounding box
        // We want to map to UIView coordinates
        
        // 1. Convert landmark point to normalized image coordinates
        let normalizedX = faceBoundingBox.origin.x + point.x * faceBoundingBox.width
        let normalizedY = faceBoundingBox.origin.y + point.y * faceBoundingBox.height
        
        // 2. Vision's coordinate system origin is bottom-left. UIKit's is top-left.
        let flippedY = 1 - normalizedY
        
        // 3. Get previewLayer frame size
        let width = previewLayer.bounds.width
        let height = previewLayer.bounds.height
        
        // 4. Map normalized coordinates to previewLayer coordinates
        let x = normalizedX * width
        let y = flippedY * height
        
        return CGPoint(x: x, y: y)
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { (req, err) in
            guard let results = req.results as? [VNFaceObservation], let face = results.first else {
                DispatchQueue.main.async { self.overlayLayer.removeFromSuperlayer() }
                return
            }
            
            DispatchQueue.main.async {
                self.drawLips(on: face)
            }
        }
        
        try? sequenceHandler.perform([request], on: pixelBuffer)
    }
}

// MARK: - UICollectionView
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCell
        cell.label.text = options[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected: \(options[indexPath.item])")
        // Add overlay logic later
        self.selectedOption = options[indexPath.item]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 40)
    }
}



