//
//  MenuViewCtrl.swift
//  BCPlayer_Example
//
//  Created by mtAdmin on 2021/2/2.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class MenuVC: UITableViewController {
    
    enum Item: String, CaseIterable {
        case basic = "基础"
        case feed  = "流"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "菜单"
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Item.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = Item.allCases[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Item.allCases[indexPath.row] {
        case .basic:
            navigationController?.pushViewController(BasicVC(), animated: true)
        case .feed:
            navigationController?.pushViewController(BasicVC(), animated: true)
        }
    }
}
