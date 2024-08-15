//
//  ViewController.swift
//  SpatialAudio
//
//  Created by Thejas K on 12/08/24.
//



import UIKit
import AVFoundation
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var seekBar: UISlider!
    
    //var audioNode : AudioNode!
    var sceneView : SKScene!
    var gameView : GameView?
    
    var scnAudioPlayer : SCNAudioPlayer!
    var audioSource : SCNAudioSource!
    
    var audioEngine: AVAudioEngine!
    var environmentNode: AVAudioEnvironmentNode!
    var playerNode: AVAudioPlayerNode!
    var audioFile: AVAudioFile!
    var mixerNode: AVAudioMixerNode!
    
    var playBackTimer : Timer?
    var movingPoint = AVAudio3DPoint(x: 0.0, y: 0.0, z: 0.0)
    var positionSimulator = 1.0
    
    let radius: Float = 5.0
    var angle: Float = 1.0
    var currentZ: Float = -10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let audioFileURL = Bundle.main.url(forResource: "sample", withExtension: "mp3") else {
            print("Audio file not found")
            return
        }
        
        audioFile = try! AVAudioFile(forReading: audioFileURL)
        
        addAVAudioNode()
        //addSKAudioNode()
        
        
        scheduleAudioPlayback()
        startMovingAudioSource()
    }
    
    func addSKAudioNode() {
        
        let scene = SCNScene(named: "cube.scn")
        
        gameView = GameView(frame: self.view.bounds)
        
        for view in self.view.subviews {
            
            if self.view.subviews.contains(view) {
                self.gameView = view as? GameView
                print("scene assigned for game view")
            }
        }
        
        gameView?.scene = scene
        
    }
    
    func addAVAudioNode() {
        
        // Initialize the audio engine
        audioEngine = AVAudioEngine()
        
        // Create and attach the environment node
        environmentNode = AVAudioEnvironmentNode()
        
        playerNode = AVAudioPlayerNode()
        mixerNode = AVAudioMixerNode()
        
//        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
//        environmentNode.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0, 0, 0)
        //environmentNode.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: AVAudio3DVector(x: 0, y: 0, z: -1), up: AVAudio3DVector(x: 0, y: 1, z: 0))
        
        
        audioEngine.attach(playerNode)
        audioEngine.attach(environmentNode)
        audioEngine.attach(mixerNode)
        
        // Connect the environment node to the main mixer
        
        guard let audioFileURL = Bundle.main.url(forResource: "sample", withExtension: "mp3") else {
            print("Audio file not found")
            return
        }
        
        let playerItem = AVPlayerItem(url: audioFileURL)
        let player = AVPlayer(playerItem: playerItem)
        
        if let formats = player.currentItem?.allowedAudioSpatializationFormats {
            
            switch formats {
            case .monoAndStereo :
                print("Available format is monoAndStereo")
            case .multichannel :
                print("Available format is multichannel")
            case .monoStereoAndMultichannel :
                print("Available format is monoStereoAndMultichannel")
            default : break
            }
            
        }
        
        if let supportsSpatialAudio = player.currentItem?.isAudioSpatializationAllowed {
            print("Current audio file supports spatial audio : \(supportsSpatialAudio)")
        }
        
        guard let audioFile = self.audioFile else {return}
        
        audioEngine.connect(playerNode, to: mixerNode, format: audioFile.processingFormat)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: nil)
        
        try? audioEngine.start()
        
        // Set listener position and orientation
        
        
        // Load the audio file
        // dolby_atmospheric_sounds
        // sample
        
        
        // Position the sound in 3D space
        //playerNode.position = AVAudio3DPoint(x: 1, y: 0, z: -1)
        
        // Start the audio engine
        
        
        // Schedule the audio file for playback
//        playerNode.scheduleFile(audioFile, at: nil, completionHandler: {
//            print("Playback finished")
//        })
        
        seekBar.isContinuous = true
        
        playBackTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(playerPlaybackChanged), userInfo: nil, repeats: true)
        
    }
    
    @objc func playerPlaybackChanged() {
        
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return
        }
        
        var threeDVector = AVAudio3DVector(x: 0.0, y: 0.0, z: 0.0)
        
