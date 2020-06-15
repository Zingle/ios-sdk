//
//  ZNGContentSizedTableView.swift
//  ZingleSDK
//
//  Created by Jason Neel on 6/4/20.
//

import UIKit

class ZNGContentSizedTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
