//
//  AppController.swift
//  DiveLane
//
//  Created by Anton Grigorev on 08/09/2018.
//  Copyright © 2018 Matter Inc. All rights reserved.
//

import UIKit
import Web3swift
import BigInt

public class AppController {

    private let etherscanService = ContractsService()
    private let walletsService = WalletsService()
    //private let routerEIP681 = EIP681Router()
    private let userDefaultKeys = UserDefaultKeys()
    private let tokensService = TokensService()
    private let networksService = NetworksService()

    convenience init(
            window: UIWindow,
            url: URL?) {
        self.init()
        start(in: window, url: url)
    }

    private func start(in window: UIWindow, url: URL?) {
        if let url = url {
            navigateViaDeepLink(url: url, in: window)
        } else {
            startAsUsual(in: window)
        }
    }
    
    public func onboardingController() -> UINavigationController {
        let vc = OnboardingViewController()
        let nav = navigationController(withTitle: "Onboarding",
                                       withImage: nil,
                                       withController: vc,
                                       tag: 0)
        return nav
    }
    
    public func acceptChequeController(cheque: PlasmaCode) -> UINavigationController {
        let vc = AcceptChequeController(cheque: cheque)
        let nav = navigationController(withTitle: "Accept cheque",
                                       withImage: nil,
                                       withController: vc,
                                       tag: 0)
        return nav
    }
    
//    public func deeplinkPayController(cheque: BuffiCode) -> UINavigationController {
//        let vc = DeeplinkPayViewController(cheque: cheque)
//        let nav = navigationController(withTitle: "Pay",
//                                       withImage: nil,
//                                       withController: vc,
//                                       tag: 0)
//        return nav
//    }
    
    public func enterPincodeController() -> UINavigationController {
        let vc = EnterPincodeViewController(for: EnterPincodeCases.enterWallet, data: Data())
        let nav = navigationController(withTitle: "Enter Pincode",
                                       withImage: nil,
                                       withController: vc,
                                       tag: 0)
        return nav
    }
    
//    public func walletCreationVC() -> UINavigationController {
//        let vc = WalletCreationAnimationViewController()
//        let nav = navigationController(withTitle: "Creating wallet",
//                                       withImage: nil,
//                                       withController: vc,
//                                       tag: 0)
//        return nav
//    }

//    public func addWalletController() -> UINavigationController {
//        let vc = AddWalletViewController(isNavigationBarNeeded: false)
//        let nav = navigationController(withTitle: "Add Wallet",
//                                       withImage: nil,
//                                       withController: vc,
//                                       tag: 0)
//        return nav
//    }

    @objc public func goToApp() -> UINavigationController {
//    public func goToApp() -> SWRevealViewController {
//        let frontController:UINavigationController
//        let rearController:UINavigationController
//        let revealController = SWRevealViewController()
//        var mainRevealController = SWRevealViewController()
        
        let nav = UINavigationController()
        let tabs = TabBarController()
//        let nav0 = navigationController(withTitle: "Shop",
//                                        withImage: UIImage(named: "shopping-cart"),
//                                        withController: ShopViewController(nibName: nil, bundle: nil),
//                                        tag: 0)
        let nav1 = navigationController(withTitle: "Wallet",
                                        withImage: UIImage(named: "wallet"),
                                        withController: WalletViewController(nibName: nil, bundle: nil),
                                        tag: 1)
        let nav2 = navigationController(withTitle: "Transactions",
                                        withImage: UIImage(named: "list"),
                                        withController: TransactionsHistoryViewController(nibName: nil, bundle: nil),
                                        tag: 2)
        let nav3 = navigationController(withTitle: "Contacts",
                                        withImage: UIImage(named: "user_male"),
                                        withController: ContactsViewController(nibName: nil, bundle: nil),
                                        tag: 3)
//        let nav2 = navigationController(withTitle: "Transactions History",
//                                        withImage: UIImage(named: "transactions_gray"),
//                                        withController: TransactionsHistoryViewController(),
//                                        tag: 2)
//        let nav4 = navigationController(withTitle: "Settings",
//                                        withImage: UIImage(named: "settings_white"),
//                                        withController: SettingsViewController(nibName: nil, bundle: nil),
//                                        tag: 4)
//        let nav3 = navigationController(withTitle: "Contacts",
//                                        withImage: UIImage(named: "list"),
//                                        withController: ContactsViewController(nibName: nil, bundle: nil),
//                                        tag: 3)
        tabs.tabBar.barTintColor = Colors.background
        tabs.tabBar.tintColor = Colors.mainBlue
        tabs.tabBar.unselectedItemTintColor = Colors.otherLightGray
        
        tabs.viewControllers = [nav1, nav2, nav3]
        
        nav.viewControllers = [tabs]
        nav.setNavigationBarHidden(true, animated: false)
//        frontController = nav
//        rearController = UINavigationController(rootViewController: SettingsViewController(nibName: nil, bundle: nil))
        
//        revealController.frontViewController = frontController
//        revealController.rearViewController = rearController
//        revealController.delegate = nav as? SWRevealViewControllerDelegate
//        revealController.rearViewRevealWidth = UIScreen.main.bounds.width * 0.85
//        mainRevealController = revealController
//
//        return mainRevealController
        return nav
    }
    
