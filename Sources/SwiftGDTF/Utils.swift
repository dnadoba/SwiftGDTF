//
//  File.swift
//  
//
//  Created by Brandon Wees on 7/6/24.
//

import Foundation
import SWXMLHash

func resolveNode<T: XMLDecodable>(path pathStr: String?, base: XMLIndexer, tree fullTree: XMLIndexer) -> T? {
    guard let pathStr else { return nil }
    
    let path = pathStr.components(separatedBy: ".")
    var tree = base
    
    for step in path {
        tree = tree.children.first(where: { child in
            if let name = child.element!.attribute(by: "Name")?.text {
                return name == step
            }
            
            return false
        })!
    }
    
    return T(xml: tree, tree: fullTree)
}

extension XMLIndexer {
    func parseChildrenToArray<T: XMLDecodable>(tree fullTree: XMLIndexer) -> [T] {
        return self.children.map { child in
            child.parse(tree: fullTree)
        }
    }
    
    func parseChildrenToArray<T: XMLDecodableWithParent>(parent: XMLIndexer, tree fullTree: XMLIndexer) -> [T] {
        return self.children.map { child in
            child.parse(parent: parent, tree: fullTree)
        }
    }
    
    func parseChildrenToArray<T: XMLDecodableWithIndex>(tree fullTree: XMLIndexer) -> [T] {
        return self.children.enumerated().map { (index, child) in
            child.parse(index: index, tree: fullTree)
        }
    }
    
    func parse<T: XMLDecodable>(tree fullTree: XMLIndexer) -> T {
        return T(xml: self, tree: fullTree)
    }
    
    func parse<T: XMLDecodableWithIndex>(index: Int, tree fullTree: XMLIndexer) -> T {
        return T(xml: self, index: index, tree: fullTree)
    }
    
    func parse<T: XMLDecodableWithParent>(parent: XMLIndexer, tree fullTree: XMLIndexer) -> T {
        return T(xml: self, parent: parent, tree: fullTree)
    }
}

extension XMLAttribute {
    var double: Double? {
        return Double(self.text)
    }
    
    var int: Int? {
        return Int(self.text)
    }
    
    func toEnum<T: RawRepresentable>() -> T? {
        return T(rawValue: self.text as! T.RawValue)
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
