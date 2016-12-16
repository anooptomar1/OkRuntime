//
//  ViewController.swift
//  OkRuntime
//
//  Created by Gagandeep Singh on 12/14/16.
//  Copyright © 2016 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS
import AVFoundation

enum BarState:String {
    case Collapsed = "Collapsed"
    case Idle = "Idle"
    case Listening = "Listening"
    case Loading = "Loading"
}

enum audioType:String {
    case Start = "Start"
    case Stop = "Stop"
    case Error = "Error"
}

class ViewController: UIViewController, AnimatedBarsViewDelegate, AVSpeechSynthesizerDelegate, MapActionsDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var visualEffectView:UIVisualEffectView!
    @IBOutlet var visualEffectView2:UIVisualEffectView!
    @IBOutlet var speechButton:UIButton!
    @IBOutlet var progressView:UIView!
    @IBOutlet var barWidthConstraint:NSLayoutConstraint!
    @IBOutlet var barLeadingConstraint:NSLayoutConstraint!
    @IBOutlet var bannerView:UIView!
    @IBOutlet var barTextField:UITextField!
    @IBOutlet var animatedBarsView:AnimatedBarsView!
    
    private var speechRecognizer: SpeechRecognizer?
    private var housesFeatureLayer:AGSFeatureLayer?
    private var schoolsFeatureLayer:AGSFeatureLayer?
    
    private var voiceCommandParser = VoiceCommandParser()
    private var mapActions: MapActions!
    private var action = actions.unknown
    private var performingAction = false
    
    private var barState:BarState = .Collapsed {
        didSet {
            self.updateBarUI()
        }
    }
    
    var siriStartSound:SystemSoundID = 0
    var siriStopSound:SystemSoundID = 0
    var siriErrorSound:SystemSoundID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let map = AGSMap(url: URL(string: "https://www.arcgis.com/home/item.html?id=37f5487e55cb43e0956786f83dc202d4")!)
        self.mapView.map = map
        
        self.mapView?.map?.load(completion: { [weak self] (error) in
            self?.setLayers()
            self?.mapActions = MapActions(mapView: self?.mapView, housesFeatureLayer: self?.housesFeatureLayer, schoolsFeatureLayer: self?.schoolsFeatureLayer)
            self?.mapActions.delegate = self
        })
        
        //corner radius for visual effect view
        self.visualEffectView.layer.cornerRadius = 20
        
        //initial state for button
        self.barState = .Collapsed
        //self.toggleTextField(on: false)
        
        //init speech recognizer
        self.speechRecognizer = SpeechRecognizer()
        
        //delegate for animatedBarsView
        self.animatedBarsView.delegate = self
        
        //tap gesture for progress view to cancel
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(progressViewTapAction))
        self.progressView.addGestureRecognizer(tapGestureRecognizer)
        
        //create sounds
        self.createSounds()
        
        /*
        let lp = LanguageProcessing()
        lp.partsOfSpeech(text: "Where am I?") { (_: [String : String]?) in
            
        }
        lp.partsOfSpeech(text: "Zoom to a 2 mile radius", completion: nil)
        lp.partsOfSpeech(text: "Show me all homes in this area", completion: nil)
        lp.partsOfSpeech(text: "Select homes that are for sale within 2 miles of McKinley School", completion: nil)
        lp.partsOfSpeech(text: "Show me only the ones less than 900000 dollars", completion: nil)
        lp.partsOfSpeech(text: "Show me details of the house on street", completion: nil)
        lp.partsOfSpeech(text: "Take me to that house", completion: nil)
         */
    }
    
    private func setLayers() {
        for layer in (self.mapView?.map?.operationalLayers)! {
            if (layer as! AGSLayer).name == "Houses" {
                self.housesFeatureLayer = layer as? AGSFeatureLayer
                self.housesFeatureLayer?.isVisible = false
            }
            else if (layer as! AGSLayer).name == "Schools" {
                self.schoolsFeatureLayer = layer as? AGSFeatureLayer
                self.schoolsFeatureLayer?.isVisible = false
            }
        }
    }
    
    private func updateBarUI() {
        switch self.barState {
        case .Collapsed:
            self.toggleTextField(on: false)
            self.toggleSpeechButton(on: true)
            self.toggleProgressView(on: false)
            self.toggleBannerView(on: true)
            self.toggleAnimatedBarsView(on: false)
        case .Idle:
            self.toggleTextField(on: true)
            self.toggleSpeechButton(on: true)
            self.toggleProgressView(on: false)
            self.toggleBannerView(on: false)
            self.toggleAnimatedBarsView(on: false)
            self.barTextField.text = ""
        case .Listening:
            self.toggleTextField(on: true)
            self.toggleSpeechButton(on: false)
            self.toggleProgressView(on: false)
            self.toggleBannerView(on: false)
            self.toggleAnimatedBarsView(on: true)
            self.barTextField.text = ""
        default:
            self.toggleTextField(on: true)
            self.toggleSpeechButton(on: false)
            self.toggleProgressView(on: true)
            self.toggleBannerView(on: false)
            self.toggleAnimatedBarsView(on: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    
    @IBAction func speechButtonAction() {
        //change bar state
        if self.barState == .Idle || self.barState == .Collapsed {
            OperationQueue.main.addOperation {
                self.barState = .Listening
            }
        }
        else {
            return
        }
        
        if (self.speechRecognizer?.started)! {
            self.speechRecognizer?.stop()
        }
        else {
            self.playSound(audioType: .Start, completion: {
                self.speechRecognizer?.start(completion: { (text, isFinal, error) in
                    if error != nil {
                        print(error)
                    }
                    else {
                        self.barTextField.text = text
                    }
                })
            })
        }
    }

    //MARK: - Hide/Show progress view
    
    private func toggleProgressView(on:Bool) {
        //self.progressView.alpha = on ? 1 : 0
        self.progressView.isHidden = !on
    }
    
    private func toggleSpeechButton(on:Bool) {
        self.speechButton.isHidden = !on
    }
    
    private func toggleTextField(on:Bool) {
        self.barWidthConstraint.constant = on ? 500 : 46
        self.barLeadingConstraint.constant = on ? 8 : 0
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { [weak self] in
            self?.view.layoutIfNeeded()
        }) { (finished) in
                
        }
    }
    
    private func toggleBannerView(on:Bool) {
        if on {
            self.visualEffectView2.isHidden = false
        }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: { [weak self] in
            self?.visualEffectView2.effect = on ? UIBlurEffect(style: .light) : nil
            self?.bannerView.alpha = on ? 1 : 0
        }) { (finished) in
            if !on {
                self.visualEffectView2.isHidden = true
            }
        }
    }
    
    private func toggleAnimatedBarsView(on: Bool) {
        self.animatedBarsView.isHidden = !on
    }
    
    func progressViewTapAction() {
        //set bar state to idle
        OperationQueue.main.addOperation {
            self.barState = .Idle
        }
        
        //TODO: Cancel operations in progress
    }
    
    //MARK: - AnimatedBarsViewDelegate
    
    func animatedBarsViewDidTap(animatedBarsView: AnimatedBarsView) {
        
        //set the bar state to idle
        OperationQueue.main.addOperation {
            self.barState = .Loading
        }
        
        //Stop speech recognizer
        self.speechRecognizer?.stop(completion: { [weak self] (finished) in
          
            if let weakSelf = self {
                //play sound
                weakSelf.playSound(audioType: .Stop, completion: {
                    //parse text
                    if let text = self?.barTextField.text, !text.isEmpty {
                        weakSelf.action = weakSelf.voiceCommandParser.parseQuery(query: text)
                        print(weakSelf.action)
                        weakSelf.performingAction = false

                        switch weakSelf.action {
                        case .wrongQuery:
                            OperationQueue.main.addOperation {
                                weakSelf.barState = .Idle
                            }
                            weakSelf.textToSppech(text: NSAttributedString(string: "Sorry, I did not get that"))
                        case .whereAm:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Looking"))
                        case .housesForSale:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Finding houses for sale"))
                        case .houseBedroomFilter:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Filtering on bedroom"))
                        case .showSchools:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Finding schools"))
                        case .schoolFilter:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Finding school"))
                        case .houseSchoolFilter:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Finding houses in that area"))
                        case .houseStreetFilter:
                            weakSelf.textToSppech(text: NSAttributedString(string: "Ok, Looking up that house"))
                        default:
                            print("What we want to say here?")
                        }
                    }
                })
            }
        })
    }
    
    //MARK: - Audio files
    
    func createSounds() {
        if let filepath = Bundle.main.path(forResource: "Siri_Start_sound", ofType: "m4a") {
            let url = NSURL(fileURLWithPath: filepath)
            AudioServicesCreateSystemSoundID(url, &self.siriStartSound)
        }
        if let filepath = Bundle.main.path(forResource: "Siri_Stop_sound", ofType: "m4a") {
            let url = NSURL(fileURLWithPath: filepath)
            AudioServicesCreateSystemSoundID(url, &self.siriStopSound)
        }
        if let filepath = Bundle.main.path(forResource: "Siri_Error_sound", ofType: "m4a") {
            let url = NSURL(fileURLWithPath: filepath)
            AudioServicesCreateSystemSoundID(url, &self.siriErrorSound)
        }
    }
    
    //to play the shutter sound once the screenshot is taken
    func playSound(audioType:audioType, completion: (() -> Void)?) {
        
        var siriSound:SystemSoundID
        switch audioType {
        case .Start:
            siriSound = self.siriStartSound
        case .Stop:
            siriSound = self.siriStopSound
        default:
            siriSound = self.siriErrorSound
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
            try audioSession.setActive(true)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        AudioServicesPlaySystemSoundWithCompletion(siriSound) {
            completion?()
        }
    }
    
    deinit {
        AudioServicesDisposeSystemSoundID(self.siriStartSound)
        AudioServicesDisposeSystemSoundID(self.siriStopSound)
        AudioServicesDisposeSystemSoundID(self.siriErrorSound)
        AudioServicesRemoveSystemSoundCompletion(self.siriStartSound)
        AudioServicesRemoveSystemSoundCompletion(self.siriStopSound)
        AudioServicesRemoveSystemSoundCompletion(self.siriErrorSound)
    }
    
    //MARK: - Text to Speech
    
    func textToSppech(text: NSAttributedString) {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        let utterance =  AVSpeechUtterance(attributedString: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    //MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("didStart speechSynthesizer")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("didFinish speechSynthesizer")
        if self.action != .wrongQuery && !self.performingAction {
            self.performingAction = true
            self.mapActions?.performActionForEnum(action: self.action)
        }
    }
    
    //MARK: - MapActionsDelegate
    
    func finishedPerformingAction() {
        OperationQueue.main.addOperation {
            self.barState = .Idle
        }
    }
    
    func show(popupViewController: AGSPopupsViewController) {
        popupViewController.modalPresentationStyle = .popover
        popupViewController.popoverPresentationController?.sourceView = self.view
        self.present(popupViewController, animated: true) { [weak self] in
            OperationQueue.main.addOperation {
                self?.barState = .Idle
            }
        }
    }
}

