//
//  IssuesPresentationAnimator.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 15/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

@objc public class IssuesPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.1
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)

        let finalFrame = transitionContext.initialFrame(for: fromVC!)

        toVC?.view.frame = finalFrame

        transitionContext.containerView.addSubview(toVC!.view)

        let views = toVC!.view.subviews
        var index = 0

        for view in views {
            view.transform = CGAffineTransform(translationX: 0, y: finalFrame.height)

            let delay = 0.0
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext) - delay,
                           delay: delay,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.3,
                           options: [],
                           animations: {
                            view.transform = CGAffineTransform.identity
            }, completion: nil)

            index += 1
        }

        let backgroundColor = toVC?.view.backgroundColor!
        toVC?.view.backgroundColor = backgroundColor?.withAlphaComponent(0)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                       animations: {
                        toVC?.view.backgroundColor = backgroundColor
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}
