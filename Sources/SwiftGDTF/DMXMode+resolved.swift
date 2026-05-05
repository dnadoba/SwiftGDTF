//
//  DMXMode+resolved.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 12/22/25.
//

extension DMXMode {
    /// Adds additional DMX channels for DMX Breaks in the Geometry. This is usally how LED Strips or fixture with multiple beams work.
    /// They all have a copy of a set of channels but their DMX offset is shifted.
    ///
    /// Channels can target a geometry that is reached through one or more nested ``GeometryReference`` instances. Each chain of
    /// references from the mode's root to the channel's target geometry produces one resolved replica, and the offsets along that
    /// chain sum together (e.g. an outer reference at break-2 offset 181 around an inner reference at break-2 offset 13 places a
    /// channel with template offset 1 at address ``1 + (13 - 1) + (181 - 1) = 193``).
    ///
    /// Channels are silently dropped in two cases:
    ///   1. The channel's geometry isn't reachable from the root tree. I have seen this happen when one geometry node is used as a
    ///      "template" and referenced multiple times — the original definition is then not actually used and its DMX channels need
    ///      to be removed.
    ///   2. A reference on the resolved chain has no entry for the break id the channel is targeting (this can also occur after
    ///      ``DMXChannel/Break/overwrite`` is resolved at the innermost reference). The replica that would have come from that
    ///      chain is omitted.
    ///
    /// Reference cycles (`A → B → A`) are detected and broken: the recursion does not re-enter a template that is already on the
    /// current chain.
    public consuming func resolved(with geometries: [Geometry]) -> DMXMode {
        guard let geometry else {
            /// root geometry is missing. This isn't valid but some GDTF Share files have it (~50). This is already shown as a error in the GDTF Share Editor but these files still exists.
            /// This should be flagged in the UI.
            return self
        }
        let topLevelGeometryIndex = Dictionary(
            geometries.lazy.map { ($0.name, $0) },
            // keep the first if we find duplicate named geometry
            uniquingKeysWith: { old, _ in old }
        )
        guard let root = topLevelGeometryIndex[geometry] else {
            // TODO: report errors back
            return self
        }

        /// For each geometry name reachable from the root, the list of reference chains (outermost first) that reach it. An empty
        /// chain means the geometry is in the root tree directly. A geometry that is reachable through several chains (e.g. a
        /// template referenced from multiple spots, or a descendant of such a template) appears once per chain — that's what
        /// produces channel replication.
        var pathsByGeometry: [String: [[GeometryReference]]] = [:]
        /// Templates currently on the active recursion chain — used to break reference cycles (`A → B → A`) without recursing forever.
        var templatesOnChain: Set<String> = []

        func recursivelyCollect(_ geometry: Geometry, chain: [GeometryReference]) {
            pathsByGeometry[geometry.name, default: []].append(chain)
            if
                case .reference(let reference) = geometry,
                let referencedName = reference.geometry,
                let target = topLevelGeometryIndex[referencedName],
                !templatesOnChain.contains(referencedName)
            {
                templatesOnChain.insert(referencedName)
                recursivelyCollect(target, chain: chain + [reference])
                templatesOnChain.remove(referencedName)
            }
            for child in geometry.children {
                recursivelyCollect(child, chain: chain)
            }
        }
        recursivelyCollect(root, chain: [])

        var resolvedChannels: [DMXChannel] = []
        for channel in channels {
            guard let paths = pathsByGeometry[channel.geometry] else { continue }
            for chain in paths {
                if chain.isEmpty {
                    resolvedChannels.append(channel)
                } else if let replica = Self.resolve(channel: channel, through: chain) {
                    resolvedChannels.append(replica)
                }
            }
        }

        var copyOfDMXMode = self
        copyOfDMXMode.channels = resolvedChannels
        copyOfDMXMode.channels.sort(by: {
            if $0.dmxBreak == $1.dmxBreak {
                ($0.offset.first ?? -1) < ($1.offset.first ?? -1)
            } else {
                $0.dmxBreak < $1.dmxBreak
            }
        })
        return copyOfDMXMode
    }

    /// Resolves a channel through a chain of ``GeometryReference``s.
    ///
    /// The chain is ordered outermost-first (the reference attached to the root tree comes first; the reference closest to the
    /// channel's target geometry comes last). Resolution walks it inside-out: the innermost reference resolves the channel's break
    /// (turning ``DMXChannel/Break/overwrite`` into a concrete id and contributing its offset), then each outer reference looks up
    /// the now-concrete break id to add its own offset. If any reference on the chain has no entry for the resolved break id, the
    /// replica is dropped — same posture as the previous single-level implementation.
    private static func resolve(channel: consuming DMXChannel, through chain: [GeometryReference]) -> DMXChannel? {
        var totalOffsetShift = 0
        var currentBreak = channel.dmxBreak

        for reference in chain.reversed() {
            guard let referenceBreak = reference.getDMXBreak(for: currentBreak) else {
                return nil
            }
            /// a DMXAddress has in theory also a universe but the GDTF Share editor doesn't seem to allow to define the universe
            totalOffsetShift += referenceBreak.offset.address - 1
            currentBreak = .id(referenceBreak.break)
        }

        channel.dmxBreak = currentBreak
        channel.offset = channel.offset.map { $0 + totalOffsetShift }

        let prefix = chain.map(\.name).joined(separator: " -> ")
        if let oldName = channel.name {
            channel.name = "\(prefix) -> \(oldName)"
        } else {
            channel.name = prefix
        }
        return channel
    }
}

import OrderedCollections

extension [DMXChannel] {
    /// Groups the ``DMXChannel`` by their ``DMXChannel/Break``.
    /// - Returns: The returned ``OrderedDictionary`` is sorted by the ``DMXChannel.Break``.
    public func groupedByDMXBreak() -> OrderedDictionary<DMXChannel.Break, [DMXChannel]> {
        var dict = OrderedDictionary(grouping: self, by: { $0.dmxBreak })
        dict.sort(by: { $0.key < $1.key })
        return dict
    }
}
