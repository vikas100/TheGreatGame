//
//  Editioned.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

public struct Editioned<Content : Mappable> {
    
    public let edition: Int
    public let content: Content
    
    public func isMoreRecent(than other: Editioned<Content>) -> Bool {
        if self.edition == -1 && other.edition != -1 {
            return true
        } else {
            return self.edition > other.edition
        }
    }
    
    public static func compare(_ lhs: Editioned<Content>, _ rhs: Editioned<Content>) -> Bool {
        return lhs.isMoreRecent(than: rhs)
    }
    
}

public enum EditionedMappingKeys : String, IndexPathElement {
    case edition, content
}

extension Editioned : Mappable {
    
    public init<Source : InMap>(mapper: InMapper<Source, EditionedMappingKeys>) throws {
        self.edition = try mapper.map(from: .edition)
        self.content = try mapper.map(from: .content)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, EditionedMappingKeys>) throws where Destination : OutMap {
        try mapper.map(self.edition, to: .edition)
        try mapper.map(self.content, to: .content)
    }
    
}

