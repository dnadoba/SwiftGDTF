//
//  Utils.swift
//  
//
//  Created by Brandon Wees on 7/6/24.
//

import Foundation
import SWXMLHash

public enum XMLParsingError: Error {
    case elementMissing
    case attributeMissing(named: String, on: String)
    case childNotFound(named: String, at: String)
    case initialFunctionPathInvalid
    case enumCastFailed(enumType: String, stringValue: String)
    case nodeResolutionFailed(path: String)
    case noChildren
    case failedToParseString
}

extension XMLAttribute {
    func resolveNode<T: XMLDecodable>(base: XMLIndexer, tree fullTree: XMLIndexer) throws -> T {
        let pathStr = self.text
                
        let path = pathStr.components(separatedBy: ".")
        var tree = base
        
        for step in path {
            guard let nextTree = try tree.children.first(where: { child in
                guard let childElement = child.element else {
                    throw XMLParsingError.childNotFound(named: step, at: path.joined(separator: "."))
                }
                
                // if there is a name field
                if let name = (try? childElement.attribute(named: "Name"))?.text {
                    return name == step
                }
                
                // if there is a attribute field
                if let name = (try? childElement.attribute(named: "Attribute"))?.text {
                    return name == step
                }
                
                // otherwise we need to look for ChannelFunction for the name
                if let initialFunction = try? childElement.attribute(named: "InitialFunction").text {
                    let initialFunctionParts = initialFunction.components(separatedBy: ".")
                    guard initialFunctionParts.count == 3 else {
                        throw XMLParsingError.initialFunctionPathInvalid
                    }
                                    
                    return initialFunctionParts.first == step
                }
                
                return false
            }) else {
                throw XMLParsingError.childNotFound(named: step, at: path.joined(separator: "."))
            }
            
            tree = nextTree
        }
        
        return try T(xml: tree, tree: fullTree)
    }

}

extension XMLIndexer {
    func parseChildrenToArray<T: XMLDecodable>(tree fullTree: XMLIndexer) throws -> [T] {
        return try self.children.map { child in
            try child.parse(tree: fullTree)
        }
    }
    
    func parseChildrenToArray<T: XMLDecodableWithParent>(parent: XMLIndexer, tree fullTree: XMLIndexer) throws -> [T]  {
        return try self.children.map { child in
            try child.parse(parent: parent, tree: fullTree)
        }
    }
    
    func parseChildrenToArray<T: XMLDecodableWithIndex>(tree fullTree: XMLIndexer) throws -> [T] {
        return try self.children.enumerated().map { (index, child) in
            try child.parse(index: index, tree: fullTree)
        }
    }
    
    func parse<T: XMLDecodable>(tree fullTree: XMLIndexer) throws -> T  {
        return try T(xml: self, tree: fullTree)
    }
    
    func optionalParse<T: XMLDecodable>(tree fullTree: XMLIndexer) throws -> T? {
        guard self.element != nil else { return nil }
        
        return try self.parse(tree: fullTree)
    }
    
    func parse<T: XMLDecodableWithIndex>(index: Int, tree fullTree: XMLIndexer) throws -> T {
        return try T(xml: self, index: index, tree: fullTree)
    }
    
    func parse<T: XMLDecodableWithParent>(parent: XMLIndexer, tree fullTree: XMLIndexer) throws -> T {
        return try T(xml: self, parent: parent, tree: fullTree)
    }
    
    func child(named name: String) throws -> XMLIndexer {
        guard let child = self.children.first(where: { c in c.element?.name == name }) else {
            throw XMLParsingError.childNotFound(named: name, at: "")
        }
        
        return child
    }
    
    func firstChild() throws -> XMLIndexer {
        guard let firstChild = self.children.first else {
            throw XMLParsingError.noChildren
        }
        
        return firstChild
    }
}

extension XMLAttribute {
    var double: Double? {
        return Double(self.text)
    }
    
    var int: Int? {
        return Int(self.text)
    }
    
    func toEnum<T: RawRepresentable>() throws -> T {
        guard let raw = self.text as? T.RawValue, let enumValue = T(rawValue: raw) else {
            throw XMLParsingError.enumCastFailed(enumType: String(describing: T.self), stringValue: self.text)
        }
        
        return enumValue
    }
}

extension SWXMLHash.XMLElement {
    func attribute(named name: String) throws -> XMLAttribute {
        guard let attr = self.attribute(by: name) else {
            throw XMLParsingError.attributeMissing(named: name, on: self.description)
        }
        
        return attr
    }
}

extension Double {
    func constrain(min: Double, max: Double) -> Double {
        if self > max {
            return max
        }
        
        if self < min {
            return min
        }
        
        return self
    }
}