    public func initPreparations(for wallet: Wallet, on network: Web3Network) {
        let group = DispatchGroup()
        
        let defaultNetworksAdded = userDefaultKeys.areDefaultNetworksAdded()
        let tokensDownloaded = userDefaultKeys.areTokensDownloaded()
        let etherAdded = userDefaultKeys.isEtherAdded(for: wallet)
        let franklinAdded = userDefaultKeys.isFranklinAdded(for: wallet)
        let daiAdded = userDefaultKeys.isDaiAdded(for: wallet)
        let xdaiAdded = userDefaultKeys.isXDaiAdded(for: wallet)
        let buffAdded = userDefaultKeys.isBuffAdded(for: wallet)
        
        CurrentWallet.currentWallet = wallet
        CurrentNetwork.currentNetwork = network
        
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !defaultNetworksAdded {
                do {
                    try self.addDefaultNetworks()
                    group.leave()
                } catch let error {
                    fatalError("Can't add networks - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !tokensDownloaded {
                do {
                    try self.tokensService.downloadAllAvailableTokensIfNeeded()
                    self.userDefaultKeys.setTokensDownloaded()
                    group.leave()
                } catch let error {
                    fatalError("Can't download tokens - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !franklinAdded {
                do {
                    try self.addFranklin(for: wallet)
                    group.leave()
                } catch let error {
                    fatalError("Can't add ether token - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !xdaiAdded {
                do {
                    try self.addXDai(for: wallet)
                    group.leave()
                } catch let error {
                    fatalError("Can't add ether token - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !etherAdded {
                do {
                    try self.addEther(for: wallet)
                    group.leave()
                } catch let error {
                    fatalError("Can't add ether token - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !daiAdded {
                do {
                    try self.addDai(for: wallet)
                    group.leave()
                } catch let error {
                    fatalError("Can't add ether token - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global().async { [unowned self] in
            if !buffAdded {
                do {
                    try self.addBuff(for: wallet)
                    group.leave()
                } catch let error {
                    fatalError("Can't add ether token - \(String(describing: error))")
                }
            } else {
                group.leave()
            }
        }
        group.enter()
        if let token = try? wallet.getSelectedToken(network: network) {
            CurrentToken.currentToken = token
            group.leave()
        } else {
            CurrentToken.currentToken = ERC20Token(franklin: true)
            group.leave()
        }
        group.wait()
    }
    
    private func startAsUsual(in window: UIWindow) {
        var startViewController: UIViewController
        
        let selectedNetwork: Web3Network
        if let sn = try? self.networksService.getSelectedNetwork() {
            selectedNetwork = sn
        } else {
            let mainnet = MainnetNetwork()
            //let xdai = Web3Network(id: 100, name: "xDai")
            selectedNetwork = mainnet
        }
        
        if let selectedWallet = CurrentWallet.currentWallet {
            self.initPreparations(for: selectedWallet, on: selectedNetwork)
            if self.userDefaultKeys.isPincodeExists() {
                startViewController = self.enterPincodeController()
            } else {
                startViewController = self.goToApp()
            }
            self.createRootViewController(startViewController, in: window)
        } else {
            startViewController = self.onboardingController()
            self.createRootViewController(startViewController, in: window)
        }
    }
    
    private func createRootViewController(_ vc: UIViewController, in window: UIWindow) {
        DispatchQueue.main.async {
            vc.view.backgroundColor = Colors.background
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }
    }
    
    public func addDefaultNetworks() throws {
        let defaultNets = [MainnetNetwork(), RinkebyNetwork(), RopstenNetwork(), XDaiNetwork()]
        do {
            for network in defaultNets {
                try network.save()
            }
            self.userDefaultKeys.setDefaultNetworksAdded()
        } catch let error {
            throw error
        }
    }
    
    public func addXDai(for wallet: Wallet) throws {
        let xdai = ERC20Token(xdai: true)
        
        do {
            try wallet.add(token: xdai,
                           network: XDaiNetwork())
        } catch let error {
            throw error
        }
        self.userDefaultKeys.setXDaiAdded(for: wallet)
    }
    
    public func addBuff(for wallet: Wallet) throws {
        let buff = ERC20Token(buff: true)
        
        do {
            try wallet.add(token: buff,
                           network: XDaiNetwork())
        } catch let error {
            throw error
        }
        self.userDefaultKeys.setBuffAdded(for: wallet)
    }
    
    public func addEther(for wallet: Wallet, network: Web3Network) throws {
        let ether = ERC20Token(ether: true)
        do {
            try wallet.add(token: ether,
                           network: network)
        } catch let error {
            throw error
        }
        self.userDefaultKeys.setEtherAdded(for: wallet)
    }
    
    public func addEther(for wallet: Wallet) throws {
        let ether = ERC20Token(ether: true)
        let networks = networksService.getAllNetworks()
        for network in networks where network != XDaiNetwork() {
            do {
                if let balance = try? wallet.getETHbalance(web3instance: Web3.new(network.endpoint)) {
                    print(balance)
                    try wallet.add(token: ether,
                                   network: network)
                }
            } catch let error {
                throw error
            }
        }
        self.userDefaultKeys.setEtherAdded(for: wallet)
    }
    
    public func addFranklin(for wallet: Wallet) throws {
        let franklin = ERC20Token(franklin: true)
        
        do {
            try wallet.add(token: franklin,
                           network: MainnetNetwork())
            try wallet.add(token: franklin,
                           network: RinkebyNetwork())
        } catch let error {
            throw error
        }
        CurrentToken.currentToken = franklin
        self.userDefaultKeys.setFranklinAdded(for: wallet)
    }
    
    public func addDai(for wallet: Wallet) throws {
        let dai = ERC20Token(dai: true)
        do {
            try wallet.add(token: dai,
                           network: MainnetNetwork())
            try wallet.add(token: dai,
                           network: RinkebyNetwork())
            try wallet.add(token: dai,
                           network: RopstenNetwork())
        } catch let error {
            throw error
        }
        self.userDefaultKeys.setDaiAdded(for: wallet)
    }
    
    //buffishop:0x4fd693f57e63714591a07a73a4d7ad84e5ccde10?amount=2&uint256=21214124
    private func navigateViaDeepLink(url: URL, in window: UIWindow) {
        if url.absoluteString.hasPrefix("ethereum:") {

//            guard let parsed = Web3.EIP681CodeParser.parse(url.absoluteString) else { return }
//            switch parsed.isPayRequest {
//            case false:
//                //Custom transaction
//                routerEIP681.sendCustomTransaction(parsed: parsed, usingWindow: window)
//            case true:
//                //Regular sending of ETH
//                routerEIP681.sendETHTransaction(parsed: parsed, usingWindow: window)
//            }
        } else if url.absoluteString.hasPrefix("plasma:") {
            if let parsed = PlasmaParser.parse(url.absoluteString) {
                let vc = self.acceptChequeController(cheque: parsed)
                self.createRootViewController(vc, in: window)
            } else {
                startAsUsual(in: window)
            }
        }
//        else if url.absoluteString.hasPrefix("buffishop:") {
//            if let parsed = BuffiParser.parse(url.absoluteString) {
//                let vc = self.deeplinkPayController(cheque: parsed)
//                  self.createRootViewController(vc, in: window)
//            } else {
//                startAsUsual(in: window)
//            }
//        }
    }
}
