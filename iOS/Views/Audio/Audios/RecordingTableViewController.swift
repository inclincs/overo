//
//  RecordingTableViewController.swift
//  Overo
//
//  Created by cnlab on 2021/08/03.
//

import Foundation
import UIKit

class RecordingTableViewController: UITableViewController {
    
    var list: [OVAudioInformation] = []
    
//    var refreshTimer: Timer?
//    let refreshSelector: Selector = #selector(refreshVisibleCells)
    
//    var refreshImageView: UIImageView!
    
    override func viewDidLoad() {
        let refreshControl = UIRefreshControl()
        
        refreshControl.attributedTitle = NSAttributedString(string: "새로고침".localized())
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
//        refreshControl.tintColor = .clear
        
//        refreshImageView = UIImageView(image: UIImage(systemName: "arrow.clockwise"))
//        refreshImageView.center.x = refreshControl.frame.width / 2
//        refreshImageView.frame.size.width = 40
//        refreshImageView.frame.size.height = 40
        
//        refreshControl.addSubview(refreshImageView)
        
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refresh()
    }
    
    @objc func refresh() {
        if let audioInformations = OVAudioInformation.loadAll() {
            list.removeAll()
            list = audioInformations.reversed()
            
            tableView.reloadData()
        }
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let refreshControl = refreshControl else {
//            return
//        }
//
//        let distance = max(0.0, -refreshControl.frame.origin.y)
//
//        refreshImageView.center.y = distance / 2
//
//        let transform = CGAffineTransform(rotationAngle: CGFloat(distance / 30))
//        refreshImageView.transform = transform
//    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let refreshControl = refreshControl, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }
    
//    func startPeriodicalRefresh() {
//        if refreshTimer == nil {
//            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0,
//                                                target: self,
//                                                selector: refreshSelector,
//                                                userInfo: nil,
//                                                repeats: true)
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        stopPeriodicalRefresh()
//    }
//
//    func stopPeriodicalRefresh() {
//        refreshTimer?.invalidate()
//        refreshTimer = nil
//    }
//
//    @objc func refreshVisibleCells() {
//        tableView.reloadData()
//    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! RecordingTableViewCell
        
        let ai: OVAudioInformation = list[indexPath.row]
        
        let audio: OVAudio = ai.audio
        
        cell.name.text = audio.name
        cell.duration.text = audio.getDurationTimeFormat()
        cell.date.text = audio.date
        cell.isProtected.text = ai.protectionDegree
        
        cell.isEnabled = !OVRealtimeProcessing.contains(audioId: ai.audio.id)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? RecordingTableViewCell else {
            return
        }
        
        if cell.isEnabled == false {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        guard let detailViewController = storyboard?.instantiateViewController(identifier: "detailViewController") as? DetailViewController else {
            return
        }
        
        let ai = list[indexPath.row]
        let newAi = OVAudioInformation.load(ai.audio.id)
        
        detailViewController.audioInformation = newAi
        
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Edit") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
//            guard let postprocessingViewController = storyboard?.instantiateViewController(identifier: "postprocessingViewController") as? PostprocessingViewController else {
//                return
//            }
            
//            stopPeriodicalRefresh()
//            postprocessingViewController.audioInformation = list[indexPath.row]
            
//            navigationController?.pushViewController(postprocessingViewController, animated: true)
            
            print("edit clicked")
            success(true)
        }
        
        edit.backgroundColor = .systemIndigo
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
            let ai: OVAudioInformation = self.list[indexPath.row]
            
            ai.delete()
            
            self.list.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            success(true)
        }
        
        return UISwipeActionsConfiguration(actions:[delete])
    }
}
