//
//  ViewController.swift
//  CardScrollView
//
//  Created by Hummer on 16/7/1.
//  Copyright © 2016年 Hummer. All rights reserved.
//

import UIKit

class ViewController: UIViewController, HUCardScrollViewDelegate, HUCardScrollViewDataSource {

//    @IBOutlet weak var cardScrollView: HUCardScrollView!
    var cardScrollView: HUCardScrollView = {
        let cardScrollView = HUCardScrollView(frame: CGRect(x: 0, y: 0, width: UIScreen.width, height: UIScreen.height))
        cardScrollView.backgroundColor = UIColor.whiteColor()
        return cardScrollView
    }()
    
    var button:UIButton = {
        let btn = UIButton(type: .Custom)
        btn.backgroundColor = UIColor.blackColor()
        btn.layer.cornerRadius = 5.0
        btn.layer.masksToBounds = true
        btn.setTitle("Reload", forState: .Normal)
        btn.setTitleColor(UIColor.yellowColor(), forState: .Normal)
        return btn
    }()
    
    var cardsInfo = [String]()
    var numberOfCard = 100
    private let _cardWidth: CGFloat = 180
    private let _cardHeight: CGFloat = 260 //UIScreen.mainScreen().bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(cardScrollView)
        cardScrollView.dataSource = self
        cardScrollView.delegate = self
        cardScrollView.cardMargin = 60
        
        let line = UIView()
        line.backgroundColor = UIColor.lightGrayColor()
        self.view.addSubview(line)
        
        line.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: line, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0);
        let bottom = NSLayoutConstraint(item: line, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0)
        let centerX = NSLayoutConstraint(item: line, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let width = NSLayoutConstraint(item: line, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 1)
        self.view.addConstraints([top, bottom, centerX, width])
        
        button.addTarget(self, action: #selector(ViewController.reload), forControlEvents: .TouchUpInside)
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        let btnWidth = NSLayoutConstraint(item: button, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 100)
        let btnHeight = NSLayoutConstraint(item: button, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40)
        let btnCenterX = NSLayoutConstraint(item: button, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1.0, constant: 0)
        let btnBottom = NSLayoutConstraint(item: button, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: -20)
        self.view.addConstraints([btnWidth, btnHeight, btnCenterX, btnBottom])
        
        for i in 0 ..< numberOfCard {
            cardsInfo.append("\(i)")
        }
        
        cardScrollView.reloadData()
    }
    
    func reload() {
        cardScrollView.scrollCardToIndex(0, animated: true)
        cardScrollView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfCardsInCardScrollView(cardScrollView: HUCardScrollView) -> Int {
        return cardsInfo.count
    }
    
    func widthForscrollCardAtIndex(index: Int) -> CGFloat {
        return _cardWidth
    }
    
    func heightForscrollCardAtIndex(index: Int) -> CGFloat {
        return _cardHeight
    }
    
    func randomColor() -> UIColor {
        return UIColor(red: (CGFloat(arc4random() % 255) / 255.0), green: (CGFloat(arc4random() % 255) / 255.0), blue: (CGFloat(arc4random() % 255) / 255.0), alpha: 1.0)
    }
    
    func cardScrollView(cardScrollView: HUCardScrollView, cardAtIndex index: Int) -> HUScrollViewCard {
        var card = cardScrollView.dequeueReusableCardWithIdentifier("card")
        if card == nil {
            card = HUScrollViewCard(frame: CGRect(x: 0, y: 0, width: _cardWidth, height: _cardHeight))
            card!.identifier = "card"
            let label = UILabel(frame: card!.frame)
            label.text = cardsInfo[index]
            label.textAlignment = .Center
            label.textColor = UIColor.whiteColor()
            label.font = UIFont.boldSystemFontOfSize(15)
            card!.addSubview(label)
        }
        card!.backgroundColor = randomColor()
        card!.layer.cornerRadius = 5.0
        card!.layer.masksToBounds = true
        (card?.subviews.first as! UILabel).text = cardsInfo[index]
        return card!
    }
    
    func cardScrollView(cardScrollView: HUCardScrollView, updateVisiblsCard card: HUScrollViewCard, withProgress progress: CGFloat) {
        card.layer.transform = CATransform3DMakeScale(1 + 0.16 * progress, 1 + 0.16 * progress, 1.0)
    }

}

extension UIScreen {
    class var width: CGFloat {
        return UIScreen.mainScreen().bounds.width
    }
    class var height: CGFloat {
        return UIScreen.mainScreen().bounds.height
    }
}