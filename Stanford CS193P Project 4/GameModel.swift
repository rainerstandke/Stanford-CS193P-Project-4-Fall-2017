//
//  GameModel.swift
//  Set Game
//
//  Created by Rainer Standke on 2/4/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import Foundation
import GameKit

class GameModel {
	
	// cards that haven't been played/seen yet
	var deck = Card.newDeck()
	
	// 'on the table'
	var openCards = [Card]()
	
	// cached for speed
	var allMatches = [[Card]]()
	
	var score: Int = 0
	
	// MARK: -
	
	init() {
		// move 12 cards from deck to openCards
		let twelve = pickRandomCardsFromDeck(12)
		openCards.append(contentsOf: twelve)
		allMatches = getAllMatches()
	}
	
	func dropFromOpenCards(_ triplet: [Card]) {
		// remove from openCards
		
		for droppedCard in triplet {
			openCards = openCards.filter({ $0 != droppedCard })
		}

		allMatches = getAllMatches()
	}
	
	public func dealThree(replacing replacedCards: [Card]? = nil) -> Bool {
		// move 3 from deck to open
		
		defer {
			allMatches = getAllMatches()
		}
		
		if replacedCards != nil && openCards.count > 12 {
			dropFromOpenCards(replacedCards!)
			return true
		}
		
		var three = pickRandomCardsFromDeck(3)
		
		if three.count != 3 {
			return false
		}
		
		if replacedCards != nil {
			
			assert(replacedCards?.count == 3, "replacing fails with \(String(describing: replacedCards?.count)) cards")
			
			for idx in 0..<replacedCards!.count {
				guard let jdx = openCards.index(of: replacedCards![idx]) else { continue }
				openCards.remove(at: jdx)
				openCards.insert(three[idx], at: jdx)
			}
		} else {
			openCards.append(contentsOf: three)
		}
		return true
	}
	
	public func shuffleOpenCards() {
		openCards = GKMersenneTwisterRandomSource().arrayByShufflingObjects(in: openCards) as! [Card]
	}
	
	internal func pickRandomCardsFromDeck(_ count: Int) -> [Card] {
		// picks AND removes from deck
		var result = [Card]()
		for _ in 1...count {
			if deck.count == 0 { return result }

			let randomIndex = Int(arc4random_uniform(UInt32(deck.count - 1)))
			result.append(deck.remove(at: randomIndex))
		}
		return result
	}
	
	// all matches from openCards
	func getAllMatches() -> [[Card]] {
		var result = [[Card]]()
		
		for triplet in allTriplets(from: openCards) {
			if Card.matchCards(triplet) {
				result.append(triplet)
			}
		}
		return result
	}
	
	func allTriplets<T>(from arr: [T]) -> [[T]] {
		// return all possible triplet combos
		// combos are like sets, where order does not matter
		// (did try to make real set of sets, resulted in same number as array's)
		let max = arr.count
		
		if max < 3 { return [] }
		
		var retArr = [[T]]()
		
		for idx in 0...max - 3 {
			for jdx in idx + 1...max - 2 {
				for kdx in jdx + 1...max - 1  {
					retArr.append([arr[idx], arr[jdx], arr[kdx]])
				}
			}
		}
		return retArr
	}
	
	func openCardIndicesForCards(_ cards: [Card]) -> [Int] {
		return cards.compactMap { (card) -> Int? in
			openCards.index(of: card)
		}
	}
	
	func logMatches() {
		for triplet in allMatches {
			print(tripletDescription(triplet))
		}
		if allMatches.count == 0 {
			print("no match")
		}
		
		print("\n")
	}
	
	func tripletDescription(_ triplet:[Card]) -> String {
		assert(triplet.count == 3, "tripletDescription: expected 3 Cards, got: \(triplet.count)")
		
		var retStr = "triplet: idx: \(String(describing: openCardIndicesForCards(triplet)))"
		retStr.append(" \(String(describing: triplet))")
		
		return retStr
	}
}
