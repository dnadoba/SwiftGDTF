# SwiftGDTF
A Swift library for interacting with GDTF files.

*Note: This library is still in development and will have frequent breaking changes. Look out for a v1 release that will be more stable in updates*

This library:
- Handles the decompression and parsing of GDTF Files
- Resolves (most) node links present in attributes
- Does not currenty parse Geometries (and geometry tags in other elements), Models, FTPresets, or Protocols nodes currently, if you would like to add support, submit a PR!
- Does not currently handle the decompression of image files 

## Installation
Install with SPM, currently running off of master branch until a v1 release.

```
dependencies: [
    .package(url: "https://github.com/bwees/SwiftGDTF.git", branch: "master)
]
```
