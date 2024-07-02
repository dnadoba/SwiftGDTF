//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/2/24.
//

import Foundation

public let COLOR_SPACE_SRGB = ColorSpaceDefinition(
    r: ColorCIE(x: 0.6400, y: 0.3300, Y: 0.2126),
    g: ColorCIE(x: 0.3000, y: 0.6000, Y: 0.7152),
    b: ColorCIE(x: 0.1500, y: 0.0600, Y: 0.0722),
    w: ColorCIE(x: 0.3127, y: 0.3290, Y: 1.0000))

public let COLOR_SPACE_PROPHOTO = ColorSpaceDefinition(
    r: ColorCIE(x: 0.7347, y: 0.2653),
    g: ColorCIE(x: 0.1596, y: 0.8404),
    b: ColorCIE(x: 0.0366, y: 0.0001),
    w: ColorCIE(x: 0.3457, y: 0.3585))

public let COLOR_SPACE_ANSI = ColorSpaceDefinition(
    r: ColorCIE(x: 0.7347, y: 0.2653),
    g: ColorCIE(x: 0.1596, y: 0.8404),
    b: ColorCIE(x: 0.0366, y: 0.0010),
    w: ColorCIE(x: 0.4254, y: 0.4044))
