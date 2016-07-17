//
//  HUCardScrollView.swift
//  HUCardScrollView
//
//  Created by Hummer on 16/7/1.
//  Copyright © 2016年 Hummer. All rights reserved.
//

import UIKit

private let kDefaultCardWidth: CGFloat = 44.0
private let kDefaultCardHeight: CGFloat = 88.0

enum HUCardScrollDirection {
    case None
    case Left
    case Right
}

@objc protocol HUCardScrollViewDataSource: class {
    func numberOfCardsInCardScrollView(cardScrollView: HUCardScrollView) -> Int
    func cardScrollView(cardScrollView: HUCardScrollView, cardAtIndex index: Int) -> HUScrollViewCard
    optional func widthForscrollCardAtIndex(index: Int) -> CGFloat
    optional func heightForscrollCardAtIndex(index: Int) -> CGFloat
}

protocol HUCardScrollViewDelegate: class {
    func cardScrollView(cardScrollView: HUCardScrollView, updateVisiblsCard card: HUScrollViewCard, withProgress progress: CGFloat)
}

class HUCardScrollView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Public property
    
    weak var dataSource: HUCardScrollViewDataSource?
    weak var delegate: HUCardScrollViewDelegate?
    var canDelete: Bool = true
    var cardMargin: CGFloat = 10
    
    var visibleCards: [HUScrollViewCard] {
        return _visibleCardsPool.sort { $0.0 < $1.0 }.map { $0.1 }
    }
    var selectedIndex: Int {
        return _selectedIndex
    }
    var middleCardIndex: Int {
        return _middleCardIndex
    }
    var scrollDirection: HUCardScrollDirection {
        return _scrollDirection
    }
    
    // MARK: - Private property
    
    /// The number of cards.
    private var _numberOfCards: Int = 0
    /// The index of card which is selected.
    private var _selectedIndex: Int = -1
    /// The index of card which locates at middle of screen.
    private var _middleCardIndex: Int = 0
    /// The current scroll direction.
    private var _scrollDirection: HUCardScrollDirection = .None
    /// The indexes of visible cards
    private var _lastDisplayCardsRange: (startIndex: Int, endIndex: Int) = (0, 0)
    /// Which contains visible cards and it's index
    private var _visibleCardsPool = [Int : HUScrollViewCard]()
    /// Which is for reuse
    private var _reuseCardsPool = [String : [HUScrollViewCard]]()
    /// The widths of all cards
    private var _cardWidths = [CGFloat]()
    /// The heights of all cards
    private var _cardHeights = [CGFloat]()
    /// Which contains all cards' offsets which are calculated from original point of contentView
    private var _cardPositionOffsets = [CGFloat]()
    /// The width constraint added to contentView
    private var _cntViewWidthConstraint: NSLayoutConstraint?
    
    private var _lastMiddleIndexWhenOrientationChanged = 0
    
    private var _scrollView: UIScrollView! = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    private var _contentView: UIView! = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Initialize
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        setupUI()
        resetUI()
        initLayoutInfo()
        displayNeededCards()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
        resetUI()
        initLayoutInfo()
        displayNeededCards()
        
        scrollCardToIndex(_lastMiddleIndexWhenOrientationChanged, animated: true)
        _lastMiddleIndexWhenOrientationChanged = _middleCardIndex
    }
    
    // MARK: - Public method
    
    func reloadData() {
        resetUI()
        resetData()
        initializeNeededCards()
        initLayoutInfo()
        displayNeededCards()
    }
    
    func scrollCardToIndex(index: Int, animated: Bool) {
        let contentOffset = _cardPositionOffsets[index] - _cardWidths[index] - cardMargin - (frame.width - _cardWidths[0]) * 0.5
        _scrollView.setContentOffset(CGPoint(x: contentOffset, y: 0), animated: animated)
    }
    
    func dequeueReusableCardWithIdentifier(identifier: String) -> HUScrollViewCard? {
        if _reuseCardsPool[identifier]?.count == 0 {
            return nil
        } else {
            return _reuseCardsPool[identifier]?.removeFirst()
        }
    }
    
    // MARK: - Private method
    
    private func setupUI() {
        _scrollView.delegate = self
        _scrollView.addSubview(_contentView)
        self.addSubview(_scrollView)
        setupConstraints()
    }
    
    private func setupConstraints() {
        addConstraintsBetween(self, secondView: _scrollView)
        addConstraintsBetween(_scrollView, secondView: _contentView)
        
        _scrollView.constraints.forEach { (constraint) -> Void in
            if (constraint.firstItem as! UIView == self._scrollView &&
                constraint.secondItem as! UIView == self._contentView) {
                if constraint.firstAttribute == .Width {
                    self._cntViewWidthConstraint = constraint
                }
            }
        }
    }
    
    private func addConstraintsBetween(firstView: UIView, secondView: UIView) {
        secondView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: secondView, attribute: .Top, relatedBy: .Equal, toItem: firstView, attribute: .Top, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: secondView, attribute: .Bottom, relatedBy: .Equal, toItem: firstView, attribute: .Bottom, multiplier: 1.0, constant: 0)
        let width = NSLayoutConstraint(item: secondView, attribute: .Width, relatedBy: .Equal, toItem: firstView, attribute: .Width, multiplier: 1.0, constant: 0)
        let height = NSLayoutConstraint(item: secondView, attribute: .Height, relatedBy: .Equal, toItem: firstView, attribute: .Height, multiplier: 1.0, constant: 0)
        firstView.addConstraints([top, bottom, width, height])
    }
    
    /// Reset to the original state.
    @objc private func resetUI() {
        _numberOfCards = 0
        _cardWidths.removeAll()
        _cardHeights.removeAll()
        _cardPositionOffsets.removeAll()
        
        _visibleCardsPool.forEach{ $1.removeFromSuperview() }
    }
    
    private func resetData() {
        _selectedIndex = -1
        _scrollDirection = .None
        _visibleCardsPool.forEach{ $1.removeFromSuperview() }
        _visibleCardsPool.removeAll()
        _reuseCardsPool.removeAll()
    }
    
    private func initializeNeededCards() {
        let (start, end) = calWillDisplayCardsRange()
        guard end != 0 else {
            return
        }
        for index in start ... end {
            let card = dataSource?.cardScrollView(self, cardAtIndex: index)
            assert(card != nil, "Card can't be nil.")
            enqueueReusedCard(card!)
        }
    }
    
    private func displayNeededCards() {
        let (start, end) = calWillDisplayCardsRange()
        _visibleCardsPool.forEach { (_, card) -> Void in
            self.enqueueReusedCard(card)
        }
        _visibleCardsPool.removeAll()
        _contentView.subviews.forEach { $0.removeFromSuperview() }
        addWillDisplayCardsFrom(start, to: end)
        if let card = _visibleCardsPool[0] {
            self.delegate?.cardScrollView(self, updateVisiblsCard: card, withProgress: 1)
        }
    }
    
    ///  Record the width and height of card. Calcutlate the offset of every card, and contentSize of scroll view.
    private func initLayoutInfo() {
        _numberOfCards = dataSource?.numberOfCardsInCardScrollView(self) ?? 0
        guard _numberOfCards > 0 else {
            return
        }
        var offset = CGFloat(0.0)
        for index in 0..<_numberOfCards {
            let cardWidth = dataSource?.widthForscrollCardAtIndex?(index) ?? kDefaultCardWidth
            let cardHeight = dataSource?.heightForscrollCardAtIndex?(index) ?? kDefaultCardHeight
            _cardWidths.append(cardWidth)
            _cardHeights.append(cardHeight)
            offset += (cardWidth + cardMargin)
            _cardPositionOffsets.append(offset + (frame.width - _cardWidths[0]) * 0.5)
        }
        
        let firstPadding = (frame.width - _cardWidths[0]) * 0.5
        let lastPadding = (frame.width - (_cardWidths.last ?? 0)) * 0.5
        let contentSize = CGSize(width: firstPadding + offset - cardMargin + lastPadding, height: frame.height)
        _scrollView?.contentSize = contentSize
        _cntViewWidthConstraint?.constant = firstPadding + offset - cardMargin
    }
    
    ///  Add cards to screen.
    private func addWillDisplayCardsFrom(startIndex: Int, to endIndex: Int) {
        for index in startIndex ... endIndex {
            let card = dataSource?.cardScrollView(self, cardAtIndex: index)
            assert(card != nil, "Card can't be nil.")
            card!.frame = getRectForCardAtIndex(index)
            addCard(card!, atIndex: index)
//            setCardConstraints(card!, frame: cardFrame)
            card!.selected = (_selectedIndex == index) ? true : false
        }
    }
    
    private func setCardConstraints(card: UIView, frame: CGRect) {

        card.translatesAutoresizingMaskIntoConstraints = false
        let leading = NSLayoutConstraint(item: card, attribute: .Leading, relatedBy: .Equal, toItem: _contentView, attribute: .Leading, multiplier: 1.0, constant: frame.origin.x)
        let centerY = NSLayoutConstraint(item: card, attribute: .CenterY, relatedBy: .Equal, toItem: _contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let width = NSLayoutConstraint(item: card, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: frame.size.width)
        let height = NSLayoutConstraint(item: card, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: frame.size.height)
        
        _contentView.addConstraints([leading, centerY, width, height])
    }
    
    ///  Calculate the index of card which will display on screen.
    private func calWillDisplayCardsRange() -> (Int, Int) {
        guard _numberOfCards != 0 else {
            return (0, 0)
        }
        
        var startIndex = 0
        let startOffset = _scrollView.contentOffset.x - (frame.width - _cardWidths[0]) * 0.5
        var startDisplayOffset = CGFloat(0.0)
        for index in 0 ..< _numberOfCards {
            startDisplayOffset = _cardPositionOffsets[index] - (frame.width - _cardWidths[0]) * 0.5
            if startDisplayOffset > startOffset {
                startIndex = index
                break
            }
        }
        var endIndex = 0
        let endOffset = startOffset + frame.width
        var endDisplayOffset = startDisplayOffset
        for index in startIndex ..< _numberOfCards {
            endDisplayOffset = _cardPositionOffsets[index] - (frame.width - _cardWidths[0]) * 0.5 - cardMargin
            if endDisplayOffset > endOffset || index == _numberOfCards - 1 {
                endIndex = index
                break
            }
        }
        return (startIndex, endIndex)
    }
    
    ///  Calculate the frame of card.
    private func getRectForCardAtIndex(index: Int) -> CGRect {
        guard (index >= 0 || index < _numberOfCards) && _cardWidths.count > 0 else {
            return CGRectZero
        }
        let width = _cardWidths[index]
        let height = _cardHeights[index]
        let x = _cardPositionOffsets[index] - (width + cardMargin)
        let y = (frame.height - height) * 0.5
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func addCard(card: HUScrollViewCard, atIndex index: Int) {
        guard _visibleCardsPool[index] == nil else {
            enqueueReusedCard(card)
            return
        }
        card.index = index
        _visibleCardsPool[index] = card
        _contentView.addSubview(card)
    }
    
    ///  Add unvisible card to reuse pool.
    private func cleanUpUnusedCardsFrom(start: Int,to end: Int) {
        for (index, card) in _visibleCardsPool {
            if index < start || index > end {
                _visibleCardsPool.removeValueForKey(index)
                enqueueReusedCard(card)
            }
        }
    }
    
    ///  Update visible cards.
    private func checkupChangeOfdisplayRange() {
        let willDisplayCardsRange: (startIndex: Int, endIndex: Int) = calWillDisplayCardsRange()
        guard willDisplayCardsRange != _lastDisplayCardsRange else {
            return
        }
        
        let leftDelt = willDisplayCardsRange.startIndex - _lastDisplayCardsRange.startIndex
        let rightDelt = willDisplayCardsRange.endIndex - _lastDisplayCardsRange.endIndex
        _lastDisplayCardsRange = willDisplayCardsRange
        
        cleanUpUnusedCardsFrom(willDisplayCardsRange.startIndex, to: willDisplayCardsRange.endIndex)
        
        switch (leftDelt, rightDelt) {
        case (0, -_numberOfCards ... -1):
            _scrollDirection = .Right
            return
        case (1 ... _numberOfCards, 0):
            _scrollDirection = .Left
            return
        default:
            break
        }
        
        if leftDelt > 0 || rightDelt > 0 {
            _scrollDirection = .Left
            addWillDisplayCardsFrom(willDisplayCardsRange.endIndex, to: willDisplayCardsRange.endIndex)
        } else {
            _scrollDirection = .Right
            addWillDisplayCardsFrom(willDisplayCardsRange.startIndex, to: willDisplayCardsRange.startIndex)
        }
    }
    
    private func enqueueReusedCard(card: HUScrollViewCard) {
        assert(card.identifier != nil, "Card has no identifier for reusing.")
        if let pool = _reuseCardsPool[card.identifier!] {
            let cards = pool.filter {$0.index == card.index}
            if cards.count > 0 {
                return
            }
            _reuseCardsPool[card.identifier!]?.append(card)
        } else {
            var queue = [HUScrollViewCard]()
            queue.append(card)
            _reuseCardsPool[card.identifier!] = queue
        }
        // Clear up animation state of card
        card.layer.transform = CATransform3DIdentity
        card.transform = CGAffineTransformIdentity
        card.removeFromSuperview()
    }
    
    private func calculateMiddleCardIndexFromOffset(offset: CGFloat) -> Int {
        let middleOffset = offset + (frame.width + cardMargin) * 0.5
        var middleDisplayOffset = CGFloat(0)
        for index in 0 ..< _numberOfCards {
            middleDisplayOffset = _cardPositionOffsets[index]
            if middleDisplayOffset > middleOffset {
                _middleCardIndex = index
                break
            }
        }
        return _middleCardIndex
    }
    
    private func calculateProgressForUpdatingCard() -> CGFloat {
        let middleCardWidth = _cardWidths[_middleCardIndex] + cardMargin
        guard middleCardWidth != 0 else {
            return 0
        }
        let lastMiddleCardOffset = _cardPositionOffsets[_middleCardIndex] - ( _cardWidths[_middleCardIndex] + cardMargin) - (frame.width - _cardWidths[0]) * 0.5
        let cardOffset = fabs(_scrollView.contentOffset.x - lastMiddleCardOffset)
        let tempProgress = cardOffset / middleCardWidth
        return fabs(1 - 2 * tempProgress)
    }

    // MARK: - ScrollView Delegate
    
    @objc internal func scrollViewDidScroll(scrollView: UIScrollView) {
        checkupChangeOfdisplayRange()
        calculateMiddleCardIndexFromOffset(scrollView.contentOffset.x)
        if let middleCard = _visibleCardsPool[_middleCardIndex] {
            let progress = calculateProgressForUpdatingCard()
            self.delegate?.cardScrollView(self, updateVisiblsCard: middleCard, withProgress: progress)
        }
    }
    
    @objc internal func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let stopIndex = calculateMiddleCardIndexFromOffset(targetContentOffset.memory.x)
        targetContentOffset.memory.x = _cardPositionOffsets[stopIndex] - _cardWidths[stopIndex] - cardMargin - (frame.width - _cardWidths[0]) * 0.5
    }
}