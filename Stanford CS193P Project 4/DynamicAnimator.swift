//
//  DynamicAnimator.swift
//  Stanford CS193P Project 4
//
//  Created by Rainer Standke on 7/11/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//




/* to be used by snap behavior, also catching the end of the snap */




import UIKit

class DynamicAnimator: UIDynamicAnimator, UIDynamicAnimatorDelegate {

	
	func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
		print("snap done")
		
		snapDoneCallBack?()
	}
	
	var snapDoneCallBack: (() -> ())? = nil
}
