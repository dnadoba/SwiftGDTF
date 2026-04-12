#!/usr/bin/env python3
"""
Extract MVR statistics from all .mvr files in Tests/SwiftGDTFTests/MVRTestFixtures/
and output Swift code for expectStatistics calls.
"""

import zipfile
import xml.etree.ElementTree as ET
import os
import sys
from collections import defaultdict
from typing import Optional

MVR_FIXTURES_DIR = "Tests/SwiftGDTFTests/MVRTestFixtures"


def strip_null_bytes(data: bytes) -> bytes:
    """Strip trailing NULL bytes from XML data."""
    return data.rstrip(b'\x00')


def load_xml_from_mvr(mvr_path: str) -> Optional[ET.Element]:
    """Extract and parse GeneralSceneDescription.xml from an MVR file."""
    try:
        with zipfile.ZipFile(mvr_path, 'r') as zf:
            xml_data = zf.read("GeneralSceneDescription.xml")
            xml_data = strip_null_bytes(xml_data)
            return ET.fromstring(xml_data)
    except Exception as e:
        print(f"ERROR loading {mvr_path}: {e}", file=sys.stderr)
        return None


def get_root_attributes(root: ET.Element) -> dict:
    """Extract version and provider from root element."""
    ver_major = root.get("verMajor", "1")
    ver_minor = root.get("verMinor", "0")
    provider = root.get("provider", "")
    return {
        "version": f"{ver_major}.{ver_minor}",
        "provider": provider,
    }


def get_layers(root: ET.Element) -> list:
    """Get all Layer elements directly under Scene/Layers."""
    layers = []
    scene = root.find("Scene")
    if scene is not None:
        layers_el = scene.find("Layers")
        if layers_el is not None:
            for layer in layers_el.findall("Layer"):
                name = layer.get("name", "")
                layers.append((name, layer))
    return layers


def get_auxdata(root: ET.Element) -> dict:
    """Count AUXData children."""
    counts = {
        "symdefCount": 0,
        "classCount": 0,
        "positionCount": 0,
        "mappingDefinitionCount": 0,
    }
    scene = root.find("Scene")
    if scene is None:
        return counts
    aux = scene.find("AUXData")
    if aux is None:
        return counts
    counts["symdefCount"] = len(aux.findall("Symdef"))
    counts["classCount"] = len(aux.findall("Class"))
    counts["positionCount"] = len(aux.findall("Position"))
    counts["mappingDefinitionCount"] = len(aux.findall("MappingDefinition"))
    return counts


def count_geometry_nodes_in_element(element: ET.Element) -> tuple:
    """Count Geometry3D and Symbol nodes recursively within an element."""
    geo3d = 0
    sym = 0
    for child in element.iter():
        if child.tag == "Geometry3D":
            geo3d += 1
        elif child.tag == "Symbol":
            sym += 1
    return geo3d, sym


def count_geometry_in_symdefs(root: ET.Element) -> tuple:
    """Count geometry nodes in all Symdef elements."""
    geo3d = 0
    sym = 0
    scene = root.find("Scene")
    if scene is None:
        return geo3d, sym
    aux = scene.find("AUXData")
    if aux is None:
        return geo3d, sym
    for symdef in aux.findall("Symdef"):
        # Count Geometry3D and Symbol nodes within Geometries children of Symdef
        g, s = count_geometry_nodes_in_element(symdef)
        geo3d += g
        sym += s
    return geo3d, sym


