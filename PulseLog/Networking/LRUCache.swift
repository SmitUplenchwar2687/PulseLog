import Foundation

actor LRUCache<Key: Hashable, Value> {
    private final class Node {
        let key: Key
        var value: Value
        weak var previous: Node?
        var next: Node?

        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }

    private let capacity: Int
    private var map: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    func value(for key: Key) -> Value? {
        guard let node = map[key] else { return nil }
        moveToHead(node)
        return node.value
    }

    func setValue(_ value: Value, for key: Key) {
        if let existing = map[key] {
            existing.value = value
            moveToHead(existing)
            return
        }

        let node = Node(key: key, value: value)
        map[key] = node
        insertAtHead(node)

        if map.count > capacity, let tail {
            remove(node: tail)
            map[tail.key] = nil
        }
    }

    func removeAll() {
        map.removeAll(keepingCapacity: true)
        head = nil
        tail = nil
    }

    func count() -> Int {
        map.count
    }

    private func moveToHead(_ node: Node) {
        guard head !== node else { return }
        remove(node: node)
        insertAtHead(node)
    }

    private func insertAtHead(_ node: Node) {
        node.previous = nil
        node.next = head
        head?.previous = node
        head = node

        if tail == nil {
            tail = node
        }
    }

    private func remove(node: Node) {
        let previous = node.previous
        let next = node.next

        previous?.next = next
        next?.previous = previous

        if head === node {
            head = next
        }

        if tail === node {
            tail = previous
        }

        node.previous = nil
        node.next = nil
    }
}
