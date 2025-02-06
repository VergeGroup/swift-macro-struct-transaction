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
      _ = original._1?._2?.value
    }
        
    #expect(
      result.readGraph.prettyPrint() ==
      """
      root {
        _1 {
          _2 {
            value
          }
        }
      }
      """
    )        
  }
  
  @Test  
  func tracking_nest_set() {
    
    var original = Nesting.init()
    
    let result = original.tracking {
      original._1?._1?.value = "AAA"
    }
    
    #expect(
      result.writeGraph.prettyPrint() ==
      """
      root {
        _1 {
          _1 {
            value
          }
        }
      }
      """
    )        
  }
  
  @Test  
  func tracking_nest_detaching() {
    
    let original = Nesting.init()
    
    let result = original.tracking {
      let sub = original._1
      
      _ = sub?._1?.value
    }
    
    #expect(
      result.readGraph.prettyPrint() ==
      """
      root {
        _1 {
          _1 {
            value
          }
        }
      }
      """
    )      
    
  }
  
  @Test  
  func tracking_nest_write_modify() {
    
    var original = Nesting.init()
    
    let result = original.tracking {      
      original._1 = .init(_1: nil, _2: nil, _3: nil)
    }
       
    #expect(
      result.writeGraph.prettyPrint() ==
      """
      root {
        _1
      }
      """
    )   
    
  }
  
  @Test  
  func tracking_nest2_write_modify() {
    
    var original = Nesting.init()
    
    let result = original.tracking {      
      original._1?._1 = .init(_1: nil, _2: nil, _3: nil)
    }
    
    #expect(
      result.writeGraph.prettyPrint() ==
      """
      root {
        _1 {
          _1
        }
      }
      """
    )   
    
  }
  
  @Test 
  func test_cow() {
    var original = Nesting.init()
    original._1?._1?.value = "AAA"
  }
  
  @Test  
  func tracking_nest3_write_modify() {
    
    var original = Nesting.init()
    
    let result = original.tracking {      
      original._1?._1?.value = "AAA"
    }
    
    #expect(
      result.writeGraph.prettyPrint() ==
      """
      root {
        _1 {
          _1 {
            value
          }
        }
      }
      """
    )   
    
  }
    
  /**
   ⚠️ original._1 is not actually modified, but the write graph is still correct
   */
  @Test  
  func tracking_nest_detaching_write() {
    
    let original = Nesting.init()
    
    let result = original.tracking {
      var sub = original._1
      
      sub?._1?.value = "AAA"
    }    
    
    #expect(
      result.writeGraph.prettyPrint() ==
      """
      root {
        _1 {
          _1 {
            value
          }
        }
      }
      """
    )   
    
//    #expect(
//      result.writeIdentifiers.contains(.init("StructTransactionTests.Nesting.next.next.value"))
//    )
    
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
