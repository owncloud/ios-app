//
//  ProgressView.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.01.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

class ProgressView: UIView, Themeable {
	var backgroundCircleLayer : CAShapeLayer = CAShapeLayer()
	var foregroundCircleLayer : CAShapeLayer = CAShapeLayer()
	var stopButtonLayer : CAShapeLayer = CAShapeLayer()

	private let dimensions : CGSize = CGSize(width: 30, height: 30)
	private let circleLineWidth : CGFloat = 3

	private var progressObservationFractionCompleted : NSKeyValueObservation?
	private var progressObservationIsIndeterminate : NSKeyValueObservation?
	private var progressObservationCancelled : NSKeyValueObservation?
	private var progressObservationFinished : NSKeyValueObservation?

	var progress : Progress? {
		willSet {
			if newValue != progress {
				progressObservationFractionCompleted?.invalidate()
				progressObservationIsIndeterminate?.invalidate()
				progressObservationCancelled?.invalidate()
				progressObservationFinished?.invalidate()
			}
		}

		didSet {
			if let newProgress = progress {
				progressObservationFractionCompleted = newProgress.observe(\Progress.fractionCompleted) { [weak self] (_, _) in
					self?.update()
				}

				progressObservationIsIndeterminate = newProgress.observe(\Progress.isIndeterminate) { [weak self] (_, _) in
					self?.update()
				}

				progressObservationCancelled = newProgress.observe(\Progress.isCancelled) { [weak self] (_, _) in
					self?.update()
				}

				progressObservationFinished = newProgress.observe(\Progress.isFinished) { [weak self] (_, _) in
					self?.update()
				}
			}

			self.update()
		}
	}

//	var accessibilityLabel: String? {
//
//	}

	private var spinning : Bool = false {
		didSet {
			if spinning != oldValue {
				if spinning {
					let spinningAnimation = CABasicAnimation(keyPath: "transform.rotation.z")

					spinningAnimation.toValue = 2 * CGFloat.pi

					spinningAnimation.duration = 1.0
					spinningAnimation.isCumulative = true
					spinningAnimation.repeatCount = 1000

					foregroundCircleLayer.add(spinningAnimation, forKey: "spinningAnimation")
				} else {
					foregroundCircleLayer.removeAnimation(forKey: "spinningAnimation")
				}
			}
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		Theme.shared.register(client: self, applyImmediately: true)

		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.cancel)))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		self.progress = nil
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		foregroundCircleLayer.fillColor = nil
		backgroundCircleLayer.fillColor = nil
		stopButtonLayer.strokeColor = nil

		foregroundCircleLayer.strokeColor = collection.progressColors.foreground.cgColor
		backgroundCircleLayer.strokeColor = collection.progressColors.background.cgColor

		stopButtonLayer.fillColor = collection.tintColor.cgColor
	}

	@objc private func cancel() {
		if let progress = progress, progress.isCancellable, !progress.isCancelled {
			progress.cancel()
		}
	}

	private func update() {
		if !Thread.isMainThread {
			OnMainThread {
				self.update()
			}

			return
		}

		if let progress = progress {
			foregroundCircleLayer.isHidden = false

			self.spinning = progress.isIndeterminate || progress.isCancelled

			if progress.isIndeterminate || progress.isCancelled {
				backgroundCircleLayer.isHidden = true
				foregroundCircleLayer.strokeEnd = 0.9
			} else {
				backgroundCircleLayer.isHidden = false
				foregroundCircleLayer.strokeEnd = CGFloat(progress.fractionCompleted)
			}

			stopButtonLayer.isHidden = !progress.isCancellable
		} else {
			foregroundCircleLayer.isHidden = true
			backgroundCircleLayer.isHidden = true
			stopButtonLayer.isHidden = true
		}
	}

	private func adjustFrames() {
		let bounds = self.bounds
		let circleFrame : CGRect = CGRect(x: bounds.origin.x + ((bounds.size.width - dimensions.width) / 2), y: bounds.origin.y + ((bounds.size.height - dimensions.height) / 2), width: dimensions.width, height: dimensions.height)

		backgroundCircleLayer.frame = circleFrame
		foregroundCircleLayer.frame = circleFrame
		stopButtonLayer.frame = circleFrame
	}

	override func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)

		self.adjustFrames()
	}

	override func willMove(toSuperview newSuperview: UIView?) {
		let centerPoint = CGPoint(x: dimensions.width/2, y: dimensions.height/2)
		let radius = (dimensions.width - circleLineWidth) / 2
		let circlePath : CGMutablePath = CGMutablePath()
		let stopPath : CGMutablePath = CGMutablePath()
		let stopButtonSideLength = radius / 2

		circlePath.addArc(center: centerPoint, radius: radius, startAngle: -(CGFloat.pi / 2.0), endAngle: CGFloat.pi * 1.5, clockwise: false)
		stopPath.addRect(CGRect(x: centerPoint.x-(stopButtonSideLength/2), y: centerPoint.y-(stopButtonSideLength/2), width: stopButtonSideLength, height: stopButtonSideLength))

		super.willMove(toSuperview: newSuperview)

		if backgroundCircleLayer.superlayer != self.layer {
			backgroundCircleLayer.path = circlePath
			backgroundCircleLayer.lineWidth = circleLineWidth
			backgroundCircleLayer.lineCap = .round

			self.layer.addSublayer(backgroundCircleLayer)
		}

		if foregroundCircleLayer.superlayer != self.layer {
			foregroundCircleLayer.path = circlePath
			foregroundCircleLayer.lineWidth = circleLineWidth
			foregroundCircleLayer.strokeEnd = 0.6
			foregroundCircleLayer.lineCap = .round

			self.layer.addSublayer(foregroundCircleLayer)
		}

		if stopButtonLayer.superlayer != self.layer {
			stopButtonLayer.path = stopPath

			self.layer.addSublayer(stopButtonLayer)
		}

		self.adjustFrames()
	}

	override var intrinsicContentSize: CGSize {
		return dimensions
	}
}
