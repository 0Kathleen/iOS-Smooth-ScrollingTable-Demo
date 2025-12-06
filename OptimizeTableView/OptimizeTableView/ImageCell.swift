//
//  imageCell.swift
//  OptimizeTableView
//
//  Created by kathleen on 2025/12/6.
//

import UIKit

class ImageCell:UITableViewCell{
    
    static let reuseId = "ImageCell"
    var imageURL: URL?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        contentView.addSubview(photoView)
        photoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            photoView.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 16),
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,constant: 16),
            photoView.widthAnchor.constraint(equalToConstant: 75),
            photoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: -16),
            photoView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
        imageURL = nil
    }
    
    func configure(with url: URL?){
        imageURL = url
        photoView.image = nil
    }
    
    let photoView:UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()
    
}
