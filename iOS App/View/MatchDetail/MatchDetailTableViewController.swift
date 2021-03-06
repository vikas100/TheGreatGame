//
//  MatchDetailTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues

struct MatchDetailPreLoaded {
    
    var home: Match.Team?
    var score: Match.Score?
    var away: Match.Team?
    var stageTitle: String?
    var location: String?
    var date: Date?
    
}

extension MatchProtocol {
    
    func preloaded() -> MatchDetailPreLoaded {
        return MatchDetailPreLoaded(home: self.home, score: self.score, away: self.away, stageTitle: nil, location: nil, date: self.date)
    }
    
}

extension Match.Full {
    
    func preloaded() -> MatchDetailPreLoaded {
        return MatchDetailPreLoaded(home: self.home, score: self.score, away: self.away, stageTitle: self.stageTitle, location: self.location, date: self.date)
    }
    
}

extension Match.Compact {
    
    func preloaded() -> MatchDetailPreLoaded {
        return MatchDetailPreLoaded(home: self.home, score: self.score, away: self.away, stageTitle: nil, location: self.location, date: self.date)
    }
    
}

class MatchDetailTableViewController: TableViewController {
    
    static let dateFormatter = DateFormatter() <- {
        $0.timeStyle = .short
        $0.setLocalizedDateFormatFromTemplate("MMMMd" + $0.dateFormat)
    }

    // MARK: - Outlets
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: - Data source
    var match: Match.Full?
    
    // MARK: - Injections
    var preloadedMatch: MatchDetailPreLoaded?
    var makeAvenue: (CGSize) -> Avenue<URL, UIImage> = runtimeInject
    var makeTeamDetailVC: (Match.Team) -> UIViewController = runtimeInject
    var isFavorite: () -> Bool = runtimeInject
    var updateFavorite: (Bool) -> () = runtimeInject
    
    // MARK: - Services
    var badgeAvenue: Avenue<URL, UIImage>!
    var flagAvenue: Avenue<URL, UIImage>!
    
    // MARK: - Connections
    var reactiveTeam: Reactive<Match.Full>!
    //var shouldReloadData: MainThreadSubscribe<Void>?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.badgeAvenue = makeAvenue(CGSize(width: 80, height: 80))
        self.flagAvenue = makeAvenue(CGSize(width: 30, height: 15))

        configure(tableView)
        configure(navigationItem)
        configure(favoriteButton: favoriteButton)
        
