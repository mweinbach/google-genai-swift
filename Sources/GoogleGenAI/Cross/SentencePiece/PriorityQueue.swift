// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Generic max-priority queue with `insert`, `popMax`, and `removeFunc` operations.
///
/// Implemented as a binary heap stored at indices `1..<count`; index 0 is a
/// dummy slot so the parent/child arithmetic mirrors the reference Go
/// implementation in `go-sentencepiece/internal/priorityqueue`.
public final class PriorityQueue<T>: @unchecked Sendable {
    /// Returns > 0 if `a` has higher priority than `b`, 0 if equal, < 0 otherwise.
    private let cmp: (T, T) -> Int
    private var items: [T?]

    /// Creates a new `PriorityQueue`.
    ///
    /// - Parameters:
    ///   - sizeHint: Initial capacity hint.
    ///   - cmp: Comparison closure returning > 0 when `a` has higher priority.
    public init(sizeHint: Int, cmp: @escaping (T, T) -> Int) {
        self.cmp = cmp
        self.items = [nil]
        self.items.reserveCapacity(Swift.max(1, sizeHint + 1))
    }

    /// Number of items currently in the queue.
    public func len() -> Int { items.count - 1 }

    /// Inserts a new element into the queue.
    public func insert(_ elem: T) {
        items.append(elem)
        siftUp(items.count - 1)
    }

    /// Removes and returns the element with the highest priority.
    /// Precondition: queue must be non-empty.
    public func popMax() -> T {
        precondition(items.count >= 2, "popping from empty priority queue")
        let maxItem = items[1]!
        items[1] = items[items.count - 1]
        items.removeLast()
        if items.count > 1 {
            siftDown(1)
        }
        return maxItem
    }

    /// Removes all elements for which `rm` returns `true`.
    public func removeFunc(_ rm: (T) -> Bool) {
        var i = 1
        while i < items.count, !rm(items[i]!) {
            i += 1
        }
        if i == items.count {
            return
        }

        var j = i + 1
        while j < items.count {
            if !rm(items[j]!) {
                items[i] = items[j]
                i += 1
            }
            j += 1
        }

        items.removeLast(items.count - i)
        rebuildHeap()
    }

    private func rebuildHeap() {
        var i = items.count / 2
        while i >= 1 {
            siftDown(i)
            i -= 1
        }
    }

    private func siftUp(_ n: Int) {
        var i = n
        while i > 1 {
            let p = i / 2
            if cmp(items[p]!, items[i]!) >= 0 {
                return
            }
            items.swapAt(i, p)
            i = p
        }
    }

    private func siftDown(_ start: Int) {
        var i = start
        while true {
            let c = 2 * i
            if c >= items.count {
                return
            }
            var maxChild = c
            if c + 1 < items.count {
                if cmp(items[c + 1]!, items[c]!) > 0 {
                    maxChild = c + 1
                }
            }
            if cmp(items[i]!, items[maxChild]!) >= 0 {
                return
            }
            items.swapAt(i, maxChild)
            i = maxChild
        }
    }
}
