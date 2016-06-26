//
//  SDCSignInViewController.swift
//  Drivecast
//
//  Created by Marc Rollin on 10/15/15.
//  Copyright © 2015 Safecast. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SpinKit
import SnapKit

class SDCSignInViewController: UIViewController {

    // ViewModel handling all logic
    let viewModel = SDCSignInViewModel()
    
    // Main screen to be shown after authentication
    var menuViewController: UITabBarController?
    
    // Activity monitor spinner
    let activityMonitor:RTSpinKitView = RTSpinKitView(style: .StyleBounce,
        color: UIColor(named: .Main).colorWithAlphaComponent(0.1))
    
    // Sign in action
    var signInCocoaAction: CocoaAction!
    
    // IB variables
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var dotImageView: UIImageView!
    @IBOutlet var signInFormView: UIView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var emailUnderlineView: UIView!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var passwordUnderlineView: UIView!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var explanationTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureView()
        configureConstraints()
        configureTabBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Check authentication everytime the screen appears
        viewModel.checkAuthentication()
    }
}

// MARK - UIView
extension SDCSignInViewController {
    
    // Center icons on the tabbar and remove titles
    func configureTabBar() {
        menuViewController = StoryboardScene.Main.instantiateMenu()
        
        menuViewController?.delegate    = self
        navigationController?.delegate  = self
        
        if let items = menuViewController?.tabBar.items {
            for item in items {
                item.title          = ""
                item.imageInsets    = UIEdgeInsetsMake(6, 0, -6, 0)
            }
        }
    }
    
    func configureView() {
        let textColor = UIColor(named: .Text)
        
        view.backgroundColor            = UIColor(named: .Background)
        emailTextField.textColor        = textColor
        passwordTextField.textColor     = textColor
        explanationTextView.textColor   = textColor
        signInButton.isRounded          = true
        
        view.addSubview(activityMonitor)
        
        resetView()
    }
    
    // Called uppon view appearing
    func resetView() {
        logoImageView.alpha     = 1.0
        dotImageView.alpha      = 1.0
        signInFormView.alpha    = 0.0
        
        let color = UIColor(named: .Main).colorWithAlphaComponent(0.2)
        
        emailTextField.delegate                 = self
        emailUnderlineView.backgroundColor      = color
        passwordTextField.delegate              = self
        passwordUnderlineView.backgroundColor   = color
        
        activityMonitor.startAnimating()
    }
    
    func configureConstraints() {
        activityMonitor.snp_makeConstraints { make in
            make.center.equalTo(dotImageView)
        }
        
        logoImageView.snp_removeConstraints()
        logoImageView.snp_makeConstraints { make in
            make.bottom.equalTo(signInFormView.snp_top).offset(-40)
        }
        
        resetConstraints()
    }
    
    // Called uppon view appearing
    func resetConstraints() {
        signInFormView.snp_removeConstraints()
        signInFormView.snp_makeConstraints { make in
            make.top.equalTo(dotImageView.snp_top)
        }
    }
    