        self.subscribe()
        self.reactiveTeam.update.fire(errorDelegate: self)
    }
    
    func subscribe() {
        reactiveTeam.didUpdate.subscribe(self, with: MatchDetailTableViewController.setup)
        //shouldReloadData?.subscribe(self, with: MatchDetailTableViewController.reload)
        //shouldReloadData = nil
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let favoriteAction = UIPreviewAction(title: isFavorite() ? "Unfavorite" : "Favorite", style: .default) { (action, controller) in
            if let controller = controller as? MatchDetailTableViewController {
                controller.updateFavorite(!controller.isFavorite())
            } else {
                fault("Wrong VC")
            }
        }
        return [favoriteAction]
    }
    
    func setup(with match: Match.Full) {
        self.match = match
        self.tableView.reloadData()
        self.configure(navigationItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        reload()
    }
    
    func reload() {
        reactiveTeam.update.fire(activityIndicator: pullToRefreshIndicator, errorDelegate: self)
    }

    @IBAction func didPressFavoriteButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        updateFavorite(sender.isSelected)
    }
    
    // MARK: - Table view data source
    
    let matchDetailSection = 0
    let eventsSection = 1

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case matchDetailSection:
            return 1
        case eventsSection:
            return match?.events.count ?? 0
        default:
            fatalError("Undefined section \(section)")
        }
    }
    
    let matchDetailReuseIdentifier = "MatchDetailMatch"
    let matchEventReuseIdentifier = "MatchDetailEvent"
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            switch indexPath.section {
            case matchDetailSection:
                return tableView.dequeueReusableCell(withIdentifier: matchDetailReuseIdentifier, for: indexPath)
            case eventsSection:
                return tableView.dequeueReusableCell(withIdentifier: matchEventReuseIdentifier, for: indexPath)
            default:
                fatalError("Undefined section")
            }
        }()
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch cell {
        case let matchDetail as MatchDetailTableViewCell:
            configureMatchDetailCell(matchDetail, forRowAt: indexPath)
        case let event as MatchEventTableViewCell:
            configureEventCell(event, forRowAt: indexPath)
        default:
            fault("Such cell is not registered \(type(of: cell))")
        }
    }
    
    func configureMatchDetailCell(_ cell: MatchDetailTableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
        if let match = match {
                        
            cell.homeTeamNameLabel.text = match.home.name
            cell.scoreLabel.text = match.scoreOrPenaltyString()
            cell.awayTeamLabel.text = match.away.name
            cell.stageTitleLabel.text = match.stageTitle
            cell.dateLabel.text = MatchDetailTableViewController.dateFormatter.string(from: match.date)
            
            if match.penalties != nil {
                cell.penaltyLabel.isHidden = false
                var text = "(\(match.onlyMainTimeScoreString()))"
                if match.isEnded {
                    text.append(", FT")
                }
                cell.minuteLabel.text = text
            } else {
                cell.penaltyLabel.isHidden = true
                cell.minuteLabel.text = match.minuteOrStateString()
            }
            
            flagAvenue.register(cell.homeFlagImageView, for: match.home.badges.flag)
            flagAvenue.register(cell.awayFlagImageView, for: match.away.badges.flag)
            
            badgeAvenue.register(cell.homeBadgeImageView, for: match.home.badges.large)
            badgeAvenue.register(cell.awayBadgeImageView, for: match.away.badges.large)
            
            cell.onHomeBadgeTap = { [unowned self] in
                let vc = self.makeTeamDetailVC(match.home)
                self.show(vc, sender: self)
            }
            cell.onAwayBadgeTap = { [unowned self] in
                let vc = self.makeTeamDetailVC(match.away)
                self.show(vc, sender: self)
            }
            
        } else if let preloaded = preloadedMatch {
            if let home = preloaded.home {
                flagAvenue.register(cell.homeFlagImageView, for: home.badges.flag)
                badgeAvenue.register(cell.homeBadgeImageView, for: home.badges.large)
            }
            if let away = preloaded.away {
                flagAvenue.register(cell.awayFlagImageView, for: away.badges.flag)
                badgeAvenue.register(cell.awayBadgeImageView, for: away.badges.large)
            }
            cell.homeTeamNameLabel.text = preloaded.home?.name
            cell.scoreLabel.text = preloaded.score?.string ?? "-:-"
            cell.awayTeamLabel.text = preloaded.away?.name
            cell.stageTitleLabel.text = preloaded.stageTitle ?? "Stage"
            cell.minuteLabel.text = nil
            cell.dateLabel.text = preloaded.date.map(MatchDetailTableViewController.dateFormatter.string(from:)) ?? "Date"
        }
        cell.scoreLabel.textColor = .black
    }
    
    func configureEventCell(_ cell: MatchEventTableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
        guard let match = match else {
            fault("Match should be existing at this point")
            return
        }
        let eventViewModel = match.events.reversed()[indexPath.row].viewModel(in: match)
        cell.setText(eventViewModel.title, on: cell.eventTitleLabel)
        cell.setText(eventViewModel.text, on: cell.eventTextLabel)
        cell.minuteLabel.text = eventViewModel.minute
    }

}

extension MatchDetailTableViewController {
    
    // MARK: - Configurations
    
    fileprivate func configure(favoriteButton: UIButton) {
        favoriteButton.isSelected = isFavorite()
    }
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView <- {
            $0.register(UINib.init(nibName: "MatchDetailTableViewCell", bundle: nil), forCellReuseIdentifier: matchDetailReuseIdentifier)
            $0.register(UINib.init(nibName: "MatchEventTableViewCell", bundle: nil), forCellReuseIdentifier: matchEventReuseIdentifier)
            $0.estimatedRowHeight = 70
            $0.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    fileprivate func configure(_ navigationItem: UINavigationItem) {
        navigationItem.title = match?.title ?? preloadedMatch?.title
    }
    
}

extension MatchProtocol {
    
    fileprivate var title: String {
        return "\(home.shortName) : \(away.shortName)"
    }
    
}

extension MatchDetailPreLoaded {
    
    fileprivate var title: String {
        return "\(home?.shortName ?? "") : \(away?.shortName ?? "")"
    }
    
}
