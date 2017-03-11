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

import Vapor


public class PhoneNumberValidator: ValidationSuite {
  
  private static let minimumCharacters = 7
  private static let maximumCharacters = 15
  
  private static let numberic = "0123456789"
  private static let validCharacters = numberic.characters
  
  /// Validate whether or not an input string appears to be a valid number: it must:
  ///   - contain only numeric characters 0...9
  ///   - be at least 7 characters long
  //    - be no more (less than or equal to) 15 characters long
  ///
  /// - Parameter value: input value to validate
  ///
  /// - Throws: an error if validation fails
  public static func validate(input value: String) throws {

    guard value.characters.count > minimumCharacters && value.characters.count <= maximumCharacters else {
      throw error(with: value)
    }
    
    let passed = value.characters.filter(validCharacters.contains).count
    guard passed == value.characters.count else {
      throw error(with: value)
    }
  }
}
