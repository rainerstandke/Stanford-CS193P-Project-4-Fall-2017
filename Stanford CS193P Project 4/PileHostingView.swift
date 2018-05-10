//
//  PileHostingView.swift
//  Set Game Card Based
//
//  Created by Rainer Standke on 5/1/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import UIKit

class PileHostingView: UIView {

	var deckStack: CardView!
	var discardedStack: CardView!
	
	func addTwoStacks() -> (deck: CardView, discard: CardView) {
		
		let rotated = CGAffineTransform.init(rotationAngle: .pi / 2)
		
		deckStack = CardView.init(frame: deckFrame())
		deckStack.isOpaque = false
		addSubview(deckStack)
		deckStack.transform = rotated
		
		discardedStack = CardView.init(frame: discardFrame())
		discardedStack.isOpaque = false
		addSubview(discardedStack)
		discardedStack.transform = rotated
		
		return (deckStack, discardedStack)
	}
    
	func deckFrame() -> CGRect {
		return pileFrame(type: .Deck)
	}
	
	func discardFrame() -> CGRect {
		return pileFrame(type: .Discard)
	}
	
	func pileFrame(type: PileType) -> CGRect {
		// rects are positioned by their upper left corners
		// position stacks upright, before roation into landscape
		
		// deck dimension based on own height and aspect 5/8 - in vertical orientation
		let pileWidth = self.bounds.height
		let pileHeight = pileWidth * 8 / 5
		let halfDiff = abs((pileHeight - pileWidth) / 2)
		
		// width left over after placing 2 landscape stacks, div by 3
		let oneSpacerWidth = (self.bounds.width - (pileHeight * 2)) / 3
		let pileOriginX: CGFloat!
		switch type {
		case .Discard:
			// from right edge, move left by 1 spacer + 1 height, then move right by diff between tall and wide
			pileOriginX = bounds.width - oneSpacerWidth - pileHeight + halfDiff
		case .Deck:
			 fallthrough
		default:
			pileOriginX = oneSpacerWidth + halfDiff
		}
		
		// vertical same for both
		let pileOriginY = self.bounds.height / 2 - (pileHeight / 2)
		
		return CGRect.init(x: pileOriginX, y: pileOriginY, width: pileWidth, height: pileHeight)
	}
	
	func updatePilePositions() {
		// un-rotate, new - upright - frame, rotate into landscape
		let rotated = CGAffineTransform.init(rotationAngle: .pi / 2)
		
		deckStack.transform = CGAffineTransform.identity
		deckStack.frame = deckFrame()
		deckStack.transform = rotated

		discardedStack.transform = CGAffineTransform.identity
		discardedStack.frame = discardFrame()
		discardedStack.transform = rotated
	}
	
	
	enum PileType {
		case Deck
		case Discard
	}
}
