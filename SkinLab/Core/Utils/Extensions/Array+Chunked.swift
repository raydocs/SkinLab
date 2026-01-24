// SkinLab/Core/Utils/Extensions/Array+Chunked.swift
import Foundation

extension Array {
    /// 将数组分割成指定大小的块
    /// - Parameter size: 每块的最大元素数量
    /// - Returns: 分块后的二维数组
    ///
    /// 示例:
    /// ```swift
    /// [1, 2, 3, 4, 5].chunked(into: 2)
    /// // [[1, 2], [3, 4], [5]]
    /// ```
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
