
/**
 Available only for structs
 */
@attached(
  memberAttribute
)
public macro Tracking() = #externalMacro(module: "StructTransactionMacros", type: "TrackingMacro")

@attached(
  accessor, 
  names: named(willSet)
)
public macro TrackingIgnored() = #externalMacro(module: "StructTransactionMacros", type: "TrackingIgnoredMacro")

@attached(
  accessor, 
  names: named(init), named(get), named(set), named(_modify)
)
@attached(peer, names: prefixed(`_backing_`))
public macro TrackingProperty() = #externalMacro(module: "StructTransactionMacros", type: "TrackingPropertyMacro")

@attached(
  accessor, 
  names: named(init), named(get), named(set), named(_modify)
)
@attached(peer, names: prefixed(`_backing_`))
public macro COWTrackingProperty() = #externalMacro(module: "StructTransactionMacros", type: "COWTrackingPropertyMacro")

public struct AccessingResult {

  public let readIdentifiers: Set<String>
  public let modifiedIdentifiers: Set<String>

  public init(
    readIdentifiers: Set<String>,
    modifiedIdentifiers: Set<String>
  ) {
    self.readIdentifiers = readIdentifiers
    self.modifiedIdentifiers = modifiedIdentifiers
  }
}



@Tracking
struct MyState {
  
  init() {
    stored_2 = 0
  }
  
  var stored_1: Int = 18
  
  var stored_2: Int
  
  var computed_1: Int {
    stored_1
  }
  
  var subState: MySubState = .init()
  
}


@Tracking
struct MySubState {
  
  var stored_1: Int = 18
  
  var computed_1: Int {
    stored_1
  }
  
  init() {
    
  }
  
}

#if canImport(Observation)
import Observation

@available(macOS 14.0, iOS 17.0, tvOS 15.0, watchOS 8.0, *)
@Observable
class Hoge {
    
  let stored: Int
  
  var stored_2: Int
  
  init(stored: Int) {
    self.stored = stored
    self.stored_2 = stored
  }
}
#endif
