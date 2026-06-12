// test_inheritance.wren — Tests for rule inheritance (inheritInstanceOf).
//
// When a rule specifies inheritInstanceOf, it merges with its parent rule.
// Scalar fields: child overrides. Collections: concatenate. Maps: merge.

class Logger {
  construct new() {}
}

class BaseService {
  construct new(logger) { _logger = logger }
  logger { _logger }
  name { "Base" }
}

class ExtendedService {
  construct new(logger, extra) {
    _logger = logger
    _extra = extra
  }
  logger { _logger }
  extra { _extra }
  name { "Extended" }
}

class SimpleService {
  construct new() {}
}

import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface, Value

Testie.test("Rule Inheritance") { |it|

  it.test("child inherits classDef from parent") {
    var container = Container.new()

    var parent = Rule.new()
    parent.classDef = BaseService
    container.addRule("Base", parent)

    var child = Rule.new()
    child.inheritInstanceOf = "Base"
    child.classDef = SimpleService
    container.addRule("Child", child)

    var instance = container.get("Child")
    Expect.that(instance is SimpleService).toBe(true)
  }

  it.test("child inherits params from parent") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var parent = Rule.new()
    parent.classDef = BaseService
    parent.params = [Interface.new("Logger")]
    container.addRule("Base", parent)

    var child = Rule.new()
    child.inheritInstanceOf = "Base"
    child.classDef = ExtendedService
    child.params = [Value.new("extra")]
    container.addRule("Child", child)

    var instance = container.get("Child")
    Expect.that(instance.logger is Logger).toBe(true)
    Expect.that(instance.extra).toBe("extra")
  }

  it.test("child shared overrides parent") {
    var container = Container.new()

    var parent = Rule.new()
    parent.classDef = Logger
    parent.shared = true
    container.addRule("Base", parent)

    var child = Rule.new()
    child.inheritInstanceOf = "Base"
    child.classDef = Logger
    child.shared = false
    container.addRule("Child", child)

    var a = container.get("Child")
    var b = container.get("Child")
    Expect.that(a == b).toBe(false)
  }

  it.test("child singleton overrides parent shared") {
    var instance = Logger.new()
    var container = Container.new()

    var parent = Rule.new()
    parent.classDef = Logger
    parent.shared = true
    container.addRule("Base", parent)

    var child = Rule.new()
    child.inheritInstanceOf = "Base"
    child.singleton = instance
    container.addRule("Child", child)

    var got = container.get("Child")
    Expect.that(got).toBe(instance)
  }

  it.test("grandchild inherits from grandparent") {
    var container = Container.new()

    var grandparent = Rule.new()
    grandparent.classDef = Logger
    grandparent.shared = true
    container.addRule("Grand", grandparent)

    var parent = Rule.new()
    parent.inheritInstanceOf = "Grand"
    parent.classDef = Logger
    container.addRule("Parent", parent)

    var child = Rule.new()
    child.inheritInstanceOf = "Parent"
    child.classDef = Logger
    child.shared = false
    container.addRule("Child", child)

    var a = container.get("Child")
    var b = container.get("Child")
    Expect.that(a == b).toBe(false)
  }

  it.test("missing parent rule aborts") {
    var container = Container.new()
    var child = Rule.new()
    child.inheritInstanceOf = "Missing"
    child.classDef = Logger
    container.addRule("Child", child)

    Expect.that { container.get("Child") }.toAbortWith("Inherit rule not found: Missing")
  }
}
