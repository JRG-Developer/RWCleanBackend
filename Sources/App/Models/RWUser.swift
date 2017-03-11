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
import HTTP
import Vapor
import Turnstile
import TurnstileCrypto


public final class RWUser: Model, User {
  
  // MARK: - Constants
  
  internal struct TableColumnKey {
    static let id = "id"
    static let email = "email"
    static let firstName = "first_name"
    static let isAdmin = "admin"
    static let password = "password"
    static let phoneNumber = "phone_number"
    static let lastName = "last_name"
  }
  
  
  // MARK: - Intance Properties
  
  public var email: Valid<EmailValidator>
  public var isAdmin: Bool = false
  public var firstName: String
  public var lastName: String
  public var password: String
  public var phoneNumber: Valid<PhoneNumberValidator>
  
  
  // MARK: - Object Lifecycle
  
  private init(email: String,
               firstName: String,
               lastName: String,
               password: String,
               phoneNumber: String) throws {
    self.firstName = firstName
    self.lastName = lastName
    self.email = try email.validated()
    self.password = BCrypt.hash(password: password)
    self.phoneNumber = try phoneNumber.validated()
  }
  
  
  // MARK: - Authenticator
  
  public static func authenticate(credentials: Credentials) throws -> User {
    
    guard let credentials = credentials as? APIKey else {
      throw UnsupportedCredentialsError()
    }
    
    let email = credentials.id
    let password = credentials.secret
    
    guard let fetchedUser = try RWUser.query().filter(TableColumnKey.email, email).first(),
      try BCrypt.verify(password: password, matchesHash: fetchedUser.password) else {
        throw AuthError.invalidBasicAuthorization.abortError
    }
    return fetchedUser
  }
  
  public class func register(credentials: Credentials) throws -> User {
    throw Abort.badRequest
  }
  
  public class func register(email: String,
                             firstName: String,
                             lastName: String,
                             password: String,
                             phoneNumber: String) throws -> RWUser {
    
    var newUser = try RWUser(email: email,
                             firstName: firstName,
                             lastName: lastName,
                             password: password,
                             phoneNumber: phoneNumber)
    
    let query = try RWUser.query().filter(TableColumnKey.email, newUser.email.value)
    guard try query.first() == nil else {      
      throw AccountTakenError()
    }
    
    try newUser.save()
    return newUser
  }
  
  
  // MARK: - Entity
  
  public var exists: Bool = false
  public var id: Node? = nil
  
  
  // MARK: - NodeRepresentable
  
  public init(node: Node, in context: Context) throws {
    id = try node.extract(TableColumnKey.id)
    email = try (node.extract(TableColumnKey.email) as String).validated()
    firstName = try node.extract(TableColumnKey.firstName)
    isAdmin = try node.extract(TableColumnKey.isAdmin)
    lastName = try node.extract(TableColumnKey.lastName)
    password = try node.extract(TableColumnKey.password)
    phoneNumber = try (node.extract(TableColumnKey.phoneNumber) as String).validated()
  }
  
  public func makeNode(context: Context) throws -> Node {
    return try Node(node: [
      TableColumnKey.id: id ?? nil,
      TableColumnKey.email: email.value,
      TableColumnKey.firstName: firstName,
      TableColumnKey.isAdmin: isAdmin,
      TableColumnKey.lastName: lastName,
      TableColumnKey.password: password,
      TableColumnKey.phoneNumber: phoneNumber.value
      ])
  }
  
  public func makePublicNode() throws -> Node {
    guard var nodeObject = try self.makeNode().nodeObject else {
      throw Abort.badRequest
    }    
    nodeObject.removeValue(forKey: TableColumnKey.password)
    return try Node(node: nodeObject)
  }
  
  public func makeJSON() throws -> JSON {
    return try JSON(node: makePublicNode())
  }
  
  
  // MARK: - Preparation
  
  public class func prepare(_ database: Database) throws {
    try database.create(entity) { table in
      table.id()
      table.string(TableColumnKey.email)
      table.string(TableColumnKey.firstName)
      table.bool(TableColumnKey.isAdmin)
      table.string(TableColumnKey.lastName)
      table.string(TableColumnKey.password)
      table.string(TableColumnKey.phoneNumber)
    }
  }
  
  public class func revert(_ database: Database) throws {
    try database.delete(entity)
  }
}


// MARK: - User + Relations

extension User {
  
  public func homeInfo() -> HomeInfo? {
    guard let query = try? HomeInfo.query().filter(HomeInfo.TableColumnKey.userID, id!),
      let queryResult = try? query.first(),
      let homeInfo = queryResult else {
        return nil
    }
    return homeInfo
  }
  
  public func quotes() throws -> [QuoteRequest]? {    
    let query = try QuoteRequest.query().filter(QuoteRequest.TableColumnKey.userID, id!)
    return try query.all()
  }
}


// MARK: - Request + User

extension Request {
  
  public func basicUser() throws -> RWUser {
    if let authUser = try? auth.user(), let user = authUser as? RWUser {
      return user
    }
    guard let credentials = auth.header?.basic else {
      throw AuthError.notAuthenticated.abortError
    }
    try auth.login(credentials)
    return try auth.user() as! RWUser
  }
  
  public func verifyIsAuthorized(_ user: RWUser) throws {
    let authUser = try basicUser()
    guard authUser.isAdmin || authUser.id == user.id else {
      throw AuthError.invalidAccountType.abortError
    }
  }
  
  public func verifyIsAuthorizedAdmin() throws {
    let authUser = try basicUser()
    guard authUser.isAdmin else {
      throw AuthError.invalidAccountType.abortError
    }
  }
}
