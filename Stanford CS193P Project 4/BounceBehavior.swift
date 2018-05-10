//
//  DynamicBehavior.swift
//  Set Game Card Based
//
//  Created by Rainer Standke on 2/20/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//




/*


House and combine several UIDynamicItemBehaviors


*/


import UIKit


class BounceAroundBehavior: UIDynamicBehavior {
	
	lazy var itemBehavior: UIDynamicItemBehavior = {
		let behavior = UIDynamicItemBehavior()
		behavior.allowsRotation = true
		behavior.elasticity = 1.0 //0.2
		behavior.resistance = 0.1 //1.0
		return behavior
	}()
	
	lazy var collisionBehavior: UICollisionBehavior = {
		let behavior = UICollisionBehavior()
		behavior.translatesReferenceBoundsIntoBoundary = true // ??
		return behavior
	}()
	
	func push(_ item: UIDynamicItem) {
		let pushBehavior = UIPushBehavior(items: [item], mode: .instantaneous)

		// push into center
		if let referenceBounds = dynamicAnimator?.referenceView?.bounds {
			let center = CGPoint(x: referenceBounds.midX, y: referenceBounds.midY)
			switch (item.center.x, item.center.y) {
			case let (x, y) where x < center.x && y < center.y:
				pushBehavior.angle = (CGFloat.pi/2).arc4random
			case let (x, y) where x > center.x && y < center.y:
				pushBehavior.angle = CGFloat.pi-(CGFloat.pi/2).arc4random
			case let (x, y) where x < center.x && y > center.y:
				pushBehavior.angle = (-CGFloat.pi/2).arc4random
			case let (x, y) where x > center.x && y > center.y:
				pushBehavior.angle = CGFloat.pi+(CGFloat.pi/2).arc4random
			default:
				pushBehavior.angle = (CGFloat.pi*2).arc4random
			}
		}
		
		pushBehavior.magnitude = CGFloat(1.0) + 6.0 * CGFloat(1.0).arc4random
		pushBehavior.action = { [unowned pushBehavior, weak self] in
			self?.removeChildBehavior(pushBehavior)
		}
		addChildBehavior(pushBehavior)
	}
	
	func addItem(_ item: UIDynamicItem) {
		collisionBehavior.addItem(item)
		itemBehavior.addItem(item)
//		push(item)
	}
	
	func removeItem(_ item: UIDynamicItem) {
		collisionBehavior.removeItem(item)
		itemBehavior.removeItem(item)
	}
	
	override init() {
		super.init()
		addChildBehavior(itemBehavior)
		addChildBehavior(collisionBehavior)
	}
	
	convenience init(inAni animator: UIDynamicAnimator, in inRect: CGRect) {
		self.init()
		animator.addBehavior(self)
		let boundPath = UIBezierPath(rect: inRect)
		collisionBehavior.addBoundary(withIdentifier: "from in-rect" as NSCopying, for: boundPath)
	}
}


extension CGFloat {
	var arc4random: CGFloat {
		return self * (CGFloat(arc4random_uniform(UInt32.max))/CGFloat(UInt32.max))
	}
}
