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

class ProgressView: UIView, Themeable, CAAnimationDelegate {
	var backgroundCircleLayer : CAShapeLayer = CAShapeLayer()
	var foregroundCircleLayer : CAShapeLayer = CAShapeLayer()
	var stopButtonLayer : CAShapeLayer = CAShapeLayer()

	private let dimensions : CGSize = CGSize(width: 30, height: 30)
	private let circleLineWidth : CGFloat = 3

	private var _observerRegistered : Bool = false
	private var _progress : Progress?
	var progress : Progress? {
		set {
			OCSynchronized(self) {
				if _observerRegistered, let progress = _progress {
					progress.removeObserver(self, forKeyPath: "fractionCompleted")
					progress.removeObserver(self, forKeyPath: "indeterminate")
					progress.removeObserver(self, forKeyPath: "cancelled")
					progress.removeObserver(self, forKeyPath: "finished")

					_observerRegistered = false
				}

				_progress = newValue

				if !_observerRegistered, let progress = newValue {
					progress.addObserver(self, forKeyPath: "fractionCompleted", options: [], context: nil)
					progress.addObserver(self, forKeyPath: "indeterminate", options: [], context: nil)
					progress.addObserver(self, forKeyPath: "cancelled", options: [], context: nil)
					progress.addObserver(self, forKeyPath: "finished", options: [], context: nil)

					_observerRegistered = true
				}

				if Thread.isMainThread {
					CATransaction.begin()
					CATransaction.setDisableActions(true)
					CATransaction.setAnimationDuration(0)
				} else {
					Log.log("Progress not set on main thread")
				}

				self.update()

				if Thread.isMainThread {
					CATransaction.commit()
				}
			}
		}

		get {
			var progress : Progress?

			OCSynchronized(self) {
				progress = _progress
			}

			return progress
		}
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if (object as? Progress) === progress {
			OnMainThread {
				self.update()
			}
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}

	private var spinningAnimationActive : Bool = false

	private var spinning : Bool = false {
		didSet {
			let spinningAnimationKey = "spinningAnimation"

			CATransaction.begin()
			CATransaction.setDisableActions(true)
			CATransaction.setAnimationDuration(0)

			foregroundCircleLayer.animation(forKey: spinningAnimationKey)

			if (spinning != oldValue) || (spinning && oldValue && !spinningAnimationActive) {
				if spinning {
					let spinningAnimation = CABasicAnimation(keyPath: "transform.rotation.z")

					spinningAnimation.toValue = 2 * CGFloat.pi

					spinningAnimation.duration = 1.0
					spinningAnimation.isCumulative = true
					spinningAnimation.repeatCount = MAXFLOAT

					foregroundCircleLayer.add(spinningAnimation, forKey: spinningAnimationKey)

					if window != nil {
						spinningAnimationActive = true
					}
				} else {
					foregroundCircleLayer.removeAnimation(forKey: spinningAnimationKey)
				}
			}

			CATransaction.commit()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		Theme.shared.register(client: self, applyImmediately: true)

		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.cancel)))

		NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

		self.progress = nil
		Theme.shared.unregister(client: self)
	}

	@objc func appDidBecomeActive() {
		spinningAnimationActive = false
		self.update()
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

		if let progress = self.progress {

			self.spinning = progress.isIndeterminate || progress.isCancelled

			if progress.isIndeterminate || progress.isCancelled {
				backgroundCircleLayer.isHidden = true
				foregroundCircleLayer.strokeEnd = 0.9
			} else {
				backgroundCircleLayer.isHidden = false
				if foregroundCircleLayer.strokeEnd > CGFloat(progress.fractionCompleted) {
					CATransaction.begin()
					CATransaction.setDisableActions(true)
					CATransaction.setAnimationDuration(0)

					foregroundCircleLayer.strokeEnd = CGFloat(progress.fractionCompleted)

					CATransaction.commit()
				} else {
					foregroundCircleLayer.strokeEnd = CGFloat(progress.fractionCompleted)
				}
			}

			foregroundCircleLayer.isHidden = false
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

	override func didMoveToWindow() {
		super.didMoveToWindow()

		if window == nil {
			spinningAnimationActive = false
		} else {
			self.update()
		}
	}

	override var intrinsicContentSize: CGSize {
		return dimensions
	}
}
