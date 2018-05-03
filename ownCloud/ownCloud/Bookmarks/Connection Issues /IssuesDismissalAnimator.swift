//
//  IssuesDismissalAnimator.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 15/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

@objc public class IssuesDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)

        transitionContext.containerView.addSubview(fromVC!.view)

        let initialFrame = transitionContext.initialFrame(for: fromVC!)

        let views = Array(fromVC!.view.subviews.reversed())
        var index = 0

        let step: Double = 0.0

        for view in views.reversed() {
            let delay = step * Double(index)
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext) - delay,
                           delay: delay,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.5,
                           options: [],
                           animations: {
                            view.transform = CGAffineTransform(translationX: 0, y: initialFrame.height)
            }, completion: nil)
            index += 1
        }

        let backgroundColor = fromVC?.view.backgroundColor!

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       animations: {
                        fromVC?.view.backgroundColor = backgroundColor?.withAlphaComponent(0)
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
