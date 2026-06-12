// Test classes defined BEFORE tests (Wren top-to-bottom evaluation)
class Logger {
  construct new() {}
  log(msg) { System.print(msg) }
}

class SimpleService {
  construct new() {}
}

class MyService {
  construct new(logger) {
    _logger = logger
  }
  logger { _logger }
}

class A {
  construct new(b) { _b = b }
}

class B {
  construct new(a) { _a = a }
}

// Imports
import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface

// Tests
Testie.test("Container") { |it|

  it.test("can add and retrieve a rule") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Logger
    container.addRule("Logger", rule)
    Expect.that(container.has("Logger")).toBe(true)
    Expect.that(container.has("Service")).toBe(false)
  }

  it.test("can resolve a simple class") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = SimpleService
    container.addRule("Service", rule)
    var svc = container.get("Service")
    Expect.that(svc is SimpleService).toBe(true)
  }

  it.test("can resolve with params") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var svcRule = Rule.new()
    svcRule.classDef = MyService
    svcRule.params = [Interface.new("Logger")]
    container.addRule("Service", svcRule)

    var svc = container.get("Service")
    Expect.that(svc.logger is Logger).toBe(true)
  }

  it.test("shared returns same instance") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Logger
    rule.shared = true
    container.addRule("Logger", rule)
    var a = container.get("Logger")
    var b = container.get("Logger")
    Expect.that(a).toBe(b)
  }

  it.test("singleton returns pre-built instance") {
    var logger = Logger.new()
    var container = Container.new()
    var rule = Rule.new()
    rule.singleton = logger
    container.addRule("Logger", rule)
    var got = container.get("Logger")
    Expect.that(got).toBe(logger)
  }

  it.test("detects cyclic dependency") {
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

  it.test("detects missing rule") {
    var container = Container.new()
    Expect.that { container.get("Missing") }.toAbortWith("No rule found for key: Missing")
  }
}
