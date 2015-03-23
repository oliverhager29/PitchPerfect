
//
//  PlaySoundsViewController.swift
//  PitchPerfect
//
//  Created by OLIVER HAGER on 3/13/15.
//  Copyright (c) 2015 OLIVER HAGER. All rights reserved.
//

import UIKit
import AVFoundation

//View controller for the play audio page
class PlaySoundsViewController: UIViewController, AVAudioPlayerDelegate {
    //stop audio button
    @IBOutlet weak var stopAudioButton: UIButton!
    
    //audio player used by slow and fast audio re-play
    var avPlayer: AVAudioPlayer!
    //audio player node used by chipmunk and darthvader effects
    var avPlayerNode: AVAudioPlayerNode!
    //audio engine used by chipmunk and darthvader effects
    var avEngine: AVAudioEngine!
    
    //information about the recorded audio file that is replayed 
    //with the different effects
    var receivedAudio: RecordedAudio!
    
    //constants
    let FILE_NOT_FOUND_ERROR = "File not found"
    let AUDIO_PLAY_ERROR = "Audio play failed"
    
    /// Initialize audio re-play
    override func viewDidLoad() {
        super.viewDidLoad()
        initAudio()
    }
    
    /// did receive memory warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// play slow audio
    ///
    /// :param: UIButton pressed play slow audio button
    @IBAction func playSlowAudio(sender: UIButton) {
        playAudioWithVariableRate(0.5)
    }
    
    /// play fast audio
    ///
    /// :param: UIButton pressed play fast audio button
    @IBAction func playFastAudio(sender: UIButton) {
        playAudioWithVariableRate(2.0)
    }

    /// play chipmunk audio
    ///
    /// :param: UIButton pressed play chipmunk audio button
    @IBAction func playChipmunkAudio(sender: UIButton) {
        playAudioWithVariablePitch(1000.0)
    }
    
    /// play darthvader audio
    ///
    /// :param: UIButton pressed play darthvader audio button
    @IBAction func playDarthvaderAudio(sender: UIButton) {
        playAudioWithVariablePitch(-1000.0)
    }
    
    /// play reverb audio
    /// :param: UIButton pressed play reverb audio button
    @IBAction func playReverbAudio(sender: UIButton) {
        playAudioWithReverb(AVAudioUnitReverbPreset.LargeHall, wetDryMix: 100.0)
    }
    
