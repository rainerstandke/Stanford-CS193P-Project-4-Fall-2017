import Foundation

struct Card: Equatable, CustomStringConvertible, Hashable {
	let shape: Int
	let style: Int
	let color: Int
	let count: Int
	
	internal static let allKeyPaths = [\Card.shape, \Card.style, \Card.color, \Card.count]
	
	public static func == (lhs: Card, rhs: Card) -> Bool {
		return rhs.color == lhs.color &&
			lhs.count == rhs.count &&
			lhs.shape == rhs.shape &&
			lhs.style == rhs.style
	}
	
	
	public static func newDeck() -> [Card] {
		
		var deck = [Card]()
		
		for shapeIdx in 1...3 {
			for styleIdx in 1...3 {
				for colorIdx in 1...3 {
					for countIdx in 1...3 {
						deck.append(Card(shape: shapeIdx,
										 style: styleIdx,
										 color: colorIdx,
										 count: countIdx))
					}
				}
			}
		}
		
		return deck
	}
	
	public static func matchCards(_ triplet: [Card]) -> Bool {
		for keyPath in allKeyPaths {
			if keyPathMatch(triplet, with: keyPath) == false {
				return false
			}
		}
		return true
	}
	
	internal static func keyPathMatch(_ triplet: [Card],
									  with inKP: KeyPath<Card, Int>) -> Bool {
		assert(triplet.count == 3, "triplet count needs to be 3, got: \(triplet.count)")
		
		// unpack triplet using keyPath
		return matchThree(in: [triplet[0][keyPath: inKP], triplet[1][keyPath: inKP], triplet[2][keyPath: inKP]])
	}
	
	internal static func matchThree<T: Equatable>(in triplet: [T]) -> Bool {
		// match is defined as 'all equal or all different'
		
		if triplet[0] == triplet[1] {
			return triplet[1] == triplet[2]
		} else {
			return triplet[0] != triplet[2] && triplet[1] != triplet[2]
		}
	}
	
	var hashValue: Int {
		return shape * 1000 + style * 100 + color * 10 + count
	}
	
	var description: String {
		return "Card: \(shape).\(style).\(color).\(count)"
	}
}