def walk_child_list(element: ET.Element, layer_name: str,
                    stats: dict, gdtf_spec_counts: dict, layer_fixture_counts: dict):
    """
    Recursively walk child elements counting objects.
    element: the container element (ChildList, GroupObject, etc.)
    layer_name: current ancestor layer name
    """
    # Process direct children
    for child in element:
        tag = child.tag
        if tag == "Fixture":
            stats["fixtureCount"] += 1
            layer_fixture_counts[layer_name] = layer_fixture_counts.get(layer_name, 0) + 1
            # GDTFSpec
            gdtf_spec_el = child.find("GDTFSpec")
            if gdtf_spec_el is not None and gdtf_spec_el.text and gdtf_spec_el.text.strip():
                spec = gdtf_spec_el.text.strip()
                gdtf_spec_counts[spec] = gdtf_spec_counts.get(spec, 0) + 1
            # Check for addresses
            addresses_el = child.find("Addresses")
            if addresses_el is not None:
                if len(addresses_el.findall("Address")) > 0:
                    stats["fixturesWithAddresses"] += 1
            # Recurse into fixture's ChildList if any
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "SceneObject":
            stats["sceneObjectCount"] += 1
            # Count geometry nodes
            geometries = child.find("Geometries")
            if geometries is not None:
                g, s = count_geometry_nodes_in_element(geometries)
                stats["geometry3DCount"] += g
                stats["symbolCount"] += s
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "GroupObject":
            stats["groupObjectCount"] += 1
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "FocusPoint":
            stats["focusPointCount"] += 1
            geometries = child.find("Geometries")
            if geometries is not None:
                g, s = count_geometry_nodes_in_element(geometries)
                stats["geometry3DCount"] += g
                stats["symbolCount"] += s
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "Truss":
            stats["trussCount"] += 1
            geometries = child.find("Geometries")
            if geometries is not None:
                g, s = count_geometry_nodes_in_element(geometries)
                stats["geometry3DCount"] += g
                stats["symbolCount"] += s
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "Support":
            stats["supportCount"] += 1
            geometries = child.find("Geometries")
            if geometries is not None:
                g, s = count_geometry_nodes_in_element(geometries)
                stats["geometry3DCount"] += g
                stats["symbolCount"] += s
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "VideoScreen":
            stats["videoScreenCount"] += 1
            geometries = child.find("Geometries")
            if geometries is not None:
                g, s = count_geometry_nodes_in_element(geometries)
                stats["geometry3DCount"] += g
                stats["symbolCount"] += s
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "Projector":
            stats["projectorCount"] += 1
            geometries = child.find("Geometries")
            if geometries is not None:
                g, s = count_geometry_nodes_in_element(geometries)
                stats["geometry3DCount"] += g
                stats["symbolCount"] += s
            child_list = child.find("ChildList")
            if child_list is not None:
                walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

        elif tag == "ChildList":
            # ChildList as a direct child — recurse into it
            walk_child_list(child, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)


def get_archive_counts(mvr_path: str) -> dict:
    """Count archive files (root-level only: no '/' in path, not ending with '/')."""
    counts = {
        "archiveFileCount": 0,
        "gdtfFileCount": 0,
        "threeDSFileCount": 0,
        "glbFileCount": 0,
    }
    try:
        with zipfile.ZipFile(mvr_path, 'r') as zf:
            for info in zf.infolist():
                path = info.filename
                # Root-level: no '/' in path (or only a trailing '/' for dirs)
                # Skip directories
                if path.endswith('/'):
                    continue
                # Skip entries with path separators (subdirectories)
                if '/' in path:
                    continue
                counts["archiveFileCount"] += 1
                lower = path.lower()
                if lower.endswith(".gdtf"):
                    counts["gdtfFileCount"] += 1
                elif lower.endswith(".3ds"):
                    counts["threeDSFileCount"] += 1
                elif lower.endswith(".glb"):
                    counts["glbFileCount"] += 1
    except Exception as e:
        print(f"ERROR reading archive {mvr_path}: {e}", file=sys.stderr)
    return counts


def extract_statistics(mvr_path: str) -> dict:
    """Extract all statistics from an MVR file."""
    root = load_xml_from_mvr(mvr_path)
    if root is None:
        return None

    # Root attributes
    root_attrs = get_root_attributes(root)

    # Layers
    layers = get_layers(root)
    layer_names = [name for name, _ in layers]

    # AUXData
    aux = get_auxdata(root)

    # Geometry in symdefs
    geo3d_symdefs, sym_symdefs = count_geometry_in_symdefs(root)

    # Walk layers
    stats = {
        "fixtureCount": 0,
        "sceneObjectCount": 0,
        "groupObjectCount": 0,
        "focusPointCount": 0,
        "trussCount": 0,
        "supportCount": 0,
        "videoScreenCount": 0,
        "projectorCount": 0,
        "geometry3DCount": geo3d_symdefs,
        "symbolCount": sym_symdefs,
        "fixturesWithAddresses": 0,
    }
    gdtf_spec_counts = {}
    layer_fixture_counts = {}

    for layer_name, layer_el in layers:
        child_list = layer_el.find("ChildList")
        if child_list is not None:
            walk_child_list(child_list, layer_name, stats, gdtf_spec_counts, layer_fixture_counts)

    # Unique GDTF specs
    unique_specs = sorted(gdtf_spec_counts.keys())

    # fixtureCountByGDTFSpec sorted by spec name
    fixture_count_by_spec = sorted(gdtf_spec_counts.items(), key=lambda x: x[0])

    # fixtureCountByLayer sorted by layer name
    fixture_count_by_layer = sorted(layer_fixture_counts.items(), key=lambda x: x[0])

    # Archive counts
    archive = get_archive_counts(mvr_path)

    return {
        **root_attrs,
        "layerCount": len(layers),
        "layerNames": layer_names,
        **stats,
        **aux,
        "uniqueGDTFSpecs": unique_specs,
        "fixtureCountByGDTFSpec": fixture_count_by_spec,
        "fixtureCountByLayer": fixture_count_by_layer,
        **archive,
    }


