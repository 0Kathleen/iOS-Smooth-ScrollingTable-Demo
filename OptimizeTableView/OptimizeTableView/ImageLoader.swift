//
//  ImageLoader.swift
//  OptimizeTableView
//
//  Created by kathleen on 2025/12/6.
//
import UIKit

class ImageCache{
    static let shared = NSCache<NSString,UIImage>()
    private init() {}
}

class ImageLoader{
    static let shared = ImageLoader()
    
    private let session:URLSession
    private let queue = DispatchQueue(label:"com.demo.imageloader",attributes: .concurrent)
    
    private var tasks: [URL:URLSessionDataTask] = [:]
    private var refCounts:[URL:Int] = [:]   // 让多个 cell 请求同一个 URL 时不重复下载，能正确取消任务
    private var completions: [URL: [(UIImage?) -> Void]] = [:]  // 存储同一个 URL 对应的多个回调闭包
    
    private init(){
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad  // 缓存策略：优先返回缓存
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024,
                                   diskCapacity: 100 * 1024 * 1024,
                                   diskPath: "demo_url_cache") // 设置 urlCache
        session = URLSession(configuration: config)
    }
    
    func load(_ url: URL,priority: Float = URLSessionTask.defaultPriority,completion: @escaping (UIImage?) -> Void){
        
        //  图片缓存过，直接返回
        if let img = ImageCache.shared.object(forKey: url.absoluteString as NSString){
            print("命中缓存")
            completion(img)
            return
        }
        
        queue.async(flags: .barrier){ [weak self] in
            guard let self = self else { return }
            
            if self.completions[url] == nil {
                self.completions[url] = []
            }
            self.completions[url]?.append(completion)
            
            // 请求同一个 url 时，只是增加引用计数，不再重新发起请求
            if let _ = tasks[url]{
                refCounts[url,default: 0] += 1
                return
            }
            
            //  创建任务
            let task = session.dataTask(with: url){ data, response, error in
                var image: UIImage? = nil
                if let data = data {
                    image = UIImage(data: data)
                }
                //  加入缓存中
                if let image = image {
                    ImageCache.shared.setObject(image, forKey: url.absoluteString as NSString)
                }
                //  任务下载完成后移除
                self.queue.async(flags: .barrier){
                    let handlers = self.completions[url] ?? []
                    
                    self.tasks[url] = nil
                    self.refCounts[url] = nil
                    self.completions[url] = nil
                    
                    // 执行此 url 对应的所有回调
                    DispatchQueue.main.async {
                        for handler in handlers {
                            handler(image)
                        }
                    }
                }
            }
            task.priority = priority
            tasks[url] = task
            refCounts[url] = 1
            task.resume()
        }
    }
    
    func cancel(_ url:URL){
        queue.async(flags: .barrier){ [weak self] in
            guard let self = self,let task = self.tasks[url] else { return }
            let count = (self.refCounts[url] ?? 1 ) - 1
            if count <= 0 {
                task.cancel()
                self.tasks[url] = nil
                self.refCounts[url] = nil
                self.completions[url] = nil
            }else{
                self.refCounts[url] = count
            }
        }
    }
    
    func forceCancel(_ url:URL){
        queue.async(flags: .barrier){
            self.tasks[url]?.cancel()
            self.tasks[url] = nil
            self.refCounts[url] = nil
            self.completions[url] = nil
        }
    }
}
