//
//  CardView.swift
//  Set Game
//
//  Created by Rainer Standke on 2/14/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import UIKit

@IBDesignable
class CardView: UIView {
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func commonInit() {
		self.isOpaque = false
		self.clearsContextBeforeDrawing = true
	}
	
	static let shadowOpacity: Float = 0.2
	static let shadowOffset = CGSize(width: 3, height: 3)
	static let shadowRadius: CGFloat = 3.0
	
	var shapeIdx: Int = 2
	var styleIdx: Int = 2
	var colorIdx: Int = 2
	var count: Int = 2
	
	var status = CardStatus.none
	
	@IBInspectable var isFaceUp: Bool = false { didSet { setNeedsDisplay() } }
	var targetFrame = CGRect.zero
	
	var pathLineWidth: CGFloat { get { return bounds.width * 0.03 } }

	// make centered rect to draw one symbol in, based on self.bounds
	var drawingWidth: CGFloat { get { return bounds.width * 0.8 } }
	var drawingHeight: CGFloat { get { return bounds.height * 0.6 / 3 } }
	var drawingRect: CGRect { get { return CGRect(x: 0,
												   y: 0,
												   width: drawingWidth,
												   height: drawingHeight)
		}
	}
		
	var stripesPath: UIBezierPath { get { return stripesPathFunc() } }
	
	// MARK: - prep
	
	// call after init from outside to set up card
	func configure(shape: Int = 1, style: Int = 1, color: Int = 1, count: Int = 1) {
		self.shapeIdx = shape
		self.styleIdx = style
		self.colorIdx = color
		self.count = count
		
		isOpaque = false
		contentMode = .redraw
		
		layer.shadowOpacity =  Float(0.0)
		layer.shadowOffset = CardView.shadowOffset
		layer.shadowRadius = CardView.shadowRadius
	}
	
	override func copy() -> Any {
		let copy = CardView(frame: frame)
		
		copy.shapeIdx = shapeIdx
		copy.styleIdx = styleIdx
		copy.colorIdx = colorIdx
		copy.count = count
		
		copy.status = status
		
		copy.isFaceUp = isFaceUp
		
		copy.isOpaque = false
		
		copy.layer.shadowOpacity = layer.shadowOpacity
		copy.layer.shadowOffset.height = layer.shadowOffset.height
		copy.layer.shadowOffset.width = layer.shadowOffset.width
		copy.layer.shadowRadius = layer.shadowRadius
		
		copy.contentMode = contentMode
		
		return copy
	}
	
	// MARK: -
	
	override func draw(_ rect: CGRect) {
		let backgroundRoundedRect =  UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: bounds.width / 10) // (inset for stroke)
		
		#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1).setStroke()
		backgroundRoundedRect.lineWidth = 2.0
		backgroundRoundedRect.stroke()
		
		drawBackground(backgroundRoundedRect)
		if !isFaceUp {
			drawReverseText()
			return
		}
		
		drawStatusStroke()
		
