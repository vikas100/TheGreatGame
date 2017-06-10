//
//  NotificationViewController.swift
//  Notification
//
//  Created by Олег on 10.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import TheGreatKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var homeLabel: UILabel!
    @IBOutlet weak var awayLabel: UILabel!
    
    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var awayBadgeImageView: UIImageView!
    
    let avenue = Images.inSharedCachesDirectory().makeAvenue(forImageSize: CGSize.init(width: 100, height: 100))
    
    var match: Match.Full?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avenue.onStateChange = { [weak self] _ in
            self?.reload(afterImageDownload: true)
        }
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        let push = PushNotification(notification.request.content)!
        guard let match = try? Match.Full(from: push.content) else {
            fault("No match")
            return
        }
        self.match = match
        reload(afterImageDownload: false)
    }
    
    func reload(afterImageDownload: Bool) {
        guard let match = match else {
            fault("No match in reload")
            return
        }
        avenue.prepareItem(at: match.home.badgeURL)
        avenue.prepareItem(at: match.away.badgeURL)
        scoreLabel.text = match.score?.demo_string ?? "-:-"
        homeLabel.text = match.home.shortName
        awayLabel.text = match.away.shortName
        homeBadgeImageView.setImage(avenue.item(at: match.home.badgeURL), afterDownload: afterImageDownload)
        awayBadgeImageView.setImage(avenue.item(at: match.away.badgeURL), afterDownload: afterImageDownload)
    }

}
