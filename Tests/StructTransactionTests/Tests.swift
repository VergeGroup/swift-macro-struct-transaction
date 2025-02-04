import StructTransaction
import Testing

@Suite("Tests")
struct Tests {

  @Test
  func tracking_stored_property() {

    var original = MyState.init()

    let result = withTracking {
      original.height = 100
    }

    #expect(result.writeIdentifiers.contains(.init(name: "height")))

  }

  @Test
  func tracking_computed_property() {

    let original = MyState.init()

    let result = withTracking {
      let _ = original.computedName
    }

    #expect(result.readIdentifiers.contains(.init(name: "name")))

  }
  
  @Test
  func cow() {
    
    let original = MyState.init()

    var copy = original
    
    copy.height = 100
    
    #expect(copy.height == 100)
    #expect(original.height == 0)
  }
}
