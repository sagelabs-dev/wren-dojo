// test_dojo_api.wren — Tests for the public Dojo API module.
// This is the user-facing entry point: convenience static methods.

class Logger {
  construct new() {}
  level { "INFO" }
}

class Service {
  construct new(logger) { _logger = logger }
  logger { _logger }
}

import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/dojo" for Dojo
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface, Value, Factory, ClassFactory

Testie.test("Dojo API") { |it|

  it.test("Dojo.container() returns a Container") {
    var container = Dojo.container()
    Expect.that(container is Container).toBe(true)
  }

  it.test("Dojo.interface() creates an Interface seal") {
    var seal = Dojo.interface("Logger")
    Expect.that(seal is Interface).toBe(true)
    Expect.that(seal.key).toBe("Logger")
  }

  it.test("Dojo.value() creates a Value seal") {
    var seal = Dojo.value("hello")
    Expect.that(seal is Value).toBe(true)
    Expect.that(seal.value).toBe("hello")
  }

  it.test("Dojo.value() preserves numbers") {
    var seal = Dojo.value(42)
    Expect.that(seal.value).toBe(42)
  }

  it.test("Dojo.factory() creates a Factory seal") {
    var fn = Fn.new { Logger.new() }
    var seal = Dojo.factory(fn)
    Expect.that(seal is Factory).toBe(true)
  }

  it.test("Dojo.classFactory() creates a ClassFactory seal") {
    var seal = Dojo.classFactory(Logger)
    Expect.that(seal is ClassFactory).toBe(true)
    Expect.that(seal.classDef).toBe(Logger)
  }

  it.test("end-to-end with Dojo helpers") {
    var container = Dojo.container()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    loggerRule.shared = true
    container.addRule("Logger", loggerRule)

    var svcRule = Rule.new()
    svcRule.classDef = Service
    svcRule.params = [Dojo.interface("Logger")]
    container.addRule("Service", svcRule)

    var svc = container.get("Service")
    Expect.that(svc.logger is Logger).toBe(true)
  }
}
