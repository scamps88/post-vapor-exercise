//
//  MyToken.swift
//  HelloPackageDescription
//
//  Created by Alberto Scampini on 11.10.17.
//

import Vapor
import FluentProvider
import Crypto

final class MyToken: Model {
    let storage = Storage()

    let token: String
    let userId: Identifier

    var user: Parent<MyToken, MyUser> {
        return parent(id: userId)
    }

    /// Creates a new Token
    init(string: String, user: MyUser) throws {
        token = string
        userId = try user.assertExists()
    }

    // MARK: Row

    init(row: Row) throws {
        token = try row.get("token")
        userId = try row.get(MyUser.foreignIdKey)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("token", token)
        try row.set(MyUser.foreignIdKey, userId)
        return row
    }

}

extension MyToken: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Tokens
    static func prepare(_ database: Database) throws {
        try database.create(MyToken.self) { builder in
            builder.id()
            builder.string("token")
            builder.foreignId(for: MyUser.self)
        }
    }

    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(MyToken.self)
    }
}

extension MyToken {
    /// Generates a new token for the supplied User.
    static func generate(for user: MyUser) throws -> MyToken {
        // generate 128 random bits using OpenSSL
        let random = try Crypto.Random.bytes(count: 16)

        // create and return the new token
        return try MyToken(string: random.base64Encoded.makeString(), user: user)
    }
}
