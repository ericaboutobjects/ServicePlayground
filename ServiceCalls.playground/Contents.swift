//: Playground - noun: a place where people can play

import UIKit
import XCPlayground

var str = "Hello, playground"

public typealias JSON = AnyObject
public typealias JSONObject = [String: AnyObject]
public typealias JSONArray = [AnyObject]


protocol Request{
    func serializeToJSON() -> NSData
}

struct CartRequest: Request {
    var cartId: String
    
    init(cartId: String ) {
        self.cartId = cartId
    }

    func serializeToJSON() -> NSData {
        let dict = ["id": self.cartId]
        return try! NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }
}

protocol Response {
    static func decodeJSON(json: JSON) throws -> Self
}

struct Cart{
    var cartId: String
    var total: Double
    
    init(cartId: String, total: Double){
        self.cartId = cartId
        self.total = total
    }
}

extension Cart: Response{
    static func decodeJSON(json: JSON) throws -> Cart{
        
        //very simple case here, not meant to be illustrative of best
        //way to parse JSON
        guard case let (cartId as String, total as Double) = (json["cartId"],json["total"]) else {
                throw NSError(domain: "com.me.domain", code: 0, userInfo: [NSUnderlyingErrorKey: "Failed to decode: \(json)"])
        }
        return Cart(cartId: cartId, total: total)
    }
}

enum Result<A> {
    case Error(NSError)
    case Value(A)
    
    init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(value)
        }
    }
}

protocol Service{
    func performRequest<A: Response>(request: NSURLRequest, callback: Result<A> -> ())
    func parseResult<A: Response>(data: NSData) throws -> A
}

extension Service{
    func performRequest<A: Response>(request: NSURLRequest, callback: Result<A> -> ()) {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, urlResponse, error in
            print(data)
            guard let data = data else {
                let downloadError = error ?? NSError(domain: "com.me.domain", code: 0, userInfo: [NSLocalizedDescriptionKey: "The request \(request) failed."])
                callback(Result.Error(downloadError))
                return
            }
            do {
                callback(Result.Value(try self.parseResult(data)))
            }
            catch {
                callback(Result.Error(error as NSError))
            }
        }
        task.resume()
    }
    
    func decodeJSON(data: NSData) throws -> AnyObject {
        return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
    }
    
    func decodeObject<U: Response>(json: JSON) throws -> U {
        return try U.decodeJSON(json)
    }
    
    func parseResult<A: Response>(data: NSData) throws -> A {
        let json = try decodeJSON(data)
        return try decodeObject(json)
    }
}

class CartService: Service{

    func fetchCart(cartRequest: CartRequest, completion: Result<Cart> -> ()){
        let url = NSURL(string: "http://com.me.domain/cart")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        request.addValue("text/json", forHTTPHeaderField: "Content-Type")
        request.addValue("text/json", forHTTPHeaderField: "Accept")
        request.HTTPShouldHandleCookies = true
        request.HTTPBody = cartRequest.serializeToJSON()

        performRequest(request) { (result: Result<Cart>) -> () in
            switch result {
            case let .Value(cart):
                
                //do some work
                print(cart.cartId)
                
                completion(result)
            default:
                completion(result)
            }
        }
    }
}

class PlaygroundURLProtocol: NSURLProtocol {
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL!.scheme == "http" || request.URL!.scheme == "https" ? true : false
    }
    
    func loadData(forRequest request: NSURLRequest) -> NSData? {
        var URLPath = request.URL?.path
        URLPath = URLPath?.stringByReplacingOccurrencesOfString("/", withString: "_")
        if let filePath = NSBundle.mainBundle().pathForResource(URLPath, ofType: "json"){
            return NSData(contentsOfFile: filePath)
        }
        return nil
    }
    
    override func startLoading() {
        let client = self.client
        let request = self.request
        
        if let data = loadData(forRequest: request){
            let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields:nil)
            client!.URLProtocol(self, didReceiveResponse: response!, cacheStoragePolicy: .NotAllowed)
            client!.URLProtocol(self, didLoadData: data)
            client!.URLProtocolDidFinishLoading(self)
        }
        else {
            client!.URLProtocol(self, didFailWithError: NSError(domain: "", code: 404, userInfo: nil))
        }
    }
    
    override class func requestIsCacheEquivalent(aRequest: NSURLRequest, toRequest bRequest: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest { return request }
    
    override func stopLoading() { }
}

NSURLProtocol.registerClass(PlaygroundURLProtocol)


let cartService = CartService()

cartService.fetchCart(CartRequest(cartId: "23232")) { (result) -> () in
    switch result {
    case let .Value(cart):
        print("Cart : \(cart)")

    case let .Error(error):
        print("Error :" + error.localizedDescription)
    }
}


XCPSetExecutionShouldContinueIndefinitely(true)