//        while positionSimulator <= 1000000.0 {
//            movingPoint.x = Float(positionSimulator + 0.25)
//            movingPoint.y = Float(positionSimulator + 0.25)
//            //movingPoint.z = Float(positionSimulator + -1.5)
//            
//            threeDVector.x = movingPoint.x + 0.15
//            threeDVector.y = movingPoint.y + 0.25
//            threeDVector.z = movingPoint.z + 0.35
//            
//            positionSimulator += 0.5
//            print("spatial_audio : moving_positions : \(movingPoint)")
//            playerNode.position = movingPoint
//        }
        
        //environmentNode.listenerPosition = movingPoint
        //environmentNode.listenerVectorOrientation = AVAudio3DVectorOrientation(forward: movingPoint, up: threeDVector)
        
        //playerNode.position = movingPoint
        
        
        let time = (Double(playerTime.sampleTime) / playerTime.sampleRate)
        
        if time <= 100.00 {
            seekBar.setValue(Float(time) / 100.0, animated: true)
            //print("spatial_audio : \(time)")
        }
        else {
            playBackTimer?.invalidate()
            print("spatial_audio : \(String(describing: playBackTimer?.isValid))")
        }
        
    }
    
    func scheduleAudioPlayback() {
        
        if let audioFile = audioFile {
            let format = audioFile.processingFormat
            print("Channels: \(format.channelCount), Sample Rate: \(format.sampleRate), Format: \(format)")
        }
        
        guard let audioFile = audioFile else { return }
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
        playerNode.play()
        playButton.setTitle("Pause", for: .normal)
        
    }
    
    func startMovingAudioSource() {
        
        var currentX: Float = -5.0
        let moveDuration: TimeInterval = 1.0 // Move over 10 seconds
        let maxX: Float = 5.0
        
        var currentAngle: Float = 0.0
        let maxAngle: Float = 360.0
        
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//            // Increment the angle for rotation
//            currentAngle += 2.5
//            
//            // Stop when the angle exceeds 360 degrees
//            if currentAngle >= maxAngle {
//                timer.invalidate()
//            }
//            
//            // Update the listener's orientation in 3D space
//            let orientation = AVAudioMake3DAngularOrientation(currentAngle, 0, 0)
//            self.environmentNode.listenerAngularOrientation = orientation
//            
//            print("Listener orientation: \(currentAngle)")  // For debugging
//        }
        
        var currentPan: Float = -1.5  // Start at the leftmost position
        var panDirection: Float = 0.05  // The rate at which the pan changes
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            // Increase pan value
            currentPan += panDirection
            
            // Reverse the direction when the pan hits the bounds (-1.0 or 1.0)
            if currentPan >= 1.5 {
                panDirection = -0.05  // Start moving back to the left
            } else if currentPan <= -1.0 {
                panDirection = 0.05  // Start moving back to the right
            }
            
            // Update the pan position (left: -1.0, right: 1.0)
            self.mixerNode.pan = currentPan
            print("Pan position: \(currentPan)")  // Debugging
        }
        
        
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//            // Move the source position from left (-5.0) to right (5.0) over time
//            currentX += 0.1
//            
//            if currentX > maxX {
//                timer.invalidate()
//            }
//            
//            let position = AVAudio3DPoint(x: currentX, y: 0, z: 0)
//            self.environmentNode.listenerPosition = position
//            //self.playerNode.position = position
//            
//            print("Listener source position: \(position)")
//        }
    }
    
    @IBAction func playButtonAction(_ sender: UIButton) {
        
        if playerNode.isPlaying {
            playerNode.pause()
            playButton.setTitle("Play", for: .normal)
        }
        else {
            playerNode.play()
            playButton.setTitle("Pause", for: .normal)
            playBackTimer?.fire()
        }
        
    }
    
    @IBAction func sliderAction(_ sender: UISlider) {
        
//        playerNode.pause()
//        
//        sender.isContinuous = true
//        
//        let value = sender.value
//        
//        playerNode.play(at: AVAudioTime(hostTime: UInt64(value * 100)))
//        
//        print("spatial_audio_b : \(value * 100)")
//        
//        playerNode.play()
    }
    
}

//class AudioNode : SKAudioNode {
//    
//    func didMove(to view: SKView) {
//        let music = SKAudioNode(fileNamed: "sample.mp3")
//        addChild(music)
//
//        music.isPositional = true
//        music.position = CGPoint(x: -1024, y: 0)
//
//        let moveForward = SKAction.moveTo(x: 1024, duration: 2)
//        let moveBack = SKAction.moveTo(x: -1024, duration: 2)
//        let sequence = SKAction.sequence([moveForward, moveBack])
//        let repeatForever = SKAction.repeatForever(sequence)
//
//        music.run(repeatForever)
//    }
//}
