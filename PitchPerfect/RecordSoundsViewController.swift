//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by OLIVER HAGER on 3/8/15.
//  Copyright (c) 2015 OLIVER HAGER. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation

/// View controller for the audio recording page
/// The view controller implements the AVAudioRecorderDelegate interface in order to intercept
/// the completion of the audio recording
class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {
    /// record button
    @IBOutlet weak var recordButton: UIButton!
    /// stop button
    @IBOutlet weak var stopButton: UIButton!
    /// recording label
    @IBOutlet weak var recordingLabel: UILabel!
    /// pause or resume recording button
    @IBOutlet weak var pauseResumeRecordingButton: UIButton!
    
    /// audio recorder
    var audioRecorder: AVAudioRecorder!
    
    /// recorded audio
    var recordedAudio: RecordedAudio!
    
    /// tap to record label text
    let TAP_TO_RECORD = "Tap to Record"
    
    /// recording in progress label text
    let RECORDING_IN_PROGRESS = "Recording in progress"
    
    /// date format for timestamp in recording file name
    let DATE_FORMAT = "ddMMyyyy-HHmmss"
    
    /// recording file extension
    let WAV_EXTENSION = ".wav"
    
    /// segue identifier
    let SEG_IDENTIFIER = "stopRecording"
    
    /// recording error message
    let RECORDING_ERROR = "Recording was not successful"
    
    /// view did load
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// Initially hide stop button and set recording label text
    ///
    /// :param: Bool animated
    override func viewWillAppear(animated: Bool) {
        stopButton.hidden = true
        recordingLabel.text = TAP_TO_RECORD
        pauseResumeRecordingButton.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// change recording label text
    ///
    /// :param: UIButton pressed stop button
    @IBAction func stopAudioRecording(sender: UIButton) {
        recordingLabel.text = TAP_TO_RECORD
    }
    
    /// record audio
    ///
    /// :param: UIButton pressed record button
    @IBAction func recordAudio(sender: UIButton) {
        //set recording label
        recordingLabel.text = RECORDING_IN_PROGRESS
        //show stop recording button
        stopButton.hidden=false
        recordButton.enabled=false
        pauseResumeRecordingButton.hidden = false
        pauseResumeRecordingButton.setImage(UIImage(named: "pause"), forState:UIControlState.Normal)

        //construct path to audio recording file
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        //include timestamp in file name in order to make it unique
        var currentDateTime = NSDate()
        var formatter = NSDateFormatter()
        formatter.dateFormat = DATE_FORMAT
        var recordingName = formatter.stringFromDate(currentDateTime)+WAV_EXTENSION
        var pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        println(filePath)
        //open audio session
        var session = AVAudioSession.sharedInstance()
        session.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
        //create audio recorder and assign recording file
        audioRecorder = AVAudioRecorder(URL: filePath, settings: nil, error: nil)
        audioRecorder.delegate = self
        //enabled audio metering
        audioRecorder.meteringEnabled = true
        audioRecorder.prepareToRecord()
        //record
        audioRecorder.record()
    }
    
    /// stop recording
    ///
    /// :param: UIButton pressed stop recording button
    @IBAction func stopRecording(sender: UIButton) {
        //hide stop button
        stopButton.hidden=true
        recordButton.enabled=true
        pauseResumeRecordingButton.hidden = true
        //stop audio recording
        audioRecorder.stop()
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setActive(false, error: nil)
    }
    
    /// pause / resume recording
    ///
    /// :param: UIButton press pause /resume recording button
    @IBAction func pauseResumeRecording(sender: UIButton) {
        if(audioRecorder.recording) {
            audioRecorder.pause()
            pauseResumeRecordingButton.setImage(UIImage(named: "resume"), forState:UIControlState.Normal)
        }
        else {
            audioRecorder.record()
            pauseResumeRecordingButton.setImage(UIImage(named: "pause"),  forState:UIControlState.Normal)
        }
    }
    
    /// handle finishing of recording
    ///
    /// :param: AVAudioRecorder audio recorder
    /// :param: Bool true if successfully finished, false otherwise
    /// :returns: Nothing useful
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        //audio recording successfully finished?
        if(flag) {
            //store title and file path
            recordedAudio=RecordedAudio(title: audioRecorder.url.lastPathComponent, recordingFilePath: audioRecorder.url)
            //navigate to next page passing the recording information 
            //so the recorded audio file can be played
            self.performSegueWithIdentifier(SEG_IDENTIFIER, sender: recordedAudio)
        }
        else {
            //error
            println(RECORDING_ERROR)
            recordButton.enabled = true
            stopButton.hidden = true
        }
    }
    
    /// prepare navigation to next page by passing information about
    /// the recorded file to the next view controller
    /// :param: UIStoryboardSegue segue
    /// :param: AnyObject? recorded audio information
    /// :returns: Nothing useful
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == SEG_IDENTIFIER) {
            let playSoundsVC:PlaySoundsViewController = segue.destinationViewController as PlaySoundsViewController
            let data = sender as RecordedAudio
            playSoundsVC.receivedAudio=data
        }
    }
}

