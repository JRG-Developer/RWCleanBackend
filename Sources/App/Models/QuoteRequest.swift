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

import Foundation
import Fluent
import HTTP
import Vapor


public final class QuoteRequest: Model {
  
  // MARK: - Constants
  
  internal struct TableColumnKey {
    static let id = "id"
    static let created = "created"
    static let promised = "promised"
    static let userID = "rwuser_id"
  }
  
  internal struct SiblingRelationKeys {
    static let product = "product"
  }
  
  
  // MARK: - Instance Properties
  
  public var created: Date
  public var promised: Date
  
  public var userID: Node
  
  
  // MARK: - Class Constructors
  
  public class func instance(user: RWUser, product: Product) throws -> QuoteRequest {
    var quote = try QuoteRequest(user: user)
    try quote.save()
    
    var productPivot = Pivot<QuoteRequest, Product>(quote, product)
    try productPivot.save()
    
    return quote
  }
  
  
  // MARK: - Object Lifecycle
  
  private init(user: RWUser) throws {
    self.created = Date()
    self.promised = created + 3.days
    self.userID = user.id!
  }
  
  
  // MARK: - Entity
  
  public var id: Node? = nil
  public var exists: Bool = false
  
  
  // MARK: - NodeRepresentable
  
  public init(node: Node, in context: Context) throws {    
    created = try node.extract(TableColumnKey.created, transform: { Date(timeIntervalSince1970: $0) })
    promised = try node.extract(TableColumnKey.promised, transform: { Date(timeIntervalSince1970: $0) })
    userID = try node.extract(TableColumnKey.userID)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try Node(node: [
      TableColumnKey.id: id,
      TableColumnKey.created: created.timeIntervalSince1970,
      TableColumnKey.promised: promised.timeIntervalSince1970,
      
      TableColumnKey.userID: userID
    ])
  }
  
  public func makePublicNode() throws -> Node {
    
    guard let product = try self.product() else {
      throw Abort.serverError
    }
    
    var nodeObject = try makeNode().nodeObject!
    nodeObject[SiblingRelationKeys.product] = try product.makeNode()
    return try Node(node: nodeObject)
  }
  
  public func makeJSON() throws -> JSON {
    return try JSON(node: makePublicNode())
  }
  
  
  // MARK: - Preparation
  
  public class func prepare(_ database: Database) throws {
    try database.create(entity) { table in
      table.id()
      table.double(TableColumnKey.created)
      table.double(TableColumnKey.promised)
      
      table.parent(RWUser.self, optional: false)
    }
  }
  
  public class func revert(_ database: Database) throws {
    try database.delete(entity)
  }
}


// MARK: - QuoteRequest + Relations

extension QuoteRequest {
  
  public func product() throws -> Product? {
    let siblings: Siblings<Product> = try self.siblings()
    return try siblings.first()
  }
  
  public func user() throws -> RWUser! {
    return try parent(userID).get()
  }
}


// MARK: - Request + QuoteRequest

extension Request {  
  public func quoteRequest() throws -> QuoteRequest {
    guard let json = json else { throw Abort.badRequest }
    return try QuoteRequest(node: json)
  }
}
