//
//  GridTest.swift
//  Set GameTests
//
//  Created by Rainer Standke on 2/13/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import XCTest

class GridTest: XCTestCase {
	
	// used to play around with Stanford-suppplied Grid, not a serious test
	func testStanfordGrid() {
		var grid = Grid(layout: .aspectRatio(5/8), frame: CGRect(x: 0, y: 0, width: 60, height: 50))
		grid.cellCount = 9
		print("grid.cellSize: \(String(describing: grid.cellSize))")
		
		for idx in 0..<grid.cellCount {
			print("grid[\(idx)]: \(String(describing: grid[idx]))")
			
		}
	}
}
