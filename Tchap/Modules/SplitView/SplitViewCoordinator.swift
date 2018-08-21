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

final class SplitViewCoordinator: SplitViewCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootRouter: RootRouterType
    private let session: MXSession
    
    private let splitViewController: UISplitViewController
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: RootRouterType, session: MXSession) {
        self.rootRouter = router
        self.session = session
        self.splitViewController = UISplitViewController()
    }
    
    // MARK: - Public methods
    
    func start() {
        let segmentedViewCoordinator = SegmentedViewCoordinator(session: self.session)
        
        self.splitViewController.viewControllers = [segmentedViewCoordinator.toPresentable()]
        self.splitViewController.preferredDisplayMode = .allVisible
        
        segmentedViewCoordinator.start()
        
        self.rootRouter.setRootModule(self.splitViewController)
        
        self.add(childCoordinator: segmentedViewCoordinator)
    }        
    
    func toPresentable() -> UIViewController {
        return self.splitViewController
    }
}

// MARK: - UISplitViewControllerDelegate
extension SplitViewCoordinator: UISplitViewControllerDelegate {
    
    // TODO: Implement UISplitViewControllerDelegate methods
}