def swift_string_list(items: list) -> str:
    """Format a list of strings as Swift array literal."""
    if not items:
        return "[]"
    inner = ",\n                ".join(f'"{s}"' for s in items)
    return f"[\n                {inner},\n            ]"


def swift_named_count_list(items: list) -> str:
    """Format a list of (name, count) tuples as Swift NamedCount array."""
    if not items:
        return "[]"
    inner = ",\n                ".join(f'NamedCount("{name}", {count})' for name, count in items)
    return f"[\n                {inner},\n            ]"


def format_swift(filename: str, s: dict) -> str:
    """Format statistics as a Swift expectStatistics call."""
    name = os.path.splitext(filename)[0]
    lines = [
        f"    // MARK: {filename}",
        f"    @Test func test_{name.replace('-', '_').replace('.', '_').replace(' ', '_')}() throws {{",
        f"        let stats = try loadAndExtractStatistics(from: /* {filename} fixture */ )",
        f"        expectStatistics(",
        f"            stats,",
        f'            version: "{s["version"]}",',
    ]
    if s["provider"]:
        lines.append(f'            provider: "{s["provider"]}",')
    lines += [
        f'            layerCount: {s["layerCount"]},',
        f'            layerNames: {swift_string_list(s["layerNames"])},',
        f'            fixtureCount: {s["fixtureCount"]},',
    ]
    # Only emit non-zero optional fields
    for field, default in [
        ("sceneObjectCount", 0),
        ("groupObjectCount", 0),
        ("focusPointCount", 0),
        ("trussCount", 0),
        ("supportCount", 0),
        ("videoScreenCount", 0),
        ("projectorCount", 0),
        ("symdefCount", 0),
        ("classCount", 0),
        ("positionCount", 0),
        ("mappingDefinitionCount", 0),
        ("geometry3DCount", 0),
        ("symbolCount", 0),
    ]:
        val = s[field]
        if val != default:
            lines.append(f'            {field}: {val},')
    lines += [
        f'            uniqueGDTFSpecs: {swift_string_list(s["uniqueGDTFSpecs"])},',
        f'            fixturesWithAddresses: {s["fixturesWithAddresses"]},',
        f'            fixtureCountByGDTFSpec: {swift_named_count_list(s["fixtureCountByGDTFSpec"])},',
        f'            fixtureCountByLayer: {swift_named_count_list(s["fixtureCountByLayer"])},',
        f'            archiveFileCount: {s["archiveFileCount"]},',
        f'            gdtfFileCount: {s["gdtfFileCount"]},',
    ]
    if s["threeDSFileCount"] != 0:
        lines.append(f'            threeDSFileCount: {s["threeDSFileCount"]},')
    if s["glbFileCount"] != 0:
        lines.append(f'            glbFileCount: {s["glbFileCount"]},')
    lines += [
        f"        )",
        f"    }}",
    ]
    return "\n".join(lines)


def main():
    fixtures_dir = MVR_FIXTURES_DIR
    if not os.path.isdir(fixtures_dir):
        print(f"ERROR: fixtures directory not found: {fixtures_dir}", file=sys.stderr)
        sys.exit(1)

    mvr_files = sorted(f for f in os.listdir(fixtures_dir) if f.endswith(".mvr"))
    print(f"// Found {len(mvr_files)} MVR files\n")

    for filename in mvr_files:
        path = os.path.join(fixtures_dir, filename)
        print(f"// Processing {filename}...", file=sys.stderr)
        s = extract_statistics(path)
        if s is None:
            print(f"// ERROR: could not parse {filename}")
            continue

        # Print raw stats summary to stderr for verification
        print(f"//   v{s['version']} provider={repr(s['provider'])} layers={s['layerCount']} fixtures={s['fixtureCount']}", file=sys.stderr)
        print(f"//   archive={s['archiveFileCount']} gdtf={s['gdtfFileCount']} 3ds={s['threeDSFileCount']} glb={s['glbFileCount']}", file=sys.stderr)

        print(format_swift(filename, s))
        print()


if __name__ == "__main__":
    main()
