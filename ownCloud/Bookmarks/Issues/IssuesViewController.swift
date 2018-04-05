//
//  IssueViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

enum IssueButtonStyle {
    case plain
    case approve
    case cancel
    case custom(backgroundColor: UIColor)
}

struct IssueButton {
    let title: String
    let type: IssueButtonStyle
    let action: () -> Void
}

class IssuesViewController: UIViewController {

    var tableView: UITableView?
    private var bottomContainer: UIStackView?
    var headerTitle: String?
    var buttons:[IssueButton]?
    private var tableHeighConstraint: NSLayoutConstraint?
    private var modalPresentationVC: UIViewControllerTransitioningDelegate?

    init(buttons: [IssueButton]? = nil, title: String) {
        super.init(nibName: nil, bundle: nil)
        self.headerTitle = title
        self.buttons = buttons
        setupTransitions()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        setupTableView()
        setupBottomContainer()
        tableView?.delegate = self
        self.addButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableHeighConstraint?.constant =  self.tableView!.contentSize.height
    }

    private func setupTableView() {
        tableView = UITableView()
        tableView?.layer.cornerRadius = 10
        tableView?.separatorInset = .zero
        tableView?.bounces = false
        tableView?.backgroundColor = .green
        tableView?.rowHeight = UITableViewAutomaticDimension
    }

    private func setupBottomContainer() {
        bottomContainer = UIStackView()
        bottomContainer?.alignment = .fill
        bottomContainer?.axis = .horizontal
        bottomContainer?.distribution = .fillEqually
        bottomContainer?.spacing = 20
    }

    func addButtons() {
        if let buttonsToAdd = buttons {
            var tag = 0
            buttonsToAdd.forEach({
                let button = UIButton(type: .system)
                var color: UIColor = .blue
                var backgroundColor: UIColor = .white

                switch $0.type {
                case .approve:
                    backgroundColor = UIColor(hex:0x1AC763)
                    color = UIColor.white
                case .custom(let backColor):
                    backgroundColor = backColor
                default:
                    backgroundColor = .white
                    color = .blue
                }

                button.backgroundColor = backgroundColor
                button.setAttributedTitle(NSAttributedString(string: $0.title, attributes: [
                    .foregroundColor : color,
                    .font : UIFont.systemFont(ofSize: 20, weight: .regular)
                    ]), for: .normal)
                button.setTitle($0.title, for: UIControlState.normal)
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
                button.layer.cornerRadius = 10
                button.tag = tag
                tag += 1
                bottomContainer?.addArrangedSubview(button)
            })
        }
    }

    @objc func buttonPressed(_ button :UIButton) {

        if let buttonPressed: IssueButton = buttons?[button.tag] {
            print("buttonPressed name \(buttonPressed.title)")
            buttonPressed.action()
        }
    }

    private func setupConstraints() {
        bottomContainer?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bottomContainer!)

        bottomContainer?.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        bottomContainer?.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        bottomContainer?.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        bottomContainer?.heightAnchor.constraint(equalToConstant: 50).isActive = true
        bottomContainer?.contentHuggingPriority(for: .vertical)

        tableView?.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView!)

        tableView?.bottomAnchor.constraint(equalTo: bottomContainer!.topAnchor, constant: -20).isActive = true
        tableView?.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
        tableView?.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        tableView?.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        tableHeighConstraint = tableView?.heightAnchor.constraint(equalToConstant: 0)
        tableHeighConstraint?.isActive = true
    }

    private func setupTransitions() {
        self.modalPresentationStyle = .custom
        let transitioningDLG = IssuesTransitioningDelegate()
        self.modalPresentationVC = transitioningDLG
        self.transitioningDelegate = transitioningDLG
    }
}

extension IssuesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = headerTitle
        cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

}

internal class IssuesTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return IssuesPresentationAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return IssuesDismissalAnimator()
    }
}