		drawSymbols()
	}
	
	fileprivate func drawBackground(_ backgroundRoundedRect: UIBezierPath) {
		var fillColor: UIColor
		if !isFaceUp {
			fillColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
		} else {
			switch status {
			case .hinted, .hintedAndSelected:
				fillColor = #colorLiteral(red: 0.9986267686, green: 0.8799173934, blue: 0.7440991847, alpha: 1)
			case .matched:
				fillColor = #colorLiteral(red: 0.7655002408, green: 0.7655002408, blue: 0.7655002408, alpha: 1)
			default:
				fillColor = #colorLiteral(red: 0.9298661214, green: 0.93, blue: 0.929836067, alpha: 1)
			}
		}
		
		guard let context = UIGraphicsGetCurrentContext() else {
			// just in case...
			fillColor.setFill()
			backgroundRoundedRect.fill()
			return
		}
		
		context.saveGState()
		
		// drawing based on: https://stackoverflow.com/questions/8125623/how-do-i-add-a-radial-gradient-to-a-uiview?noredirect=1&lq=1
		
		backgroundRoundedRect.addClip()
		
		// get the radius, i.e. the distance to the more remote corner, as half the length of the diagonal
		// based on: https://www.mathopenref.com/rectanglediagonals.html
		let radius = sqrt(pow(bounds.height, 2) + pow(bounds.width, 2)) / 2
		
		// manipulate the two gradient colors, based on the original fill color
		var hue = CGFloat(0)
		var sat = CGFloat(0)
		var brite = CGFloat(0)
		var al = CGFloat(0)
		fillColor.getHue(&hue, saturation: &sat, brightness: &brite, alpha: &al)
		let inner = UIColor.init(hue: hue, saturation: sat, brightness: brite * 1.03, alpha: al).cgColor
		
		fillColor.getHue(&hue, saturation: &sat, brightness: &brite, alpha: &al)
		let outer  = UIColor.init(hue: hue, saturation: sat * 1.1, brightness: brite * 0.985, alpha: al).cgColor
		
		let colors = [inner, outer] as CFArray
		let endRadius = radius
		let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
		let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil)
		context.drawRadialGradient(gradient!, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: endRadius, options: CGGradientDrawingOptions.drawsBeforeStartLocation)
		
		context.restoreGState()
	}
	
	fileprivate func drawReverseText() {
		// put text on the back of the card
		let font = UIFont.init(name: "Arial", size: bounds.width / 3)
		let color = UIColor.red
		let dict: [NSAttributedStringKey : Any] = [.foregroundColor: color, .font: font!]
		let attrStr = NSAttributedString.init(string: "Set !", attributes: dict)
		let strSize = attrStr.size()
		let point = CGPoint.init(x: (bounds.width / 2) - (strSize.width / 2), y: (bounds.height / 2) - (strSize.height / 2))
		attrStr.draw(at: point)
	}
	
	fileprivate func drawSymbols() {
		// colors based on self.colorIdx, via extension on Int
		colorIdx.shapeColor().setFill()
		colorIdx.shapeColor().setStroke()
		
		// transforms based on self.count
		let transforms = affineTransforms()
		
		// for each count drawPath once
		for idx in 1...count {
			// path = shape based on self.styleIdx
			let path = bezierPath()
			path.apply(transforms[idx - 1])
			drawingFunc()(path)
		}
	}
	
	fileprivate func drawStatusStroke() {
		// draw stroke based on status
		if status == .selected || status == .hintedAndSelected {
			guard let context = UIGraphicsGetCurrentContext() else { return }
			
			context.saveGState()
			#colorLiteral(red: 1, green: 0.5776097488, blue: 0.09285281522, alpha: 1).setStroke()
			let strokePath = UIBezierPath(roundedRect: bounds.insetBy(dx: pathLineWidth, dy: pathLineWidth), cornerRadius: (bounds.width - pathLineWidth) / 10)
			strokePath.lineWidth = pathLineWidth * 2
			strokePath.stroke()
			context.restoreGState()
		}
	}
	
	// MARK: -
	
	func drawingFunc() -> (UIBezierPath) -> () {
		// return a function that takes a path, draws one of the symbols in a style based on self.styleIdx, and returns nothing
		assert((1...3).contains(self.styleIdx), "styleIdx must be 1...3, got: \(self.styleIdx)")
		switch styleIdx {
		case 1:
			// stroke
			return { path in
				self.colorIdx.shapeColor().setStroke()
				path.lineWidth = self.pathLineWidth
				path.stroke()
			}
		case 2:
			// solid
			return { path in
				self.colorIdx.shapeColor().setFill()
				path.fill()
			}
		case 3:
			// striped
			return { path in
				self.colorIdx.shapeColor().setStroke()
				path.lineWidth = self.pathLineWidth
				path.stroke()
				
				UIGraphicsGetCurrentContext()?.saveGState()
				path.addClip()
				self.stripesPath.stroke()
				UIGraphicsGetCurrentContext()?.restoreGState()
			}
		default:
			return {path in
				print("path: \(String(describing: path))")
			}
		}
	}
	
	// MARK: -
	
	func affineTransforms() -> [CGAffineTransform] {
		assert((1...3).contains(self.count), "count must be 1...3, got: \(self.count)")
		
		let translateX = (bounds.width - drawingRect.size.width) / 2
		
		func centerTransform() -> CGAffineTransform {
			return CGAffineTransform(translationX: translateX,
									 y: bounds.midY - (drawingRect.height / 2))
		}
		
		func topOfThreeTransform() -> CGAffineTransform {
			return CGAffineTransform(translationX: translateX,
									 y: (bounds.height - (drawingRect.height * 3)) / 4)
		}
		
		func topOfTwoTransform() -> CGAffineTransform {
			return CGAffineTransform(translationX: translateX,
									 y: (bounds.height - (drawingRect.height * 2)) / 3)
		}
		
		func bottomOfThreeTransform() -> CGAffineTransform {
			let drawHeight = drawingRect.height * 3
			return CGAffineTransform(translationX: translateX,
									 y: drawHeight + (bounds.height - drawHeight) / 4)
		}
		
		func bottomOfTwoTransform() -> CGAffineTransform {
			let drawHeight = drawingRect.height * 2
			return CGAffineTransform(translationX: translateX,
									 y: drawHeight + (bounds.height - drawHeight) / 3)
		}
		
		switch self.count {
		case 1: return [centerTransform()]
		case 2: return [topOfTwoTransform(), bottomOfTwoTransform()]
		case 3: return [topOfThreeTransform(), centerTransform(), bottomOfThreeTransform()]
		default: return []
		}
	}
	

	// MARK: - paths
	
	func bezierPath() -> UIBezierPath {
		assert((1...3).contains(self.shapeIdx), "shapeIdx must be 1...3, got: \(self.shapeIdx)")
		switch self.shapeIdx {
		case 1: return ovalPath()
		case 2: return diamondPath()
		case 3: return swigglePath()
		default: return UIBezierPath()
		}
	}
	
	func ovalPath() -> UIBezierPath {
		let path = UIBezierPath(roundedRect: drawingRect, cornerRadius: drawingRect.height / 2)
		return path
	}
	
	func diamondPath() -> UIBezierPath {
		let path = UIBezierPath()
		path.move(to: CGPoint(x: drawingRect.minX, y: drawingRect.midY))
		path.addLine(to: CGPoint(x: drawingRect.midX, y: drawingRect.minY))
		path.addLine(to: CGPoint(x: drawingRect.maxX, y: drawingRect.midY))
		path.addLine(to: CGPoint(x: drawingRect.midX, y: drawingRect.maxY))
		path.close()
		
		return path
	}
	
	func swigglePath() -> UIBezierPath {
		let oneThirdY = drawingRect.height / 3
		let twoThirdsY = drawingRect.height * 2 / 3
		
		let seventhX = drawingRect.width / 7
		
		let hOffset = seventhX * 0.8
		let vOffset = drawingRect.height * 0.3
		
		let path = UIBezierPath()
		
		let p0 = CGPoint(x: drawingRect.minX, y: twoThirdsY)
		path.move(to: p0)
		
		let p1 = CGPoint(x: seventhX * 2, y: drawingRect.minY)
		path.addCurve(to: p1,
					  controlPoint1: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y - vOffset),
					  controlPoint2: CGPoint(x: p1.x - hOffset, y: p1.y))
		
		let p2 = CGPoint(x: seventhX * 4, y: oneThirdY)
		path.addCurve(to: p2,
					  controlPoint1: CGPoint(x: path.currentPoint.x + hOffset, y: path.currentPoint.y),
					  controlPoint2: CGPoint(x: p2.x - hOffset , y: oneThirdY))
		
		let p3 = CGPoint(x: seventhX * 6, y: drawingRect.minY)
		path.addCurve(to: p3,
					  controlPoint1: CGPoint(x: path.currentPoint.x + hOffset, y: path.currentPoint.y),
					  controlPoint2: CGPoint(x: p3.x - hOffset, y: drawingRect.minY))
		
		let p4 = CGPoint(x: drawingRect.maxX, y: oneThirdY)
		path.addCurve(to: p4,
					  controlPoint1: CGPoint(x: path.currentPoint.x + (hOffset / 2), y: path.currentPoint.y),
					  controlPoint2: CGPoint(x: p4.x, y: p4.y - vOffset))
		
		let p5 = CGPoint(x: seventhX * 5, y: drawingRect.maxY)
		path.addCurve(to: p5,
					  controlPoint1: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y + vOffset),
					  controlPoint2: CGPoint(x: p5.x + hOffset, y: p5.y))
		
		let p6 = CGPoint(x: seventhX * 3, y: twoThirdsY)
		path.addCurve(to: p6,
					  controlPoint1: CGPoint(x: path.currentPoint.x - hOffset, y: path.currentPoint.y ),
					  controlPoint2: CGPoint(x: p6.x + hOffset, y: p6.y))
		
		let p7 = CGPoint(x: seventhX, y: drawingRect.maxY)
		path.addCurve(to: p7,
					  controlPoint1: CGPoint(x: path.currentPoint.x - hOffset, y: path.currentPoint.y ),
					  controlPoint2: CGPoint(x: p7.x + hOffset, y: p7.y))
		
		path.addCurve(to: p0,
					  controlPoint1: CGPoint(x: path.currentPoint.x - (hOffset / 2), y: path.currentPoint.y ),
					  controlPoint2: CGPoint(x: p0.x, y: p0.y + vOffset))
		
		path.close()
		
		return path
	}
	
	
	func stripesPathFunc() -> UIBezierPath {
		let path = UIBezierPath()
		
		path.lineWidth = self.pathLineWidth
		
		var xCursor = bounds.minX
		let xIncrement = bounds.width * 8 / 100
		
		while xCursor < bounds.maxX {
			
			path.move(to: CGPoint(x: xCursor, y: bounds.minY))
			path.addLine(to: CGPoint(x: xCursor, y: bounds.maxY))
			
			xCursor += xIncrement
		}
		
		return path
	}
	
	// MARK: -
	
	func fadeInShadow(duration: CFTimeInterval) {
		let animation = CABasicAnimation(keyPath: "shadowOpacity")
		animation.fromValue = layer.shadowOpacity
		animation.toValue = CardView.shadowOpacity
		animation.duration = duration
		layer.add(animation, forKey: animation.keyPath)
		layer.shadowOpacity = CardView.shadowOpacity
	}
	
	func increaseShadow(duration: CFTimeInterval) {
		
		// Note: could be animationGroup - but doesn't have to be
		CATransaction.begin()
		CATransaction.setAnimationDuration(duration)
		CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))

		let opacity: Float = 0.5
		let opacAnimation = CABasicAnimation(keyPath: "shadowOpacity")
		opacAnimation.fromValue = layer.shadowOpacity
		opacAnimation.toValue = opacity
		layer.add(opacAnimation, forKey: opacAnimation.keyPath)
		
		let newOffset = layer.shadowOffset.applying(CGAffineTransform.init(scaleX: 5, y: 5))
		let offsetAnimation = CABasicAnimation(keyPath: "shadowOffset")
		offsetAnimation.fromValue = layer.shadowOffset
		offsetAnimation.toValue = newOffset
		layer.add(offsetAnimation, forKey: offsetAnimation.keyPath)
		
		let radius: CGFloat = 7.5
		let radAnimation = CABasicAnimation(keyPath: "shadowRadius")
		radAnimation.fromValue = layer.shadowRadius
		radAnimation.toValue = radius
		layer.add(radAnimation, forKey: radAnimation.keyPath)
		
		CATransaction.commit()
		
		layer.shadowOffset = newOffset
		layer.shadowOpacity = opacity
		layer.shadowRadius = radius
	}
	
	func fadeOutShadow(duration: CFTimeInterval) {
		let animation = CABasicAnimation(keyPath: "shadowOpacity")
		animation.fromValue = layer.shadowOpacity
		animation.toValue = 0
		animation.duration = duration
		layer.add(animation, forKey: animation.keyPath)
		layer.shadowOpacity = 0
	}
	
	
}


enum CardStatus: Int {
	case none
	case hinted
	case selected
	case matched
	case hintedAndSelected
}

extension Int {
	internal func shapeColor() -> UIColor {
		assert(1...3 ~= self, "(color) self = Int needs to be in 1...3, got: \(self)")
		switch self {
		case 1: return #colorLiteral(red: 1, green: 0, blue: 0.4636183381, alpha: 1)
		case 2: return #colorLiteral(red: 0, green: 0.7144035233, blue: 0.03465424656, alpha: 1)
		case 3: return #colorLiteral(red: 0.5643854141, green: 0.5600750446, blue: 0.8518306613, alpha: 1)
		default: return #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		}
	}
}
