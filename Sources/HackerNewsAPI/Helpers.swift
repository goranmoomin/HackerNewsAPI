
import Foundation

func unwrap<T>(_ expression: @autoclosure () -> T?,
               orThrow errorExpression: @autoclosure () -> Error) throws -> T {
    guard let expression = expression() else {
        throw errorExpression()
    }
    return expression
}

func perform<T>(_ expression: @autoclosure () throws -> T,
                orThrow errorExpression: @autoclosure () -> Error) throws -> T {
    do {
        return try expression()
    } catch {
        throw errorExpression()
    }
}

func perform<T>(_ expression: @autoclosure () throws -> T,
                errorTransform: (Error) -> Error) throws -> T {
    do {
        return try expression()
    } catch {
        throw errorTransform(error)
    }
}
