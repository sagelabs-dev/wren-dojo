// test_v15.wren — Tests for v1.5 features:
//   1. Extended arity support (0–8 params)
//   2. Config object pattern (Map as single param)
//   3. Fiber-based async resolution

// ============================================================
// Test domain classes
// ============================================================

class Arity0 {
  construct new() {}
  tag { "arity0" }
}

class Arity1 {
  construct new(a) {
    _a = a
  }
  a { _a }
}

class Arity2 {
  construct new(a, b) {
    _a = a
    _b = b
  }
  a { _a }
  b { _b }
}

class Arity3 {
  construct new(a, b, c) {
    _a = a
    _b = b
    _c = c
  }
  a { _a }
  b { _b }
  c { _c }
}

class Arity4 {
  construct new(a, b, c, d) {
    _a = a
    _b = b
    _c = c
    _d = d
  }
  a { _a }
  b { _b }
  c { _c }
  d { _d }
}

class Arity5 {
  construct new(a, b, c, d, e) {
    _a = a
    _b = b
    _c = c
    _d = d
    _e = e
  }
  a { _a }
  b { _b }
  c { _c }
  d { _d }
  e { _e }
}

class Arity6 {
  construct new(a, b, c, d, e, f) {
    _a = a
    _b = b
    _c = c
    _d = d
    _e = e
    _f = f
  }
  a { _a }
  b { _b }
  c { _c }
  d { _d }
  e { _e }
  f { _f }
}

class Arity7 {
  construct new(a, b, c, d, e, f, g) {
    _a = a
    _b = b
    _c = c
    _d = d
    _e = e
    _f = f
    _g = g
  }
  a { _a }
  b { _b }
  c { _c }
  d { _d }
  e { _e }
  f { _f }
  g { _g }
}

class Arity8 {
  construct new(a, b, c, d, e, f, g, h) {
    _a = a
    _b = b
    _c = c
    _d = d
    _e = e
    _f = f
    _g = g
    _h = h
  }
  a { _a }
  b { _b }
  c { _c }
  d { _d }
  e { _e }
  f { _f }
  g { _g }
  h { _h }
}

// Config object pattern: single Map param, destructure inside constructor
class ConfiguredService {
  construct new(config) {
    _host = config["host"]
    _port = config["port"]
    _debug = config["debug"]
    _timeout = config["timeout"]
  }
  host { _host }
  port { _port }
  debug { _debug }
  timeout { _timeout }
}

// Classes for async resolution tests
class Logger {
  construct new() {}
  level { "INFO" }
}

class Database {
  construct new(logger) {
    _logger = logger
  }
  logger { _logger }
}

class Repository {
  construct new(db, logger) {
    _db = db
    _logger = logger
  }
  db { _db }
  logger { _logger }
}

class Service {
  construct new(repo, logger) {
    _repo = repo
    _logger = logger
  }
  repo { _repo }
  logger { _logger }
}

class AsyncCollector {
  construct new(a, b, c) {
    _a = a
    _b = b
    _c = c
  }
  a { _a }
  b { _b }
  c { _c }
}

// ============================================================
// Imports
// ============================================================

import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface, Value, Factory

// ============================================================
// Arity Tests
// ============================================================

Testie.test("Arity Support") { |it|

  it.test("arity 0 — no params") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity0
    container.addRule("A0", rule)
    var obj = container.get("A0")
    Expect.that(obj.tag).toBe("arity0")
  }

  it.test("arity 1") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity1
    rule.params = [Value.new("one")]
    container.addRule("A1", rule)
    var obj = container.get("A1")
    Expect.that(obj.a).toBe("one")
  }

  it.test("arity 2") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity2
    rule.params = [Value.new(1), Value.new(2)]
    container.addRule("A2", rule)
    var obj = container.get("A2")
    Expect.that(obj.a).toBe(1)
    Expect.that(obj.b).toBe(2)
  }

  it.test("arity 3") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity3
    rule.params = [Value.new(1), Value.new(2), Value.new(3)]
    container.addRule("A3", rule)
    var obj = container.get("A3")
    Expect.that(obj.c).toBe(3)
  }

  it.test("arity 4") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity4
    rule.params = [Value.new(1), Value.new(2), Value.new(3), Value.new(4)]
    container.addRule("A4", rule)
    var obj = container.get("A4")
    Expect.that(obj.d).toBe(4)
  }

  it.test("arity 5") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity5
    rule.params = [Value.new(1), Value.new(2), Value.new(3), Value.new(4), Value.new(5)]
    container.addRule("A5", rule)
    var obj = container.get("A5")
    Expect.that(obj.e).toBe(5)
  }

  it.test("arity 6") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity6
    rule.params = [
      Value.new(1), Value.new(2), Value.new(3),
      Value.new(4), Value.new(5), Value.new(6)
    ]
    container.addRule("A6", rule)
    var obj = container.get("A6")
    Expect.that(obj.f).toBe(6)
  }

  it.test("arity 7") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity7
    rule.params = [
      Value.new(1), Value.new(2), Value.new(3), Value.new(4),
      Value.new(5), Value.new(6), Value.new(7)
    ]
    container.addRule("A7", rule)
    var obj = container.get("A7")
    Expect.that(obj.g).toBe(7)
  }

  it.test("arity 8") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity8
    rule.params = [
      Value.new(1), Value.new(2), Value.new(3), Value.new(4),
      Value.new(5), Value.new(6), Value.new(7), Value.new(8)
    ]
    container.addRule("A8", rule)
    var obj = container.get("A8")
    Expect.that(obj.h).toBe(8)
  }

  it.test("arity 9 aborts with helpful message") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Arity1
    rule.params = [
      Value.new(1), Value.new(2), Value.new(3), Value.new(4),
      Value.new(5), Value.new(6), Value.new(7), Value.new(8), Value.new(9)
    ]
    container.addRule("A9", rule)
    Expect.that { container.get("A9") }.toAbortWith(
      "Instantiation supports max 8 params, got 9. " +
      "Use a Map (config object) as a single param, or the Factory seal for arbitrary arity."
    )
  }
}

