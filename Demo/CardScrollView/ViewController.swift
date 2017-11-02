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
        cardScrollView.backgroundColor = UIColor.white
        return cardScrollView
    }()
    
    var button:UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.black
        btn.layer.cornerRadius = 5.0
        btn.layer.masksToBounds = true
        btn.setTitle("Reload", for: .normal)
        btn.setTitleColor(UIColor.yellow, for: .normal)
        return btn
    }()
    
    var cardsInfo = [String]()
    var numberOfCard = 6
    private let _cardWidth: CGFloat = 245
    private let _cardHeight: CGFloat = 130 //UIScreen.mainScreen().bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(cardScrollView)
        cardScrollView.dataSource = self
        cardScrollView.delegate = self
        cardScrollView.cardMargin = 40
        
        let line = UIView()
        line.backgroundColor = UIColor.lightGray
        self.view.addSubview(line)
        
        line.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: line, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0);
        let bottom = NSLayoutConstraint(item: line, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
        let centerX = NSLayoutConstraint(item: line, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let width = NSLayoutConstraint(item: line, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1)
        self.view.addConstraints([top, bottom, centerX, width])
        
        button.addTarget(self, action: #selector(ViewController.reload), for: .touchUpInside)
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        let btnWidth = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)
        let btnHeight = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40)
        let btnCenterX = NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let btnBottom = NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -20)
        self.view.addConstraints([btnWidth, btnHeight, btnCenterX, btnBottom])
        
        for i in 0 ..< numberOfCard {
            cardsInfo.append("\(i)")
        }
        
        cardScrollView.reloadData()
    }
    
    @objc func reload() {
        cardScrollView.scrollCardToIndex(index: 0, animated: true)
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
        var card = cardScrollView.dequeueReusableCardWithIdentifier(identifier: "card")
        if card == nil {
            card = HUScrollViewCard(frame: CGRect(x: 0, y: 0, width: _cardWidth, height: _cardHeight))
            card!.backgroundColor = randomColor()
            card!.identifier = "card"
            let label = UILabel(frame: card!.frame)
            label.text = cardsInfo[index]
            label.textAlignment = .center
            label.textColor = UIColor.white
            label.font = UIFont.boldSystemFont(ofSize: 15)
            card!.addSubview(label)
        }
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
        return UIScreen.main.bounds.width
    }
    class var height: CGFloat {
        return UIScreen.main.bounds.height
    }
}
