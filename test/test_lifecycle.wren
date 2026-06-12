// test_lifecycle.wren — Tests for lifecycle management:
// shared (cached), singleton (pre-built), and InstanceCache.

class Logger {
  construct new() {}
  level { "INFO" }
}

class Counter {
  construct new() { _count = 0 }
  count { _count }
  increment() { _count = _count + 1 }
}

import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/lifecycle" for InstanceCache

Testie.test("InstanceCache") { |it|

  it.test("stores and retrieves instances") {
    var cache = InstanceCache.new()
    var obj = Logger.new()
    cache.set("Logger", obj)
    Expect.that(cache.has("Logger")).toBe(true)
    Expect.that(cache.get("Logger")).toBe(obj)
  }

  it.test("returns null for missing keys") {
    var cache = InstanceCache.new()
    Expect.that(cache.has("Missing")).toBe(false)
  }

  it.test("clear removes all entries") {
    var cache = InstanceCache.new()
    cache.set("A", 1)
    cache.set("B", 2)
    cache.clear()
    Expect.that(cache.has("A")).toBe(false)
    Expect.that(cache.has("B")).toBe(false)
    Expect.that(cache.count).toBe(0)
  }

  it.test("count reflects entries") {
    var cache = InstanceCache.new()
    Expect.that(cache.count).toBe(0)
    cache.set("A", 1)
    Expect.that(cache.count).toBe(1)
    cache.set("B", 2)
    Expect.that(cache.count).toBe(2)
  }
}

Testie.test("Shared Lifecycle") { |it|

  it.test("shared returns same instance on repeated get") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Logger
    rule.shared = true
    container.addRule("Logger", rule)

    var a = container.get("Logger")
    var b = container.get("Logger")
    Expect.that(a).toBe(b)
  }

  it.test("shared instances are cached") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Counter
    rule.shared = true
    container.addRule("Counter", rule)

    var a = container.get("Counter")
    a.increment()
    var b = container.get("Counter")
    Expect.that(b.count).toBe(1)
  }

  it.test("non-shared creates new instances") {
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Counter
    container.addRule("Counter", rule)

    var a = container.get("Counter")
    a.increment()
    var b = container.get("Counter")
    Expect.that(b.count).toBe(0)
  }

  it.test("shared respects child override") {
    var container = Container.new()

    var baseRule = Rule.new()
    baseRule.classDef = Counter
    baseRule.shared = true
    container.addRule("Base", baseRule)

    var childRule = Rule.new()
    childRule.inheritInstanceOf = "Base"
    childRule.classDef = Counter
    childRule.shared = false
    container.addRule("Child", childRule)

    var a = container.get("Child")
    a.increment()
    var b = container.get("Child")
    Expect.that(b.count).toBe(0)
  }
}

Testie.test("Singleton Lifecycle") { |it|

  it.test("singleton returns exact pre-built instance") {
    var logger = Logger.new()
    var container = Container.new()
    var rule = Rule.new()
    rule.singleton = logger
    container.addRule("Logger", rule)

    var got = container.get("Logger")
    Expect.that(got).toBe(logger)
  }

  it.test("singleton skips instantiation") {
    var counter = Counter.new()
    counter.increment()
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Counter
    rule.singleton = counter
    container.addRule("Counter", rule)

    var got = container.get("Counter")
    Expect.that(got.count).toBe(1)
  }

  it.test("singleton takes precedence over shared") {
    var instance = Logger.new()
    var container = Container.new()
    var rule = Rule.new()
    rule.classDef = Logger
    rule.shared = true
    rule.singleton = instance
    container.addRule("Logger", rule)

    var got = container.get("Logger")
    Expect.that(got).toBe(instance)
  }
}
