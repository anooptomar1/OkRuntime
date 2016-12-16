//
//  AnimatedBarsView.swift
//  OkRuntime
//
//  Created by Gagandeep Singh on 12/15/16.
//  Copyright © 2016 Gagandeep Singh. All rights reserved.
//

import UIKit

protocol AnimatedBarsViewDelegate:class {
    func animatedBarsViewDidTap(animatedBarsView:AnimatedBarsView)
}

class AnimatedBarsView: UIView {

    @IBOutlet var bar1TopConstraint:NSLayoutConstraint!
    @IBOutlet var bar2TopConstraint:NSLayoutConstraint!
    @IBOutlet var bar3TopConstraint:NSLayoutConstraint!
    
    private var timer:Timer!
    private var nibView:UIView!
    
    weak var delegate:AnimatedBarsViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    private func commonInit() {
        
        self.backgroundColor = UIColor.clear
        
        self.nibView = self.loadViewFromNib()
        
        self.nibView.frame = self.bounds
        nibView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.addSubview(self.nibView)
        
        self.animateBars()
        
        //add tap recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancelAction))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "AnimatedBarsView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func animateBars() {
        //animate bars
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true, block: { (timer:Timer) in
            
            let random1 = CGFloat(arc4random() % 10) + 2
            let random2 = CGFloat(arc4random() % 10) + 2
            let random3 = CGFloat(arc4random() % 10) + 2
            
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                self?.bar1TopConstraint.constant = CGFloat(random1)
                self?.bar2TopConstraint.constant = CGFloat(random2)
                self?.bar3TopConstraint.constant = CGFloat(random3)
                }, completion: { (finished) in
                    
            })
        })
    }
    
    //MARK: - Actions
    
    func cancelAction() {
        //notify delegate
        self.delegate?.animatedBarsViewDidTap(animatedBarsView: self)
    }
}
