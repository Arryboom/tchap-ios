/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// `RootRouter` is a concrete implementation of RootRouterType.
final class RootRouter: RootRouterType {
    
    // MARK: - Constants
    
    // `rootViewController` animation constants
    private enum RootViewControllerUpdateAnimation {
        static let duration: TimeInterval = 0.5
        static let options: UIViewAnimationOptions = .transitionCrossDissolve
    }
    
    // MARK: - Properties
    
    let window: UIWindow
    
    /// The root view controller currently presented    
    var rootViewController: UIViewController? {
        return self.window.rootViewController
    }
    
    // MARK: - Setup
    
    init(window: UIWindow) {
        self.window = window
    }
    
    // MARK: - Public methods
    
    func setRootModule(_ module: Presentable) {
        self.updateRootViewController(rootViewController: module.toPresentable(), animated: false, completion: nil)
        self.window.makeKeyAndVisible()
    }
    
    func dismissModule(animated: Bool, completion: (() -> Void)?) {
        self.updateRootViewController(rootViewController: nil, animated: animated, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func updateRootViewController(rootViewController: UIViewController?, animated: Bool, completion: (() -> Void)?) {
        
        if animated {
            UIView.transition(with: window, duration: RootViewControllerUpdateAnimation.duration, options: RootViewControllerUpdateAnimation.options, animations: {
                let oldState: Bool = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                self.window.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            }, completion: { (finished: Bool) -> Void in
                completion?()
            })
        } else {
            self.window.rootViewController = rootViewController
            completion?()
        }
    }
}
