// test_error_handling.wren — Tests for error conditions.
// The resolver uses Fiber.abort for all error conditions.
// Tests verify exact error messages for predictable debugging.

class A { construct new(b) { _b = b } }
class B { construct new(a) { _a = a } }
class C { construct new(d) { _d = d } }
class D { construct new(c) { _c = c } }
class Simple { construct new() {} }

import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface

Testie.test("Error Handling") { |it|

  it.test("missing rule aborts with key name") {
    var container = Container.new()
    Expect.that { container.get("Missing") }.toAbortWith("No rule found for key: Missing")
  }

  it.test("cyclic dependency of two nodes") {
    var container = Container.new()

    var aRule = Rule.new()
    aRule.classDef = A
    aRule.params = [Interface.new("B")]
    container.addRule("A", aRule)

    var bRule = Rule.new()
    bRule.classDef = B
    bRule.params = [Interface.new("A")]
    container.addRule("B", bRule)

    Expect.that { container.get("A") }.toAbortWith("Cyclic dependency detected: key 'A' already in stack [A, B]")
  }

  it.test("cyclic dependency of three nodes") {
    var container = Container.new()

    var aRule = Rule.new()
    aRule.classDef = A
    aRule.params = [Interface.new("B")]
    container.addRule("A", aRule)

    var bRule = Rule.new()
    bRule.classDef = B
    bRule.params = [Interface.new("C")]
    container.addRule("B", bRule)

    var cRule = Rule.new()
    cRule.classDef = C
    cRule.params = [Interface.new("A")]
    container.addRule("C", cRule)

    Expect.that { container.get("A") }.toAbortWith("Cyclic dependency detected: key 'A' already in stack [A, B, C]")
  }

  it.test("self-referential rule aborts") {
    var container = Container.new()

    var aRule = Rule.new()
    aRule.classDef = A
    aRule.params = [Interface.new("A")]
    container.addRule("A", aRule)

    Expect.that { container.get("A") }.toAbortWith("Cyclic dependency detected: key 'A' already in stack [A]")
  }

  it.test("missing inherited parent rule aborts") {
    var container = Container.new()

    var child = Rule.new()
    child.inheritInstanceOf = "Missing"
    child.classDef = Simple
    container.addRule("Child", child)

    Expect.that { container.get("Child") }.toAbortWith("Inherit rule not found: Missing")
  }
}
