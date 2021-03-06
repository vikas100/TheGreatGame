//
//  TeamDetailMatchTableViewCell.swift
//  TheGreatGame
//
//  Created by Олег on 05.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import Avenues
import TheGreatKit

class MatchTableViewCell: UITableViewCell {
    
    enum LabelMode {
        case score
        case time
        case date
    }
    
    @IBOutlet weak var homeBadgeImageView: UIImageView!
    @IBOutlet weak var homeTeamNameLabel: UILabel!
    
    var scoreLabelMode: LabelMode = .time {
        didSet {
            switch scoreLabelMode {
            case .score:
                scoreTimeLabel.font = UIFont.preferredFont(forTextStyle: .title3)
                scoreTimeLabel.textColor = .black
            case .time:
                scoreTimeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                scoreTimeLabel.textColor = .darkGray
            case .date:
                scoreTimeLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
                scoreTimeLabel.textColor = .darkGray
            }
        }
    }
    
    @IBOutlet weak var scoreTimeLabel: UILabel! {
        didSet {
            scoreTimeLabel.font = scoreTimeLabel.font.monospacedNumbers()
        }
    }

    @IBOutlet weak var awayTeamNameLabel: UILabel!
    @IBOutlet weak var awayBadgeImageView: UIImageView!
    
    @IBOutlet weak var penaltyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

final class MatchCellFiller : CellFiller {
    
    enum ScoreMode {
        case dateAndTime
        case timeOnly
        
        var labelMode: MatchTableViewCell.LabelMode {
            switch self {
            case .dateAndTime:
                return .date
            case .timeOnly:
                return .time
            }
        }
    }
    
    typealias CellType = MatchTableViewCell
    typealias Content = Match.Compact
    
    let avenue: Avenue<URL, UIImage>
    let isFavorite: (Match.Compact) -> Bool
    let scoreMode: ScoreMode
    
    init(avenue: Avenue<URL, UIImage>,
         scoreMode: ScoreMode,
         isFavorite: @escaping (Match.Compact) -> Bool) {
        self.avenue = avenue
        self.isFavorite = isFavorite
        self.scoreMode = scoreMode
    }
    
    func setup(_ cell: MatchTableViewCell, with match: Match.Compact, forRowAt indexPath: IndexPath) {
        if isFavorite(match) {
            cell.backgroundColor = UIColor(named: .favoriteBackground)
        } else {
            cell.backgroundColor = .white
        }
        cell.scoreTimeLabel.textColor = .black
        cell.scoreTimeLabel.text = scoreMode == .timeOnly ? match.scoreOrTimeString() : match.scoreOrDateString()
        cell.scoreLabelMode = match.score == nil ? scoreMode.labelMode : .score
        cell.homeTeamNameLabel.text = match.home.name
        cell.awayTeamNameLabel.text = match.away.name
        avenue.register(cell.homeBadgeImageView, for: match.home.badges.large)
        avenue.register(cell.awayBadgeImageView, for: match.away.badges.large)
        cell.penaltyLabel.isHidden = (match.penalties == nil)
    }
    
}

