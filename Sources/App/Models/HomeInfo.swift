/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import HTTP
import Vapor


public final class HomeInfo: Model {
  
  // MARK: - RoomSize
  
  public enum RoomSize: String {
    case small
    case medium
    case large
    
    public static func instance(from node: Node, key: String) throws -> RoomSize {
      let rawValue: String = try node.extract(key)
      return try RoomSize.instance(from: rawValue)
    }
    
    public static func instance(from rawValue: String) throws -> RoomSize {
      switch rawValue {
      case RoomSize.small.rawValue: return .small
      case RoomSize.medium.rawValue: return .medium
      case RoomSize.large.rawValue: return .large
      default: throw NodeError.unableToConvert(node: rawValue.makeNode(),
                                               expected: "Valid RoomSize rawValue")
      }
    }
  }
  
  
  // MARK: - Constants
  
  internal struct TableColumnKey {
    static let id = "id"
    static let bathroomCount = "bathroom_count"
    static let bedroomCount = "bedroom_count"
    static let kitchenSize = "kitchen_size"
    static let otherRoomsCount = "other_rooms_count"
    static let squareFootage = "square_footage"
    
    static let userID = "rwuser_id"
  }
  
  
  // MARK: - Instance Properties
  
  public var bathroomCount: UInt
  public var bedroomCount: UInt
  public var kitchenSize: RoomSize
  public var otherRoomsCount: UInt
  public var squareFootage: UInt
  
  public var userID: Node
  
  
  // MARK: - Class Constructors
  
  public class func instance(bathroomCount: UInt,
                             bedroomCount: UInt,
                             kitchenSize: String,
                             otherRoomsCount: UInt,
                             squareFootage: UInt,
                             user: RWUser) throws -> HomeInfo {
    
    var newHomeInfo = try HomeInfo(bathroomCount: bathroomCount,
                                   bedroomCount: bedroomCount,
                                   kitchenSize: kitchenSize,
                                   otherRoomsCount: otherRoomsCount,
                                   squareFootage: squareFootage,
                                   user: user)
    
    guard let existingHomeInfo = user.homeInfo() else {
      try newHomeInfo.save()
      return newHomeInfo
    }

    try existingHomeInfo.update(newHomeInfo)
    return existingHomeInfo
  }
  
  
  // MARK: - Object Lifecycle
  
  private init(bathroomCount: UInt,
              bedroomCount: UInt,
              kitchenSize: String,
              otherRoomsCount: UInt,
              squareFootage: UInt,
              user: RWUser) throws {
    self.bathroomCount = bathroomCount
    self.bedroomCount = bedroomCount
    self.kitchenSize = try RoomSize.instance(from: kitchenSize)
    self.otherRoomsCount = otherRoomsCount
    self.squareFootage = squareFootage
    
    self.userID = user.id!
  }
  
  public func update(_ homeInfo: HomeInfo) throws {
    var existing = self
    bathroomCount = homeInfo.bathroomCount
    bedroomCount = homeInfo.bedroomCount
    kitchenSize = homeInfo.kitchenSize
    otherRoomsCount = homeInfo.otherRoomsCount
    squareFootage = homeInfo.squareFootage
    try existing.save()
  }
  
  
  // MARK: - Entity
  
  public var exists: Bool = false
  public var id: Node? = nil
  
  
  // MARK: - NodeRepresentable
  
  public init(node: Node, in context: Context) throws {
    id = try node.extract(TableColumnKey.id)
    bathroomCount = try node.extract(TableColumnKey.bathroomCount)
    bedroomCount = try node.extract(TableColumnKey.bedroomCount)
    kitchenSize = try RoomSize.instance(from: node, key: TableColumnKey.kitchenSize)
    otherRoomsCount = try node.extract(TableColumnKey.otherRoomsCount)
    squareFootage = try node.extract(TableColumnKey.squareFootage)
    
    userID = try node.extract(TableColumnKey.userID)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try Node(node: [
      TableColumnKey.id: id,
      TableColumnKey.bathroomCount: bathroomCount,
      TableColumnKey.bedroomCount: bedroomCount,
      TableColumnKey.kitchenSize: kitchenSize.rawValue,
      TableColumnKey.otherRoomsCount: otherRoomsCount,
      TableColumnKey.squareFootage: squareFootage,
      
      TableColumnKey.userID: userID
    ])
  }
  
  
  // MARK: - Preparation
  
  public class func prepare(_ database: Database) throws {
    try database.create(entity) { table in
      table.id()
      table.int(TableColumnKey.bathroomCount)
      table.int(TableColumnKey.bedroomCount)
      table.string(TableColumnKey.kitchenSize)
      table.int(TableColumnKey.otherRoomsCount)
      table.int(TableColumnKey.squareFootage)
      
      table.parent(RWUser.self, optional: false)
    }
  }
  
  public class func revert(_ database: Database) throws {
    try database.delete(entity)
  }
}


// MARK: - HomeInfo + Relations

extension HomeInfo {
  
  public func user() throws -> RWUser! {
    return try parent(userID).get()
  }
}
