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

import Auth
import Fluent
import HTTP
import Turnstile
import Vapor


public final class RWUserController {
  
  public func addRoutes(drop: Droplet) {
    
    drop.post("login", handler: login)
    drop.get("logout", handler: logout)
    
    drop.group("quotes") { quotes in
      quotes.get(handler: getQuotes)
      quotes.post("product", Product.self, handler: postQuote)
    }
    
    let group = drop.grouped("users")
    group.get(handler: index)
    group.post(handler: register)
    group.get(RWUser.self, handler: index)
    
    group.get("homeInfo", handler: getHomeInfo)
    group.put("homeInfo", handler: putHomeInfo)
  }
  
  // MARK: - Index Users
  
  internal func index(request: Request) throws -> ResponseRepresentable {
    try request.verifyIsAuthorizedAdmin()
    return try RWUser.all().makeJSON()
  }
  
  internal func index(request: Request, user: RWUser) throws -> ResponseRepresentable {
    try request.verifyIsAuthorized(user)
    return try user.makeJSON()
  }
  
  
  // MARK: - Login & Logout
  
  internal func login(request: Request) throws -> ResponseRepresentable {
    do {
      let json = try request.basicUser().makeJSON()
      return json
    } catch let error {
      print("Login failed: \(error)")
      throw error
    }
  }
  
  internal func logout(request: Request) throws -> ResponseRepresentable {
    try request.auth.logout()
    return try JSON(node: [])
  }
  
  internal func register(request: Request) throws -> ResponseRepresentable {
    guard let json = request.json else {
      throw Abort.badRequest
    }
    let user = try RWUser.register(email: try json.extract(RWUser.TableColumnKey.email),
                                   firstName: try json.extract(RWUser.TableColumnKey.firstName),
                                   lastName: try json.extract(RWUser.TableColumnKey.lastName),
                                   password: try json.extract(RWUser.TableColumnKey.password),
                                   phoneNumber: try json.extract(RWUser.TableColumnKey.phoneNumber))
    return try user.makeJSON()
  }
  
  
  // MARK: - HomeInfo
  
  internal func getHomeInfo(request: Request) throws -> ResponseRepresentable {
    let user = try request.basicUser()
    try request.verifyIsAuthorized(user)
    guard let query = try? HomeInfo.query().filter(HomeInfo.TableColumnKey.userID, user.id!),
      let queryResult = try? query.first(),
      let homeInfo = queryResult else {
      throw Abort.notFound
    }
    return try homeInfo.makeJSON()
  }
  
  internal func putHomeInfo(request: Request) throws -> ResponseRepresentable {
    let user = try request.basicUser()
    try request.verifyIsAuthorized(user)
    guard let json = request.json else { throw Abort.badRequest }
    let homeInfo = try HomeInfo.instance(bathroomCount: try json.extract(HomeInfo.TableColumnKey.bathroomCount),
                                         bedroomCount: try json.extract(HomeInfo.TableColumnKey.bedroomCount),
                                         kitchenSize: try json.extract(HomeInfo.TableColumnKey.kitchenSize),
                                         otherRoomsCount: try json.extract(HomeInfo.TableColumnKey.otherRoomsCount),
                                         squareFootage: try json.extract(HomeInfo.TableColumnKey.squareFootage),
                                         user: user)
    return try homeInfo.makeJSON()
  }
  
  
  // MARK: - QuoteRequest
  
  internal func getQuotes(request: Request) throws -> ResponseRepresentable {
    let user = try request.basicUser()
    try request.verifyIsAuthorized(user)
    guard let quotes = try user.quotes(), !quotes.isEmpty else {
      throw Abort.notFound
    }
    
    let publicQuoteNotes: [Node] = try quotes.map { try $0.makePublicNode() }
    return try JSON(node: publicQuoteNotes.makeNode())
  }
  
  internal func postQuote(request: Request, product: Product) throws -> ResponseRepresentable {
    let user = try request.basicUser()
    try request.verifyIsAuthorized(user)
    let quote = try QuoteRequest.instance(user: user, product: product)
    return try JSON(node: quote.makePublicNode())
  }
}
