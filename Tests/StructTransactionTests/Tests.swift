import StructTransaction
import Testing

@Suite("Tests")
struct Tests {

//  @Test
//  func tracking_stored_property() {
//
//    var original = MyState.init()
//
//    let result = withTracking {
//      original.height = 100
//    }
//
//    #expect(result.writeIdentifiers.contains(.init(keyPath: \MyState.height)))
//
//  }
//  
//  @Test
//  func tracking_write_nested_stored_property() {
//    
//    var original = MyState.init()
//        
//    let result = withTracking {
//      original.nested.name = "AAA"
//    }
//    
//    #expect(result.writeIdentifiers.contains(.init(keyPath: \MyState.nested)))
//    #expect(result.writeIdentifiers.contains(.init(keyPath: \MyState.nested.name)))
//    
//  }
//  
//  @Test
//  func tracking_read_nested_stored_property() {
//    
//    let original = MyState.init()
//    
//    original.startTracking()    
//    let result = withTracking {
//      _ = original.nested.name
//    }
//    original.endTracking()
//    
//    #expect(result.readIdentifiers.contains(.init(keyPath: \MyState.nested)))
//    #expect(result.readIdentifiers.contains(.init(keyPath: \MyState.nested.name)))
//    
//  }
  
  @Test  
  func tracking_nest() {
        
    let original = Nesting.init()
        
    let result = original.tracking {
      _ = original.next?.next?.value
    }
    
    #expect(result.readIdentifiers.contains(.init("StructTransactionTests.Nesting.next.next.value")))
  }
  
  @Test  
  func tracking_nest_detaching() {
    
    let original = Nesting.init()
    
    let result = original.tracking {
      let sub = original.next
      
      _ = sub?.next?.value
    }
    
    #expect(result.readIdentifiers.contains(.init("StructTransactionTests.Nesting.next.next.value")))
    
  }
  
  @Test  
  func tracking_nest_write() {
    
    var original = Nesting.init()
    
    let result = original.tracking {
      original.next?.next?.value = "AAA"      
    }
    
    print(result.writeIdentifiers)
    
    #expect(
      result.writeIdentifiers.contains(.init("StructTransactionTests.Nesting.next.next.value"))
    )
    
  }
  
  @Test  
  func tracking_nest_detaching_write() {
    
    let original = Nesting.init()
    
    let result = original.tracking {
      var sub = original.next
      
      sub?.next?.value = "AAA"
    }
    
    print(result.writeIdentifiers)
    
    #expect(
      result.writeIdentifiers.contains(.init("StructTransactionTests.Nesting.next.next.value"))
    )
    
  }
  
//  @Test
//  func modify_endpoint() {
//    
//    var original = MyState.init()
//    
//    func update(_ value: inout String) {
//      value = "AAA"    
//    }
//    
//    let result = withTracking {
//      update(&original.nested.name)
//    }
//
//    #expect(result.writeIdentifiers.contains(.init(keyPath: \MyState.nested)))
//    #expect(result.writeIdentifiers.contains(.init(keyPath: \MyState.nested.name)))
//  }
//
//  @Test
//  func tracking_computed_property() {
//
//    let original = MyState.init()
//
//    let result = withTracking {
//      let _ = original.computedName
//    }
//
//    #expect(result.readIdentifiers.contains(.init(keyPath: \MyState.name)))
//
//  }
//  
//  @Test
//  func cow() {
//    
//    let original = MyState.init()
//
//    var copy = original
//    
//    copy.height = 100
//    
//    #expect(copy.height == 100)
//    #expect(original.height == 0)
//  }
}
