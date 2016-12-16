//
//  SpeechRecognizer.swift
//  Siri
//
//  Created by Nimesh Jarecha on 12/14/16.
//  Copyright © 2016 Sahand Edrisian. All rights reserved.
//

import Foundation
import Speech

private enum SpeechRecognizerAuthorizationStatus : Int {
    case notDetermined
    case denied
    case restricted
    case authorized
}

public class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var authorizationStatus: SpeechRecognizerAuthorizationStatus?
    private(set) public var started = false
    
    public override init() {
        super.init()
        //
        // set delegate
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            //
            // set authorization status
            switch authStatus {
            case .authorized:
                self.authorizationStatus = .authorized
            case .denied:
                self.authorizationStatus = .denied
                print("User denied access to speech recognition")
            case .restricted:
                self.authorizationStatus = .restricted
                print("Speech recognition restricted on this device")
            case .notDetermined:
                self.authorizationStatus = .notDetermined
                print("Speech recognition is not yet authorized")
            }
        }
    }

    public func start(completion: ((String?, Bool, Error?) -> Swift.Void)? = nil) {
        
        if self.authorizationStatus == .authorized || self.authorizationStatus == .restricted {
            //
            // set started
            self.started = true
            
            if recognitionTask != nil {
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSessionCategoryRecord)
                try audioSession.setMode(AVAudioSessionModeMeasurement)
                try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let inputNode = audioEngine.inputNode else {
                fatalError("Audio engine has no input node")
            }
            
            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
                
                var isFinal = false
                var text: String?
                
                if result != nil {
                    text = result?.bestTranscription.formattedString
                    isFinal = (result?.isFinal)!
                }
                
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.started = false
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
                
                completion?(text, isFinal, error)
            })
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            
            do {
                try audioEngine.start()
            } catch {
                print("audioEngine couldn't start because of an error.")
            }
        }
        else {
            let userInfo: [NSObject : AnyObject] =
                [
                    NSLocalizedDescriptionKey as NSObject :  NSLocalizedString("Unauthorized", value: "Speech recognition is not yet authorized", comment: "") as AnyObject,
                    NSLocalizedFailureReasonErrorKey as NSObject : NSLocalizedString("Unauthorized", value: "Speech recognition is not yet authorized", comment: "") as AnyObject
            ]
            let error = NSError(domain: "SpeechRecognizerErrorDomain", code: 1001, userInfo: userInfo)
            completion?(nil, false, error)
        }
    }
    
    public func stop(completion: ((Bool) -> Swift.Void)? = nil) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.started = false
            self.recognitionRequest = nil
            self.recognitionTask = nil
            completion?(true)
        }
        completion?(false)
    }
    
    public func cancel() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionTask?.cancel()
        }
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.started = true
        } else {
            self.started = false
        }
    }
}
