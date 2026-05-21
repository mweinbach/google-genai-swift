// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Trie node used by `PrefixMatcher`.
private final class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isFinal: Bool = false
}

/// `PrefixMatcher` finds the longest prefix of a string that matches a
/// vocabulary word using a trie data structure.
public final class PrefixMatcher: @unchecked Sendable {
    private let root: TrieNode

    /// Creates a new `PrefixMatcher` from a vocabulary set.
    public init(vocab: Set<String>) {
        self.root = TrieNode()
        for word in vocab {
            self.add(word)
        }
    }

    /// Returns the length (in characters) of the longest prefix of `text`
    /// that matches a vocabulary entry, or 0 if no prefix matches.
    public func findPrefixLen(_ text: String) -> Int {
        var node = root
        var maxLen = 0
        var i = 0
        for char in text {
            guard let child = node.children[char] else {
                return maxLen
            }
            if child.isFinal {
                maxLen = i + 1
            }
            node = child
            i += 1
        }
        return maxLen
    }

    private func add(_ word: String) {
        var node = root
        for char in word {
            if let next = node.children[char] {
                node = next
            } else {
                let next = TrieNode()
                node.children[char] = next
                node = next
            }
        }
        node.isFinal = true
    }
}
