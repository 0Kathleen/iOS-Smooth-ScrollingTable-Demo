# iOS-Smooth-ScrollingTable-Demo
A high-performance iOS TableView demo with custom thread-safe ImageLoader, prefetching, and fast-scroll optimization.

Smooth-ScrollingTable  是一个演示如何在 iOS 中实现无限、流畅的列表滚动 Demo。

本项目没有依赖任何第三方库，而是手动实现了一个轻量级、线程安全的图片加载器和一套完整的性能优化策略，旨在展示 iOS 列表优化的核心底层原理。

### 核心特性

1.图片加载器 Image Loader

- 基于 URLSession 和 GCD 封装

- 实现内存 (`NSCache`) + 磁盘 (`URLCache`)**双重缓存**机制

2.高并发与线程安全

- 使用 **GCD 栅栏函数**解决读写锁问题，防止竞态条件。
- **请求合并 **：当多个 Cell 请求同一张图片时，不会重复发起网络请求，而是通过**回调数组**分发结果。

3.智能取消机制

- 利用**引用计数**解决 Cell 复用时的请求取消问题。只有当所有请求该 URL 的 Cell 都取消时，才真正断开网络连接。

4.列表滚动性能优化

- **快速滑动保护**：监听 `UIScrollView` 的滑动速度，当用户快速滑动时暂停加载图片，停止后立即加载可见区域。
- **预加载**：实现 `DataSourcePrefetching` 协议，在 Cell 进入屏幕前提前下载数据。

5.自适应布局 

- 使用 Auto Layout + `estimatedRowHeight` 实现 Self-Sizing Cells。
