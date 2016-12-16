//
//  LanguageProcessing.swift
//  OkRuntime
//
//  Created by Gagandeep Singh on 12/15/16.
//  Copyright © 2016 Gagandeep Singh. All rights reserved.
//

import Foundation

class LanguageProcessing: NSObject {
    
    var tagger:NSLinguisticTagger!
    var taggerOptions:NSLinguisticTagger.Options
    
    override init() {
        
        self.taggerOptions = [.omitWhitespace, .omitPunctuation, .joinNames]
        let schemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        self.tagger = NSLinguisticTagger(tagSchemes: schemes, options: Int(self.taggerOptions.rawValue))
        
        super.init()
    }
    
    func partsOfSpeech(text: String, completion: (([String: String]?) -> Void)?) {
        
        tagger.string = text
        tagger.enumerateTags(in: NSMakeRange(0, (text as NSString).length), scheme: NSLinguisticTagSchemeNameTypeOrLexicalClass, options: self.taggerOptions) { (tag, tokenRange, _, _) in
            let token = (text as NSString).substring(with: tokenRange)
            print("\(token): \(tag)")
        }
    }
}
