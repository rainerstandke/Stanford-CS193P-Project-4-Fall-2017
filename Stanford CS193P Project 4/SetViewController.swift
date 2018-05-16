//
//  ViewController.swift
//  Set Game
//
//  Created by Rainer Standke on 2/3/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import UIKit

class SetViewController: UIViewController {
	
	private lazy var game = GameModel()
	
	// keep track of view-card association
	private var cardViewDict = [Card:CardView]()
	
	
	/* NOTE: face-up cards on table are held in gameModel.openCards. */
	private var selectedCards = [Card]()
	private var matchedCards = [Card]()
	private var hintedCards = [Card]()
	
	private var lastScoreDelta =  0 {
		didSet {
			scoreDeltaLabel.text = lastScoreDelta.decoratedString()
			game.score += lastScoreDelta
			scoreLabel.text = String(describing: game.score)
		}
	}
	
	private var haveDiscarded = false
	
	// MARK: - Dynamic Animations
	
	lazy var animator = UIDynamicAnimator(referenceView: view)
	lazy var bounceBehavior: BounceAroundBehavior = {
		let bounce = BounceAroundBehavior(inAni: animator,
										  in: self.cardsView.frame)
		return bounce
	}()
	
	// MARK: - UI properties
	
	// needed for de/activation
	@IBOutlet weak var hintBtn: UIButton!
	@IBOutlet weak var autoPlayBtn: UIButton!
	
	@IBOutlet weak var scoreLabel: UILabel!
	@IBOutlet weak var scoreDeltaLabel: UILabel!
	@IBOutlet weak var remainingCountLabel: UILabel!
	
	@IBOutlet weak var cardsView: UIView! // main playing field
	
	var deckStack: CardView!
	var discardedStack: CardView!
	@IBOutlet weak var pileHostingView: PileHostingView!
	
	// MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let twoStacks = pileHostingView.addTwoStacks()
		deckStack = twoStacks.deck
		let gestRec =  UITapGestureRecognizer.init(target: self, action: #selector(handleTapOnCard(gestRec:)))
		deckStack.addGestureRecognizer(gestRec)
		
		discardedStack = twoStacks.discard
		discardedStack.isHidden = true
		
		flyOpenCardsIntoPosition()
	}
	
