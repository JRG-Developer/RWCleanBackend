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


public final class ProductsController {
  
  public func addRoutes(drop: Droplet) {
    let group = drop.grouped("products")
    group.get(handler: index)
    group.get(Product.self, handler: index)
    group.get("business", handler: businessProducts)
    group.get("home", handler: homeProducts)
    group.post(handler: create)
    group.delete(Product.self, handler: delete)
    group.patch(Product.self, handler: update)
  }
  
  internal func index(request: Request) throws -> ResponseRepresentable {
    let query = try Product.query().sort(Product.TableColumnKeys.id, .ascending)
    return try query.all().makeJSON()
  }
  
  internal func index(request: Request, product: Product) throws -> ResponseRepresentable {
    return try product.makeJSON()
  }
  
  internal func create(request: Request) throws -> ResponseRepresentable {
    try request.verifyIsAuthorizedAdmin()
    var product = try request.product()
    try product.save()
    return try product.makeJSON()
  }
  
  internal func delete(request: Request, product: Product) throws -> ResponseRepresentable {
    try request.verifyIsAuthorizedAdmin()
    try product.delete()
    return JSON([:])
  }
  
  internal func update(request: Request, product: Product) throws -> ResponseRepresentable {
    try request.verifyIsAuthorizedAdmin()
    let new = try request.product()
    var product = product
    product.update(new)
    try product.save()
    return product
  }
  
  internal func businessProducts(request: Request) throws -> ResponseRepresentable {
    let tableKey = Product.TableColumnKeys.type
    let tableValue = Product.ProductType.business.rawValue
    let query = try Product.query().filter(tableKey, tableValue).sort(Product.TableColumnKeys.id, .ascending)
    return try JSON(node: query.all().makeNode())
  }
  
  internal func homeProducts(request: Request) throws -> ResponseRepresentable {
    let tableKey = Product.TableColumnKeys.type
    let tableValue = Product.ProductType.home.rawValue
    let query = try Product.query().filter(tableKey, tableValue).sort(Product.TableColumnKeys.id, .ascending)
    return try JSON(node: query.all().makeNode())
  }
}
