//
//  ViewController.swift
//  OptimizeTableView
//
//  Created by kathleen on 2025/12/6.
//

import UIKit

class ViewController: UIViewController {
    private var urls: [URL] = []
    private var isScrollingFast = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    private func setupData(){
        for i in 0..<1000 {
            if let u = URL(string: "https://picsum.photos/id/\(i % 1000)/800/600") {
                urls.append(u)
            }
        }
    }
    
    private func setupUI(){
        title = "Image List"
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadImageIfNeeded(for indexPath: IndexPath, priority: Float = 0.5){
        guard indexPath.row < urls.count else { return }
        let url = urls[indexPath.row]
        
        if let cached = ImageCache.shared.object(forKey: url.absoluteString as NSString){
            if let cell = tableView.cellForRow(at: indexPath) as? ImageCell {
                cell.photoView.image = cached
            }
            return
        }
        
        // 用户在快速滑动，跳过下载
        if isScrollingFast {
            return
        }
        
        ImageLoader.shared.load(url, priority: priority){ [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async{
                // 避免复用机制的坑
                if let cell = self.tableView.cellForRow(at: indexPath) as? ImageCell,
                   cell.imageURL == url{
                    cell.photoView.image = image
                }
            }
        }
    }
    
    private func loadVisbleCellsImmediately(){
        guard let visible = tableView.indexPathsForVisibleRows else { return }
        for indexPath in visible {
            loadImageIfNeeded(for: indexPath, priority: 1.0)
        }
    }
    
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 132

        tv.register(ImageCell.self, forCellReuseIdentifier: ImageCell.reuseId)
        tv.dataSource = self
        tv.delegate = self
        tv.prefetchDataSource = self
        return tv
    }()
    
}
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageCell.reuseId, for: indexPath) as! ImageCell
        cell.configure(with: urls[indexPath.row])
        return cell
    }
}
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //  提前下载此 indexPath 的数据
        loadImageIfNeeded(for: indexPath, priority: 0.6)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < urls.count else { return }
        let url = urls[indexPath.row]
        ImageLoader.shared.cancel(url)
    }
}
extension ViewController:UITableViewDataSourcePrefetching{
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print("prefetching第:\(indexPath)行数据")
            guard indexPath.row < urls.count else { return }
            let url = urls[indexPath.row]
            if ImageCache.shared.object(forKey: url.absoluteString as NSString) != nil{
                continue
            }
            ImageLoader.shared.load(url, priority: 0.2) { _ in }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < urls.count else { continue }
            let url = urls[indexPath.row]
            ImageLoader.shared.cancel(url)
        }
    }
}
extension ViewController: UIScrollViewDelegate {
    // 用户开始拖动
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrollingFast = false
    }
    
    // 判断是否在快速滑动
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let v = scrollView.panGestureRecognizer.velocity(in: scrollView.superview)
        isScrollingFast = abs(v.y) > 2000
    }
    
    // 滑动停止了，立马加载当前可见的 cell
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrollingFast = false
        loadVisbleCellsImmediately()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate{
            isScrollingFast = false
            loadVisbleCellsImmediately()
        }
    }
}