    // Display the sign in form
    func presentSignInForm() {
        activityMonitor.stopAnimating()
        
        emailTextField.enabled      = true
        passwordTextField.enabled   = true
        
        UIView.animateWithDuration(0.5, delay: 0.0,
            options: [.CurveEaseInOut, .TransitionCrossDissolve],
            animations: {
                self.signInFormView.snp_removeConstraints()
                self.signInFormView.snp_makeConstraints { make in
                    make.centerY.equalTo(self.dotImageView).offset(40)
                }
                
                self.signInFormView.alpha   = 1.0
                self.dotImageView.alpha     = 0.0
                
                self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // Dismiss the sign in form
    func dismissSignInForm() {
        // Dismiss the keyboard and resign first responder
        view.endEditing(true)
        
        // Dismiss the form
        UIView.animateWithDuration(0.5, delay: 0.0,
            options: [.CurveEaseInOut],
            animations: {
                self.resetView()
                self.resetConstraints()
                
                self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // If the user authenticates, display the tabbar controller
    func presentMenu() {
        activityMonitor.stopAnimating()
        
        UIView.animateWithDuration(0.5, delay: 0.0,
            options: [.CurveEaseInOut],
            animations: {
                self.logoImageView.alpha    = 0.1
                self.dotImageView.alpha     = 0.1
            }, completion: { _ in
                self.emailTextField.text    = ""
                self.passwordTextField.text = ""
                
                if let menuViewController = self.menuViewController {
                    self.navigationController?.pushViewController(menuViewController, animated: true)
                }
        })
    }
    
    // Animates the sign in button based if enabled or disabled
    func animateSignInButton(enabled: Bool) {
        UIView.animateWithDuration(0.3, delay: 0.0,
            options: [.CurveEaseInOut],
            animations: {
                self.signInButton.backgroundColor   = UIColor(named: .Main)
                    .colorWithAlphaComponent(enabled ? 0.9 : 0.4)
            }, completion: nil)
    }
}

// MARK - Signal Bindings
extension SDCSignInViewController {
    
    func bindViewModel() {
        // Forwarding inputs to the viewModel
        viewModel.emailText             <~ emailTextField.rac_text
        viewModel.passwordText          <~ passwordTextField.rac_text

        // Updating UI elements
        emailTextField.rac_enabled      <~ viewModel.emailTextEnabled
        passwordTextField.rac_enabled   <~ viewModel.passwordTextEnabled
        signInButton.rac_enabled        <~ viewModel.signInButtonEnabled
        
        // Visually enable/disable the signInButton
        viewModel.signInButtonEnabled.producer
            .startWithNext { enabled in
                self.animateSignInButton(enabled)
                self.passwordTextField.returnKeyType = enabled ? .Go : .Done
        }
        
        // Binding the signIn action
        signInCocoaAction = CocoaAction(viewModel.signInAction!, input:nil)
        signInButton.addTarget(signInCocoaAction, action: CocoaAction.selector, forControlEvents: UIControlEvents.TouchUpInside)

        // Display an error message if sign in fails
        viewModel.signInAction?.errors
            .observeNext { error in
                var message: String = ""
                
                switch error {
                case SDCSafecastAPI.UserError.APIKeyCouldNotBeFound(let reason):
                    message = reason
                case SDCSafecastAPI.UserError.UserIdCouldNotBeFound(let reason):
                    message = reason
                case SDCSafecastAPI.UserError.Network(let reason):
                    message = reason
                }
                
                let alertController = UIAlertController(title: NSLocalizedString("Could not sign in", comment: ""), message: message, preferredStyle: .Alert)
                let okAction        = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: UIAlertActionStyle.Default) { handler in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                
                alertController.addAction(okAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        // Presenting the menu if user is authenticated
        viewModel.userIsAuthenticated.producer
            .startWithNext { authenticated in
                if authenticated {
                    self.presentMenu()
                }
        }
        
        // Presenting/dismissing the signInForm
        viewModel.signInFormIsVisible.producer
            .skip(1)
            .startWithNext { visible in
                if visible {
                    self.presentSignInForm()
                } else {
                    self.dismissSignInForm()
                }
        }
    }
}

// MARK - UITextFieldDelegate
extension SDCSignInViewController: UITextFieldDelegate {
    
    private func updateTextFieldUndeline(textField: UITextField, alpha: CGFloat) {
        UIView.animateWithDuration(0.3, delay: 0.0,
            options: [.CurveEaseInOut],
            animations: {
                if textField == self.emailTextField {
                    self.emailUnderlineView.backgroundColor = self.emailUnderlineView.backgroundColor?.colorWithAlphaComponent(alpha)
                } else {
                    self.passwordUnderlineView.backgroundColor = self.passwordUnderlineView.backgroundColor?.colorWithAlphaComponent(alpha)
                }
            } , completion: nil)
    }
    
    internal func textFieldDidBeginEditing(textField: UITextField) {
        updateTextFieldUndeline(textField, alpha: 0.6)
    }

    internal func textFieldDidEndEditing(textField: UITextField) {
        updateTextFieldUndeline(textField, alpha: 0.2)
    }

    internal func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            passwordTextField.resignFirstResponder()
            
            if viewModel.signInButtonEnabled.value {
                signInButton.sendActionsForControlEvents(.TouchUpInside)
            }
        default:
            break
        }
        
        return true
    }
}

// MARK - UITabBarControllerDelegate
extension SDCSignInViewController: UITabBarControllerDelegate {
    
    internal func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        guard tabBarController.viewControllers?.indexOf(viewController)
            == SDCConfiguration.UI.TabBarMenu.Record else {
            return true
        }
        
        let recordController = StoryboardScene.Main.instantiateRecord()
        
        tabBarController.presentViewController(recordController, animated: true, completion: nil)
        
        return false
    }
}

// MARK - UINavigationControllerDelegate
extension SDCSignInViewController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController,
        animationControllerForOperation operation: UINavigationControllerOperation,
        fromViewController fromVC: UIViewController,
        toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return SDCCircleTransitionAnimator()
    }
}
