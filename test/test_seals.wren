// test_seals.wren — Comprehensive tests for all seal types.
//
// Seals are typed markers that tell the resolver how to treat a param:
//   Interface  -> resolve by rule key
//   Value      -> pass through as-is
//   Factory    -> call function, inject result
//   ClassFactory -> instantiate class, inject result

// --- Test classes ---
class Logger {
  construct new() {}
  level { "INFO" }
}

class Config {
  construct new(env) {
    _env = env
  }
  env { _env }
}

class MultiArg {
  construct new(a, b, c) {
    _a = a
    _b = b
    _c = c
  }
  a { _a }
  b { _b }
  c { _c }
}

class Counter {
  construct new() {
    _count = 0
  }
  count { _count }
  increment() { _count = _count + 1 }
}

// --- Imports ---
import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface, Value, Factory, ClassFactory

// --- Tests ---
Testie.test("Seals") { |it|

  it.test("Interface seal resolves by rule key") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var svcRule = Rule.new()
    svcRule.classDef = Config
    svcRule.params = [Interface.new("Logger")]
    container.addRule("Config", svcRule)

    var cfg = container.get("Config")
    Expect.that(cfg.env is Logger).toBe(true)
  }

  it.test("Value seal passes literal through") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [Value.new("staging")]
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env).toBe("staging")
  }

  it.test("Value seal preserves numbers") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [Value.new(42)]
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env).toBe(42)
  }

  it.test("Value seal preserves booleans") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [Value.new(true)]
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env).toBe(true)
  }

  it.test("Value seal preserves lists") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [Value.new([1, 2, 3])]
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env[0]).toBe(1)
    Expect.that(cfg.env[2]).toBe(3)
  }

  it.test("Factory seal calls function and injects result") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [Factory.new { Logger.new() }]
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env is Logger).toBe(true)
  }

  it.test("Factory seal creates new instance each time") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [Factory.new { Counter.new() }]
    container.addRule("Config", rule)

    var a = container.get("Config")
    var b = container.get("Config")
    // Each Factory call returns a new Counter
    Expect.that(a.env).toNotBe(b.env)
    a.env.increment()
    Expect.that(a.env.count).toBe(1)
    Expect.that(b.env.count).toBe(0)
  }

  it.test("ClassFactory seal instantiates class") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [ClassFactory.new(Logger)]
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env is Logger).toBe(true)
  }

  it.test("ClassFactory creates new instance each time") {
    var container = Container.new()

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = [ClassFactory.new(Counter)]
    container.addRule("Config", rule)

    var a = container.get("Config")
    var b = container.get("Config")
    Expect.that(a.env).toNotBe(b.env)
  }

  it.test("mixed seals in params list") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var rule = Rule.new()
    rule.classDef = MultiArg
    rule.params = [
      Interface.new("Logger"),
      Value.new("literal"),
      ClassFactory.new(Counter)
    ]
    container.addRule("Multi", rule)

    var multi = container.get("Multi")
    Expect.that(multi.a is Logger).toBe(true)
    Expect.that(multi.b).toBe("literal")
    Expect.that(multi.c is Counter).toBe(true)
  }

  it.test("plain string param treated as interface") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var rule = Rule.new()
    rule.classDef = Config
    rule.params = ["Logger"]  // plain string = resolve by key
    container.addRule("Config", rule)

    var cfg = container.get("Config")
    Expect.that(cfg.env is Logger).toBe(true)
  }
}