	// react to size change / rotation
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { _ in
			self.pileHostingView.updatePilePositions()
			self.updateCardPositions()
		})
	}
	
	// MARK: -
	
	internal func flyOpenCardsIntoPosition() {
		
		game.openCards.forEach { (card) in
			if cardViewDict[card] == nil {
				// put new cards on deck stack, face down
				let newCardView = makeNewCardView()
				cardViewDict[card] = newCardView
				cardsView.addSubview(newCardView)
				newCardView.configure(shape: card.shape, style: card.style, color: card.color, count: card.count)
			}
		}
		
		// get position grid
		let openCount = game.openCards.count
		var grid = Grid(layout: .aspectRatio(5/8), frame: cardsView.bounds)
		grid.cellCount = openCount
		
		var timeInterval = TimeInterval(0.3) // this starting value allows for card's 'status' dissolves to finish before doing any moves
		
		for (idx, card) in game.openCards.enumerated()  {
			//
			guard let cardView = cardViewDict[card] else { continue }
			guard let frame = grid[idx] else { continue }
			
			animateCardViewForStatus(cardView)

			cardView.targetFrame = frame
		}
		
		game.openCards.forEach { (card) in
			// fly cards into position
			
			guard let cardView = cardViewDict[card] else { return }
			
			// don't mess with it if card is already in place / position
			if cardView.frame.integral == cardView.targetFrame.integral {
				cardView.frame = cardView.targetFrame
				return
			}
			
			UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6, delay: timeInterval, options: [ .allowUserInteraction, .allowAnimatedContent], animations: {
				// move card from current position (stack or table) to its new place
				cardView.transform = CGAffineTransform.identity
				cardView.frame = cardView.targetFrame
			}, completion: { (_) in
				if !cardView.isFaceUp {
					// flip
					UIView.transition(with: cardView,
									  duration: 0.5,
									  options: [.transitionFlipFromLeft, .allowUserInteraction, .allowAnimatedContent],
									  animations: { cardView.isFaceUp = true },
									  completion: { (aBool) in
										// can't happen before b/c flip omits shadow
										cardView.fadeInShadow(duration: 0.6)
					})
				}
			})
			
			timeInterval += 0.05 // slight staggering
		}
		updateDashBoard()
	}
	
	func makeNewCardView() -> CardView {
		// new cardView, face down, at deckStack, rotated
		
		var startingFrame = deckStack.frame
		startingFrame.morph()
		startingFrame = (deckStack.superview?.convert(startingFrame, to: cardsView))!
		let cardView = CardView(frame: startingFrame)
		cardView.transform = CGAffineTransform.init(rotationAngle: .pi / 2)
		
		let gestRec =  UITapGestureRecognizer.init(target: self, action: #selector(handleTapOnCard(gestRec:)))
		cardView.addGestureRecognizer(gestRec)
		
		return cardView
	}
	
	internal func updateCardPositions() {
		// no animations, for size class changes
		
		// get position grid
		let openCount = game.openCards.count
		var grid = Grid(layout: .aspectRatio(5/8), frame: cardsView.bounds)
		grid.cellCount = openCount
		
		for (idx, card) in game.openCards.enumerated()  {
			guard let cardView = cardViewDict[card] else { continue }
			guard let frame = grid[idx] else { continue }
			
			cardView.frame = frame
		}
	}

	// MARK: -
	
	func flyOutMatchedCards() {
		// fly out cards that have been matched
		// removes from cardsView right away, by way of adding to superView (and dropping them at the end)
		
		for card in matchedCards {
			// move cardViews up one level
			guard let cardView = cardViewDict[card] else { print("no card"); continue }
			
			let newFrame = cardsView.superview!.convert(cardView.frame, from: cardView.superview)
			cardsView.superview!.addSubview(cardView)
			cardView.frame = newFrame
		}
		DispatchQueue.main.async {
			var staggerInterval = TimeInterval(0) // w/o delay things can get whacky
			let staggerIncrement = TimeInterval(0.3)
			let firstPhaseDuration = TimeInterval(0.5)
			
			for (idx, card) in self.matchedCards.enumerated() {
				guard let cardView = self.cardViewDict[card] else { print("no card"); continue }
				
				Timer.scheduledTimer(withTimeInterval: staggerInterval, repeats: false) { _ in
					
					UIView.transition(with: cardView, duration: firstPhaseDuration, options: [.transitionCrossDissolve, .allowAnimatedContent, .allowUserInteraction], animations: {
						// grow just slightly
						cardView.frame = cardView.frame.insetBy(dx: -1.25, dy: -2)
						
						// fade out matched
						cardView.status = .none
						cardView.setNeedsDisplay()
						
						// shadow uses CAAnimation
						cardView.increaseShadow(duration: firstPhaseDuration)
					}, completion: { (_) in
						// start bouncing...
						self.bounceBehavior.addItem(cardView)
						
						// make sure the push starts around the same time for each, despite staggering
						let delay = (2 * staggerIncrement) - (Double(idx) * staggerIncrement)
						Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
							self.bounceBehavior.push(cardView)
						}
						
						// ... until timer fires
						Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (_) in
							self.bounceBehavior.removeItem(cardView)
							
							// snap to discard stack
							// (b/c snap wants to be initialized with the item, it's a one-off)
							let snapPoint = self.cardsView.superview!.convert(self.discardedStack.center, from: self.discardedStack.superview!)
							let snapBehavior = UISnapBehavior(item: cardView, snapTo: snapPoint)
							snapBehavior.damping = 0.1
							UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: [ .allowUserInteraction, .allowAnimatedContent], animations: {
								self.animator.addBehavior(snapBehavior) // snaps quickly, rings out longer
								cardView.fadeOutShadow(duration: 0.3)
								// NOTE: tried to shrink while snapping, but transform seems to be reset at snap conclusion, thus resize did not 'stick'
							})
							// b/c there seems to be no way to find when snap is done set timer for next step
							Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (_) in
								self.animator.removeBehavior(snapBehavior)
								
								if idx < 2 {
									// the first 2 cards 'evaporate' after snapping
									cardView.alpha = 0
									cardView.removeFromSuperview()
									return
								}
								
								// trigger fly in, so that the anis overlap
								self.flyOpenCardsIntoPosition()
								self.updateDashBoard()
								
								UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6, delay: 0.0, options: [ .allowUserInteraction, .allowAnimatedContent], animations: {
									
									// rotate, move on discard stack
									cardView.transform = CGAffineTransform.init(rotationAngle: .pi / 2)
									let newFrame = self.cardsView.superview!.convert(self.discardedStack.frame, from: self.pileHostingView)
									cardView.frame = newFrame
									
									Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (_) in
										UIView.transition(with: cardView, duration: 0.3, options: [.transitionFlipFromTop, .allowAnimatedContent, .allowUserInteraction], animations: {
											// flip
											cardView.isFaceUp = false
										})
									})
								}, completion: { (_) in
									self.haveDiscarded = true
									self.discardedStack.isHidden = false
									cardView.alpha = 0
									cardView.removeFromSuperview()
								})
							})
						})
					})
				}
				staggerInterval += staggerIncrement
			}
			
			self.matchedCards.forEach { self.cardViewDict.removeValue(forKey: $0) }
			self.game.dropFromOpenCards(self.matchedCards)
			self.matchedCards.removeAll()
		}
	}
	
	// MARK: - card tap
	
	func processPotentialMatch() -> Bool {
		// check for current match, trigger fly out & in
		
		if matchedCards.count < 3 { return false }
		
		_ = game.dealThree(replacing: matchedCards)
		flyOutMatchedCards()
		
		// update score
		lastScoreDelta = K.matchingScore
		
		return true
	}
	
	func processTapOn(card: Card) {
		
		// local helpers
		func deselect(card: Card) {
			selectedCards.removeItem(card)
			reDisplayCard(card)
			lastScoreDelta = K.deSelectionScore
		}
		
		func select(card: Card) {
			selectedCards.append(card)
			reDisplayCard(card)
		}
		
		// de-select already selected
		if selectedCards.contains(card) {
			deselect(card: card)
			return
		}
		
		switch selectedCards.count {
		case 0, 1:
			select(card: card)
		case 2:
			// will card make for matching triplet?
			let tempTriplet = selectedCards + [card]
			if Card.matchCards(tempTriplet) {
				// YES -> make 3 grey: remove all from selected, add them to matched, redraw 3 (in grey)
				tempTriplet.forEach { card in
					hintedCards.removeItem(card)
					selectedCards.removeItem(card)
					matchedCards.append(card)
					reDisplayCard(card)
				}
			} else {
				// NO -> add 3rd to selected, redraw it
				select(card: card)
			}
		case 3:
			// card is 4th, no current match -> deselect 3 selected, add this card to selected, redraw 4
			selectedCards.forEach { deselect(card: $0) }
			select(card: card)
		default:
			return
		}
	}
	
	func reDisplayCard(_ card: Card) {
		guard let cardView = cardViewDict[card] else { return }
		
		// deal with card 'modes'
		let selected = selectedCards.contains(card)
		let matched = matchedCards.contains(card)
		let hinted = hintedCards.contains(card)
		
		if selected && hinted {
			cardView.status = .hintedAndSelected // TODO: does this even exist?
		} else if selected {
			cardView.status = .selected
		} else if matched {
			cardView.status = .matched
		} else if hinted {
			cardView.status = .hinted
		} else {
			cardView.status = .none
		}
		
		animateCardViewForStatus(cardView)
	}
	
	func updateCardStatus(_ card: Card, to status: CardStatus) {
		// set visual status for cardView, add card to respective array
		guard let cardView = cardViewDict[card] else { return }
		
		selectedCards.removeItem(card)
		hintedCards.removeItem(card)
		matchedCards.removeItem(card)
		
		// TODO: this is logically flawed - hinted & selected can co-exist - preserve hintedness
		switch status {
		case .hinted:
			hintedCards.append(card)
		case .selected:
			selectedCards.append(card)
		case .matched:
			matchedCards.append(card)
		default:
			break
		}

		prepCardViewForDisplay(card, in: cardView) // TODO: merge this in here?   
		animateCardViewForStatus(cardView)
	}
	
	func prepCardViewForDisplay(_ card: Card, in cardView: CardView) {
		
		
		// TODO: merge with update... method?
		
		
		// deal with card 'modes'
		let selected = selectedCards.contains(card)
		let matched = matchedCards.contains(card)
		let hinted = hintedCards.contains(card)
		
		if selected && hinted {
			cardView.status = .hintedAndSelected // TODO: does this even exist?
		} else if selected {
			cardView.status = .selected
		} else if matched {
			cardView.status = .matched
		} else if hinted {
			cardView.status = .hinted
		} else {
			cardView.status = .none
		}
	}
	
	func updateDashBoard() {
		// update bottom part of UI
		remainingCountLabel.text = String(game.deck.count)
		
		let deckHasCards = game.deck.count >= 3
		deckStack.isHidden = !deckHasCards
		
		discardedStack.isHidden = !haveDiscarded
		
		let matchCount = game.allMatches.count
		let matchExists = matchCount > 0
		autoPlayBtn.isEnabled = matchExists
		hintBtn.isEnabled = matchExists
		
		let btnText = matchExists ? "Hint (\(matchCount))" : "Hint"
		hintBtn.setTitle(btnText, for: .normal)
	}
	
	func animateCardViewForStatus(_ cardView: CardView) {
		UIView.transition(with: cardView, duration: K.cardStatusTransitionInterval, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
			// fade in selected, hinted, matched looks
			cardView.setNeedsDisplay()
		}, completion: nil)
	}
	
	// MARK: - user actions
	
	@objc func handleTapOnCard(gestRec: UIGestureRecognizer) {
		// called from cardView on table, as well as deck stack
		
		guard let cardView = gestRec.view as? CardView else { return }
		
		if !processPotentialMatch() {
			
			if let card = cardViewDict.key(forValue: cardView) {
				// open card on table
				processTapOn(card: card)
			} else if !cardView.isFaceUp {
				// deck stack
				
				if game.allMatches.count > 0 {
					lastScoreDelta = K.additionalCardsScore
				}
				
				_ = game.dealThree()
				flyOpenCardsIntoPosition()
			}
		}
	}
	
	@IBAction func shuffleOpenCards(_ sender: Any) {
		if let rotGestRec = sender as? UIRotationGestureRecognizer {
			if rotGestRec.state == .ended {
				game.shuffleOpenCards()
				flyOpenCardsIntoPosition()
			}
		}
	}
	
	@IBAction func hintMatch() {
		if let matchingTriplet = game.allMatches.last {
			hintedCards = matchingTriplet
			hintedCards.forEach { card in
				hintedCards.append(card)
				reDisplayCard(card)
			}
			lastScoreDelta = -1
		}
	}
	
	@IBAction func newGame(_ sender: UIButton) {
		game = GameModel()
		
		// fade out open cards
		cardViewDict.removeAll()
		UIView.transition(with: cardsView, duration: 0.5, options: [.transitionCrossDissolve], animations: {
			self.cardsView.subviews.forEach { $0.removeFromSuperview() }
		}) { (_) in self.flyOpenCardsIntoPosition() }
		
		selectedCards.removeAll()
		matchedCards.removeAll()
		hintedCards.removeAll()
		
		haveDiscarded = false
		
		lastScoreDelta = 0
		
		updateDashBoard()
	}
	
	@IBAction func autoplay() {
		
		if processPotentialMatch() {
			return
		}
		if let aMatch = game.allMatches.last {
			aMatch.forEach { card in
				matchedCards.append(card)
				reDisplayCard(card)
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.autoplay()
			}
		} else {
			// no match, deal addtl. 3
			if !game.dealThree() {
				// no more cards on deck
				return
			}
			flyOpenCardsIntoPosition()
		}
	}
		
	// MARK: -
	
	override var description: String {
		return "m: \(self.matchedCards) - s: \(self.selectedCards) - h: \(self.hintedCards)"
	}
}

extension Int {
	func decoratedString() -> String {
		let prefix = self > 0 ? "+" : ""
		return prefix + String(describing: self)
	}
}


extension CGRect {
	// 'morph' self into rect that could be derived by rotating it by 90 degrees
	// preserves origin in upper left, rather than LL or UR
	
	mutating func morph() {
		let delta = (midX - origin.x) - (midY - origin.y)
		origin.x += delta
		origin.y -= delta
		
		let tempW = size.width
		size.width = size.height
		size.height = tempW
	}
}

extension Collection where Iterator.Element: Equatable {
	mutating func removeItem(_ item: Element) {
		self = self.filter { $0 != item } as! Self
	}
}

extension Dictionary where Value: Equatable {
	// from: https://stackoverflow.com/questions/41383937/reverse-swift-dictionary-lookup
	
	func key(forValue value: Value) -> Key? {
		// first { } is like filter for first where
		// $0 is a key-value pair, .1 is its value
		// it's ? optional, .0 is its key
		return first { $0.1 == value }?.0
	}
}


