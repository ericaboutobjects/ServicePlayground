//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

func curriedAdd(x: Int)(y: Int) -> Int {
    return x + y
}

curriedAdd(5)

final class Box<T> {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

enum Result<A> {
    case Error(NSError)
    case Value(Box<A>)
    
    init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(Box(value))
        }
    }
}

infix operator >>> { associativity left precedence 150 } // bind
infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

infix operator <|  { associativity left precedence 150 }
infix operator <|* { associativity left precedence 150 }

func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x.value)
    case let .Error(error): return .Error(error)
    }
}

func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}

func pure<A>(a: A) -> A? {
    return .Some(a)
}

//func <|<A>(object: JSONObject, key: String) -> A? {
//    return object[key] >>> _JSONParse
//}
//
//func <|*<A>(object: JSONObject, key: String) -> A?? {
//    return pure(object[key] >>> _JSONParse)
//}

func foo (string: String) -> String?{
    return string + "bar";
}

var bar = "foobar"

let foobar = bar >>> foo >>> foo
