//
//  StockCell.swift
//  Stocks
//
//  Created by Neo Ighodaro on 03/09/2018.
//  Copyright © 2018 TapSharp. All rights reserved.
//

import UIKit

struct Stock: Codable {
    let name: String
    let price: Float
    let percentage: String
}

class StockCell: UITableViewCell {

    var stock: Stock? {
        didSet {
            if let stock = s