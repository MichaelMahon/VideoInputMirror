//
//  ContentView.swift
//  VideoInputMirror
//
//  Created by Mike Mahon on 2/4/24.
//

import SwiftUI
import AVFoundation
import Combine

struct PlayerContainerView: NSViewRepresentable {
    let captureSession: AVCaptureSession
    @Binding var device: AVCaptureDevice?
    
    init(captureSession: AVCaptureSession, device: Binding<AVCaptureDevice?>) {
        self.captureSession = captureSession
        self._device = device
    }
    
    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(captureSession: captureSession, device: device)
    }
    
    func updateNSView(_ nsView: PlayerView, context: Context) { }
}


class PlayerView: NSView {
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var cancellables = Set<AnyCancellable>()
    
    var device: AVCaptureDevice?
    
    init(captureSession: AVCaptureSession, device: AVCaptureDevice?) {
        self.device = device
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(frame: .zero)
        
        setupLayer()
    }
    
    func setupLayer() {
        
        previewLayer?.frame = self.frame
        previewLayer?.contentsGravity = .resizeAspect
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        
        layer = previewLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}


class ContentViewModel: ObservableObject {
    @Published var currentDevice: AVCaptureDevice?
    
    @Published var isGranted: Bool = false
    var captureSession: AVCaptureSession!
    private var cancellables = Set<AnyCancellable>()
    
    @Published var selectedCameraIndex = 0
    @Published var availableCameras = [AVCaptureDevice]()
    
    init() {
        availableCameras = AVCaptureDevice.DiscoverySession(deviceTypes: [.external, .builtInWideAngleCamera, .continuityCamera], mediaType: .video, position: .unspecified).devices
        
        captureSession = AVCaptureSession()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.isGranted = true
                
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.isGranted = granted
                            self?.prepareCamera()
                        }
                    }
                }
                
            case .denied:
                self.isGranted = false
                return
                
            case .restricted:
                self.isGranted = false
                return
            @unknown default:
                fatalError()
        }
    }
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }
    
    func prepareCamera() {
        captureSession.sessionPreset = .high
        
        startSessionForDevice(currentDevice!)
    }
    
    func startSessionForDevice(_ device: AVCaptureDevice) {
        do {
            stopSession()
            let input = try AVCaptureDeviceInput(device: device)
            addInput(input)
            startSession()
        }
        catch {
            print("Something went wrong - ", error.localizedDescription)
        }
    }
    
    func addInput(_ input: AVCaptureInput) {
        guard captureSession.canAddInput(input) == true else {
            return
        }
        captureSession.addInput(input)
    }
}

struct ContentView: View {
    
    @EnvironmentObject var viewModel: ContentViewModel
    @State var currentDevice: AVCaptureDevice?
    
    var body: some View {
        PlayerContainerView(captureSession: viewModel.captureSession,
                            device: $currentDevice)
        .onReceive(self.viewModel.$currentDevice, perform: { currentDevice in
            self.currentDevice = currentDevice
        })
        .onChange(of: viewModel.selectedCameraIndex) {
            if let currentInput = viewModel.captureSession.inputs.first {
                viewModel.captureSession.removeInput(currentInput)
            }
            
            setupcamera()
        }
        .onAppear() {
            viewModel.checkAuthorization()
            setupcamera()
        }
    }
    
    func setupcamera() {
        viewModel.currentDevice = viewModel.availableCameras[viewModel.selectedCameraIndex]
        viewModel.prepareCamera()
    }
}
