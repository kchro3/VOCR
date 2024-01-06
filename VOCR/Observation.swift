//
//  Observation.swift
//  VOCR
//
//  Created by Chi Kim on 1/5/24.
//  Copyright © 2024 Chi Kim. All rights reserved.
//

import Foundation
import Vision

struct Observation {

	var boundingBox:CGRect
	var value:String
	var vnObservation:VNRecognizedTextObservation?
	var gptObservation:GPTObservation?

	init(_ obs:GPTObservation) {
		self.gptObservation = obs
		self.value = obs.label+"\n"+obs.content
		let x = CGFloat(obs.boundingBox[0])
		let y = CGFloat(obs.boundingBox[1])
		let width = CGFloat(obs.boundingBox[2])
		let height = CGFloat(obs.boundingBox[3])
		var rect = CGRect(x:x, y:y, width:width, height:height)
		debugPrint(value, rect, rect)
		rect = VNNormalizedRectForImageRect(rect, Int(Navigation.shared.cgSize.width), Int(Navigation.shared.cgSize.height))
		rect = CGRect(x:rect.minX, y:1-rect.maxY, width:rect.width, height:rect.height)
		self.boundingBox = rect
		debugPrint(boundingBox)
	}

	init(_ obs:VNRecognizedTextObservation) {
		self.vnObservation = obs
		self.value = obs.topCandidates(1)[0].string
		self.boundingBox = obs.boundingBox
		debugPrint(value, boundingBox)
	}

}


