//
//  Stanford_CS193P_Project_4Tests.swift
//  Stanford CS193P Project 4Tests
//
//  Created by Rainer Standke on 5/10/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import XCTest
@testable import Stanford_CS193P_Project_4

class Stanford_CS193P_Project_4Tests: XCTestCase {
	
	let deck = Card.newDeck()
	
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	func testMatching() {
		// NOTE: this only tests for positive matches, not negative ones
		// non-matches are kinda covered by testing Int Troplets elsewhere
		
		var triplets = [[Card]]()
		triplets.append([deck[0], deck[1], deck[2]])
		triplets.append([deck[0], deck[27], deck[54]])
		triplets.append([deck[0], deck[9], deck[18]])
		triplets.append([deck[0], deck[3], deck[6]])
		triplets.append([deck[0], deck[4], deck[8]])
		triplets.append([deck[0], deck[36], deck[72]])
		triplets.append([deck[0], deck[12], deck[24]])
		triplets.append([deck[0], deck[28], deck[56]])
		triplets.append([deck[0], deck[10], deck[20]])
		triplets.append([deck[0], deck[30], deck[60]])
		triplets.append([deck[0], deck[13], deck[26]])
		triplets.append([deck[0], deck[31], deck[62]])
		triplets.append([deck[0], deck[37], deck[74]])
		triplets.append([deck[0], deck[39], deck[78]])
		
		for triplet in triplets {
			runOneMatchingTriplet(triplet)
		}
	}
	
	
	func runOneMatchingTriplet(_ triplet: [Card]) {
		XCTAssert(triplet.count == 3, "Can't test anything but Card TRIPLETS, got: \(triplet.count)!")
		
		let permuts = tripletPermutations(in: triplet)
		
		for triplet in permuts {
			XCTAssertTrue(Card.matchCards(triplet), "expected match true for: \(triplet) !")
			for keyPath in Card.allKeyPaths {
				XCTAssertTrue(Card.keyPathMatch(triplet, with: keyPath), "expected keypath match for: \(keyPath)")
			}
		}
	}
	
	
	func tripletPermutations<T>(in arr: [T]) -> [[T]] {
		
		func shiftedPermutations<T>(in arr: [T]) -> [[T]] {
			// shift first to last once for each array element
			// does not change order
			
			var mutArr = arr
			var retArr = [[T]]()
			
			for _ in mutArr {
				mutArr.append(mutArr.removeFirst())
				retArr.append(mutArr)
			}
			return retArr
		}
		
		var retArr = [[T]]()
		
		// for triplets *this* gives all possible permutations:
		retArr.append(contentsOf: shiftedPermutations(in: arr))
		retArr.append(contentsOf: shiftedPermutations(in: arr.reversed()))
		
		return retArr
	}
	
	func testPermutationMechanism() {
		let simplePermuts = tripletPermutations(in: [1, 2, 3])
		XCTAssertTrue(String(describing: simplePermuts) == "[[2, 3, 1], [3, 1, 2], [1, 2, 3], [2, 1, 3], [1, 3, 2], [3, 2, 1]]", "TripletPermutations broken, got: \(simplePermuts)")
	}
	
	
	func testIntTriplet() {
		var testResultString = String()
		for idx in 1...3 {
			for jdx in 1...3 {
				for kdx in 1...3 {
					let triplet = [idx, jdx, kdx]
					let matching = Card.matchThree(in: triplet)
					testResultString.append("triplet: \(String(describing: triplet)): \(matching)\n")
				}
			}
		}
		XCTAssert(testResultString == intTripletTestString, "TripletTestString no match: \(testResultString)")
	}
	
	let intTripletTestString = """
	triplet: [1, 1, 1]: true
	triplet: [1, 1, 2]: false
	triplet: [1, 1, 3]: false
	triplet: [1, 2, 1]: false
	triplet: [1, 2, 2]: false
	triplet: [1, 2, 3]: true
	triplet: [1, 3, 1]: false
	triplet: [1, 3, 2]: true
	triplet: [1, 3, 3]: false
	triplet: [2, 1, 1]: false
	triplet: [2, 1, 2]: false
	triplet: [2, 1, 3]: true
	triplet: [2, 2, 1]: false
	triplet: [2, 2, 2]: true
	triplet: [2, 2, 3]: false
	triplet: [2, 3, 1]: true
	triplet: [2, 3, 2]: false
	triplet: [2, 3, 3]: false
	triplet: [3, 1, 1]: false
	triplet: [3, 1, 2]: true
	triplet: [3, 1, 3]: false
	triplet: [3, 2, 1]: true
	triplet: [3, 2, 2]: false
	triplet: [3, 2, 3]: false
	triplet: [3, 3, 1]: false
	triplet: [3, 3, 2]: false
	triplet: [3, 3, 3]: true

	"""
	
	
}
