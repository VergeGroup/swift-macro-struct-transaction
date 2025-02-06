import Testing
import StructTransaction

@Suite("GraphTests")
struct GraphTests {
  
  @Test
  func example() {
    
    var node = PropertyNode(name: "1")
    
    node.apply(path: PropertyPath().pushed(.init("1")).pushed(.init("1")).pushed(.init("1")))
    node.apply(path: PropertyPath().pushed(.init("1")).pushed(.init("2")).pushed(.init("1")))
    node.apply(path: PropertyPath().pushed(.init("1")).pushed(.init("1")).pushed(.init("2")))
    
    print(node.prettyPrint())
    
    #expect(
      node.prettyPrint() ==
      """
      1 {
        1 {
          1
          2
        }
        2 {
          1
        }
      }
      """
    )
    
  }
  
}
