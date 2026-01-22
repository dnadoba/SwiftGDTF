//
//  DMXMode+resolved.swift
//  SwiftGDTF
//
//  Created by David Nadoba on 12/22/25.
//

extension DMXMode {
    /// Adds additional DMX channels for DMX Breaks in the Geometry.
    /// This is usally how LED Strips or fixture with multiple beams work.
    /// They all have a copy of a set of channels but their DMX offset is shifted.
    ///
    /// It also filters out channels that aren't part of the root geometry of this dmx mode.
    /// I have seen this happen if one geometry node is used as a "template" and then referenced multiple times with DMX breaks.
    /// The original one is then not actually used and the DMX channels for it need to be removed.
    public consuming func resolved(with geomatries: [Geometry]) -> DMXMode {
        guard let geometry else {
            /// root geometry is missing. This isn't valid but some GDTF Share files have it (~50). This is already shown as a error in the GDTF Share Editor but these files still exists.
            /// This should be flagged in the UI.
            return self
        }
        let topLevelGeometryIndex = Dictionary(
            geomatries.lazy.map { ($0.name, $0) },
            // keep the first if we find duplicate named geometry
            uniquingKeysWith: { old, new in old }
        )
        guard let root = topLevelGeometryIndex[geometry] else {
            // TODO: report errors back
            return self
        }
        /// all geometry names that are part of the root tree
        var geometriesIncludedInRoot = Set<String>()
        /// references that are part of the root tree indexed by the top level geometry name they are referencing
        var topLevelGeometryToReferences: [String: [GeometryReference]] = [:]
        func recursivlyAddSelfAndChildren(_ geometry: Geometry) {
            geometriesIncludedInRoot.insert(geometry.name)
            if
                case .reference(let reference) = geometry,
                let referencedGeometry = reference.geometry
            {
                topLevelGeometryToReferences[referencedGeometry, default: []].append(reference)
            }
            for child in geometry.children {
                recursivlyAddSelfAndChildren(child)
            }
        }
        recursivlyAddSelfAndChildren(root)
        var channelsConnectedToRoot: [DMXChannel] = []
        var channelsFromReferences: [DMXChannel] = []
        for channel in channels {
            if geometriesIncludedInRoot.contains(channel.geometry) {
                channelsConnectedToRoot.append(channel)
            } else if let references = topLevelGeometryToReferences[channel.geometry] {
                // This isn't in the root geometry but it might be references
                for reference in references {
                    var copyOfChannel = channel
                    guard let referenceBreak = reference.getDMXBreak(for: channel.dmxBreak) else {
                        continue
                    }
                    // This is only really doing something if the dmxBreak was overwrite before
                    copyOfChannel.dmxBreak = .id(referenceBreak.break)
                    
                    copyOfChannel.offset = copyOfChannel.offset.map {
                        /// a DMXAddress has in theory also a univers but the GDTF Share editor doesn't seem to allow to define the universe
                        $0 + (referenceBreak.offset.address - 1)
                    }
                    if let oldName = copyOfChannel.name {
                        copyOfChannel.name = "\(reference.name) \(oldName)"
                    } else {
                        copyOfChannel.name = reference.name
                    }
                    channelsFromReferences.append(copyOfChannel)
                }
            }
        }
        var copyOfDMXMode = self
        copyOfDMXMode.channels = channelsConnectedToRoot + channelsFromReferences
        copyOfDMXMode.channels.sort(by: {
            if $0.dmxBreak == $1.dmxBreak {
                ($0.offset.first ?? -1) < ($1.offset.first ?? -1)
            } else {
                $0.dmxBreak < $1.dmxBreak
            }
        })
        return copyOfDMXMode
    }
}
