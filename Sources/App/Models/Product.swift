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


public final class Product: Model {
  
  // MARK: - Constants
  
  public enum ProductType: String {
    case business
    case home
    
    public static func instance(from node: Node, key: String) throws -> ProductType {
      let rawValue: String = try node.extract(key)
      guard let roomSize = ProductType(rawValue: rawValue) else {
        throw NodeError.unableToConvert(node: rawValue.makeNode(),
                                        expected: "Valid ProductType rawValue")
      }
      return roomSize
    }
  }
  
  internal struct TableColumnKeys {
    static let id = "id"
    static let imageURL = "image_url"
    static let priceHourly = "price_hourly"
    static let priceSquareFoot = "price_square_foot"
    static let productDescription = "product_description"
    static let title = "title"
    static let type = "type"
  }
  
  
  // MARK: - Instance Properties
  
  public var imageURL: String?
  public var priceHourly: Double
  public var priceSquareFoot: Double
  public var productDescription: String
  public var title: String
  public var type: ProductType
  
  
  // MARK: - Object Lifecycle
  
  public init(imageURL: String?,
              priceHourly: Double,
              priceSquareFoot: Double,
              productDescription: String,
              title: String,
              type: ProductType) {
    
    self.imageURL = imageURL
    self.priceHourly = priceHourly
    self.priceSquareFoot = priceSquareFoot
    self.productDescription = productDescription
    self.title = title
    self.type = type
  }
  
  public func update(_ product: Product) {
    imageURL = product.imageURL
    priceHourly = product.priceHourly
    priceSquareFoot = product.priceSquareFoot
    productDescription = product.productDescription
    title = product.title
    type = product.type
  }
  
  
  // MARK: - Entity
  
  public var id: Node? = nil
  public var exists: Bool = false

  
  // MARK: - NodeRepresentable
  
  public init(node: Node, in context: Context) throws {
    id = try node.extract(TableColumnKeys.id)
    imageURL = try node.extract(TableColumnKeys.imageURL)
    priceHourly = try node.extract(TableColumnKeys.priceHourly)
    priceSquareFoot = try node.extract(TableColumnKeys.priceSquareFoot)
    productDescription = try node.extract(TableColumnKeys.productDescription)
    title = try node.extract(TableColumnKeys.title)
    type = try ProductType.instance(from: node, key: TableColumnKeys.type)
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try Node(node: [
      TableColumnKeys.id: id,
      TableColumnKeys.imageURL: imageURL,
      TableColumnKeys.priceHourly: priceHourly,
      TableColumnKeys.priceSquareFoot: priceSquareFoot,
      TableColumnKeys.productDescription: productDescription,
      TableColumnKeys.title: title,
      TableColumnKeys.type: type.rawValue
    ])
  }
  
  
  // MARK: - Preparation
  
  public class func prepare(_ database: Database) throws {
    try database.create(entity) { table in
      table.id()
      table.string(TableColumnKeys.imageURL, length: nil, optional: true, unique: false, default: nil)
      table.double(TableColumnKeys.priceHourly)
      table.double(TableColumnKeys.priceSquareFoot)
      table.string(TableColumnKeys.productDescription)
      table.string(TableColumnKeys.title)
      table.string(TableColumnKeys.type)
    }    
  }
  
  public class func revert(_ database: Database) throws {
    try database.delete(entity)
  }
}


// MARK: - Request + Product

extension Request {
  
  func product() throws -> Product {
    guard let json = json else { throw Abort.badRequest }
    return try Product(node: json)
  }
}
