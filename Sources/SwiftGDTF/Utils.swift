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
    func mapChildrenToTypeArray<T: XMLDecodable>(tree fullTree: XMLIndexer) -> [T] {
        return self.children.map { child in
            T(xml: child, tree: fullTree)
        }
    }
}

extension XMLAttribute {
    var float: Float? {
        return Float(self.text)
    }
    
    var int: Int? {
        return Int(self.text)
    }
    
    func toEnum<T: RawRepresentable>() -> T? {
        return T(rawValue: self.text as! T.RawValue)
    }
}
