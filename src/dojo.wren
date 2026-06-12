// dojo.wren — Public API module for wren-dojo
// Import this module to access the dependency injection container.

import "./container" for Container
import "./rule" for Rule
import "./seal" for Seal, Interface, Value, Factory, ClassFactory

class Dojo {
  // Create a new Container instance.
  static container() { Container.new() }
  
  // Convenience: create an Interface seal (resolve by rule key).
  static interface(key) { Interface.new(key) }
  
  // Convenience: create a Value seal (pass through).
  static value(v) { Value.new(v) }
  
  // Convenience: create a Factory seal (call function).
  static factory(fn) { Factory.new(fn) }
  
  // Convenience: create a ClassFactory seal (instantiate class).
  static classFactory(cls) { ClassFactory.new(cls) }
}