    /// play echo audio
    /// :param: UIButton pressed play echo audio button
    @IBAction func playEchoAudio(sender: UIButton) {
        playAudioWithDelay(NSTimeInterval(2.0), feedback: 50, lowPassCutoff: 18000, wetDryMix: 100)
    }
    
    
    /// initialize audio re-play
    func initAudio() {
        var error: NSError?
        //check if path tp recorded audio file really exists
        if(receivedAudio.recordingFilePath.path != nil){
            //open audio session
            var session = AVAudioSession.sharedInstance()
            session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.AllowBluetooth, error: &error)
            //creat audio player and set path to aduio file
            self.avPlayer = AVAudioPlayer(contentsOfURL: receivedAudio.recordingFilePath, error: &error)
            self.avPlayer.delegate = self
            //set audio engine
            self.avEngine = AVAudioEngine()
            //creation of audio player failed (e.g. wrong path to file)
            if self.avPlayer == nil {
                if let e = error {
                    println(e.localizedDescription)
                }
            }
            else {
                //initialize audio player
                self.avPlayer.enableRate = true
                self.avPlayer.meteringEnabled = true
            }
            
        }
        else {
            //no audio file
            println(FILE_NOT_FOUND_ERROR)
        }
        self.avPlayerNode = nil
    }
    
    /// stop audio
    func stopAudio() {
        if(self.avPlayer != nil) {
            self.avPlayer.stop()
        }
        if(self.avPlayerNode != nil) {
            self.avPlayerNode.stop()
            self.avPlayerNode.reset()
        }
    }

    /// play audio with variable rate (used slow and fast audio re-play)
    ///
    /// :param: Float rate from 0 to 2.0 (slow to fast)
    func playAudioWithVariableRate(rate: Float) {
        if(self.avPlayer != nil) {
            //stop audio (other audio may not be finished)
            stopAudio()
            // show stop audio button
            stopAudioButton.hidden = false
            //set audio player rate
            self.avPlayer.rate = rate
            //start at beginning ot audio file
            self.avPlayer.currentTime = 0.0
            //play audio
            self.avPlayer.play()
        }
        
    }
    
    /// play audio with variable pitch (used in chipmunk and darthvader re-play)
    ///
    /// :param: Float pitch adding or subtracting cents
    func playAudioWithVariablePitch(pitch: Float) {
        //create pitch effect node
        var auTimePitch = AVAudioUnitTimePitch()
        //set pitch
        auTimePitch.pitch = pitch
        //we do not change the audio play rate
        auTimePitch.rate = 1.0
        playAudioWithEffect(auTimePitch)
    }
    
    /// play audio with reverb
    ///
    /// :param: AVAudioUnitReverbPreset preset for reverb
    /// :param: Float wet dry mix (0 (dry) to 100 (wet) percent)
    func playAudioWithReverb(preset: AVAudioUnitReverbPreset, wetDryMix: Float) {
        //create reverb effect node
        var auReverb = AVAudioUnitReverb()
        //set reverb preset
        auReverb.loadFactoryPreset(AVAudioUnitReverbPreset.Cathedral)
        //set wet dry mix
        auReverb.wetDryMix=wetDryMix
        playAudioWithEffect(auReverb)
    }

    /// play audio with delay
    ///
    /// :param: NSTimeInterval delay time (0 to 2 seconds)
    /// :param: Float feedback (-100 to 100 percent)
    /// :param: Float low pass cutoff (10 Hz to half of sample frequency)
    /// :param: Float wet dry mix (0 (dry) to 100 (wet) percent)
    func playAudioWithDelay(delayTime: NSTimeInterval, feedback: Float, lowPassCutoff: Float, wetDryMix: Float) {
        //create delay effect node
        var auDelay = AVAudioUnitDelay()
        auDelay.delayTime = delayTime
        auDelay.feedback = feedback
        auDelay.lowPassCutoff = lowPassCutoff
        auDelay.wetDryMix = wetDryMix
        playAudioWithEffect(auDelay);
    }
    
    /// play audio with variable pitch (used in chipmunk and darthvader re-play)
    ///
    /// :param: AVAudioUnit effect
    func playAudioWithEffect(effect: AVAudioUnit) {
        if(self.avPlayer != nil) {
            //stop audio (other audio may not be finished)
            stopAudio()
            // show stop audio button
            stopAudioButton.hidden = false
            //create audio player node feeding the record audio into
            //the audio network
            self.avPlayerNode=AVAudioPlayerNode()
            //get mixer
            var mixer = avEngine.mainMixerNode
            //set maximum volume
            mixer.volume = 1.0
            //attached audio player node to audio engine
            self.avEngine.attachNode(avPlayerNode)
            //attach effect node to audio engine
            self.avEngine.attachNode(effect)
            // connect audio player node to audio effect node
            self.avEngine.connect(avPlayerNode, to: effect, format: mixer.outputFormatForBus(0))
            //connect audio effect node to mixer
            self.avEngine.connect(effect, to: mixer, format: mixer.outputFormatForBus(0))
            var error: NSError? = nil
            //set recording file in audio player node
            let file = AVAudioFile(forReading: receivedAudio.recordingFilePath, error: &error)
            //asynchronously set file for audio encoding
            self.avPlayerNode.scheduleFile(file, atTime: nil, completionHandler: audioCompleted)
            //start audio engine
            self.avEngine.startAndReturnError(&error)
            //error
            if nil != error {
                println(error)
                abort();
            }
            //play audio recording
            self.avPlayerNode.play()
        }
    }

    /// Stop audio
    ///
    /// :param: UIButton pressed stop audio button
    @IBAction func stop(sender: UIButton) {
        self.stopAudioButton.hidden = true
        if(self.avPlayer != nil) {
            self.avPlayer.stop()
        }
        if(self.avEngine != nil) {
            self.avEngine.stop()
            self.avEngine.reset()
        }
        if(self.avPlayerNode != nil) {
            self.avPlayerNode.stop()
            self.avPlayerNode.reset()
        }
    }
    
    /// Hide stop button (called as completion handler by audio player node and by audioPlayerDidFinishPlaying handler)
    func audioCompleted() {
        stopAudioButton.hidden = true
    }
    
    /// Hide stop audio button when audio ends playing
    /// :param: AVAudioPlaer! audio player
    /// :param: Bool true if audio has been played successfully, false otheriwse
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        if(flag) {
            audioCompleted()
        }
        else {
            println(AUDIO_PLAY_ERROR)
            audioCompleted()
        }
    }
}