// ============================================================
// Config Object Pattern
// ============================================================

Testie.test("Config Object Pattern") { |it|

  it.test("Map as single param destructures correctly") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = ConfiguredService
    rule.params = [Value.new({
      "host": "localhost",
      "port": 8080,
      "debug": true,
      "timeout": 30
    })]
    container.addRule("Service", rule)

    var svc = container.get("Service")
    Expect.that(svc.host).toBe("localhost")
    Expect.that(svc.port).toBe(8080)
    Expect.that(svc.debug).toBe(true)
    Expect.that(svc.timeout).toBe(30)
  }

  it.test("config object with substitutions") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = ConfiguredService
    rule.params = [Value.new({
      "host": "localhost",
      "port": 8080,
      "debug": false,
      "timeout": 30
    })]
    rule.substitutions = {"debug": true, "timeout": 60}
    container.addRule("Service", rule)

    var svc = container.get("Service")
    Expect.that(svc.debug).toBe(true)
    Expect.that(svc.timeout).toBe(60)
    Expect.that(svc.host).toBe("localhost")
    Expect.that(svc.port).toBe(8080)
  }
}

// ============================================================
// Async Resolution Tests
// ============================================================

Testie.test("Async Resolution") { |it|

  it.test("async with Interface params resolves correctly") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Logger")]
    dbRule.asyncResolve = true
    container.addRule("Database", dbRule)

    var db = container.get("Database")
    Expect.that(db.logger is Logger).toBe(true)
  }

  it.test("async with multiple Interface params") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Logger")]
    container.addRule("Database", dbRule)

    var repoRule = Rule.new()
    repoRule.classDef = Repository
    repoRule.params = [Interface.new("Database"), Interface.new("Logger")]
    repoRule.asyncResolve = true
    container.addRule("Repository", repoRule)

    var repo = container.get("Repository")
    Expect.that(repo.db is Database).toBe(true)
    Expect.that(repo.logger is Logger).toBe(true)
  }

  it.test("async with mixed seals") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var rule = Rule.new()
    rule.classDef = AsyncCollector
    rule.params = [
      Interface.new("Logger"),
      Value.new("literal"),
      Factory.new { "factory-result" }
    ]
    rule.asyncResolve = true
    container.addRule("Collector", rule)

    var coll = container.get("Collector")
    Expect.that(coll.a is Logger).toBe(true)
    Expect.that(coll.b).toBe("literal")
    Expect.that(coll.c).toBe("factory-result")
  }

  it.test("async with shared lifecycle caches correctly") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    loggerRule.shared = true
    container.addRule("Logger", loggerRule)

    var svcRule = Rule.new()
    svcRule.classDef = Service
    svcRule.params = [Interface.new("Logger"), Interface.new("Logger")]
    svcRule.asyncResolve = true
    container.addRule("Service", svcRule)

    var svc = container.get("Service")
    Expect.that(svc.repo is Logger).toBe(true)
    Expect.that(svc.logger is Logger).toBe(true)
    Expect.that(svc.repo).toBe(svc.logger)
  }

  it.test("async + deep chain (4 layers)") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Logger")]
    dbRule.asyncResolve = true
    container.addRule("Database", dbRule)

    var repoRule = Rule.new()
    repoRule.classDef = Repository
    repoRule.params = [Interface.new("Database"), Interface.new("Logger")]
    repoRule.asyncResolve = true
    container.addRule("Repository", repoRule)

    var svcRule = Rule.new()
    svcRule.classDef = Service
    svcRule.params = [Interface.new("Repository"), Interface.new("Logger")]
    svcRule.asyncResolve = true
    container.addRule("Service", svcRule)

    var svc = container.get("Service")
    Expect.that(svc.repo is Repository).toBe(true)
    Expect.that(svc.logger is Logger).toBe(true)
    Expect.that(svc.repo.db is Database).toBe(true)
    Expect.that(svc.repo.logger is Logger).toBe(true)
  }

  it.test("non-async still works (regression)") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Logger")]
    container.addRule("Database", dbRule)

    var db = container.get("Database")
    Expect.that(db.logger is Logger).toBe(true)
  }
}
