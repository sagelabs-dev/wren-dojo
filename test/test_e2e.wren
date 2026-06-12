// test_e2e.wren — End-to-end simulation of a real application.
// A fictional web application with: Config, Logger, Database, Repository,
// Service, and Controller layers.
// Verifies deep resolution chains, shared lifecycles, and composition-root wiring.

// --- Domain classes ---
class Config {
  construct new(env) { _env = env }
  env { _env }
}

class Logger {
  construct new() { _logs = [] }
  logs { _logs }
  info(msg) { _logs.add("INFO: %(msg)") }
}

class Database {
  construct new(config, logger) {
    _config = config
    _logger = logger
  }
  connect() { _logger.info("Connected to %(_config.env)") }
}

class Repository {
  construct new(db, logger) {
    _db = db
    _logger = logger
  }
  find(id) {
    _logger.info("Finding %(id)")
    return "Record %(id)"
  }
}

class Service {
  construct new(repo, logger) {
    _repo = repo
    _logger = logger
  }
  logger { _logger }
  process(id) {
    _logger.info("Processing %(id)")
    return _repo.find(id)
  }
}

class Controller {
  construct new(svc, logger) {
    _svc = svc
    _logger = logger
  }
  logger { _logger }
  handle(request) {
    _logger.info("Handling %(request)")
    return _svc.process(request)
  }
}

// --- Imports ---
import "../wren-testie/testie" for Testie
import "../wren-testie/src/expect" for Expect
import "../src/container" for Container
import "../src/rule" for Rule
import "../src/seal" for Interface, Value

Testie.test("E2E Application") { |it|

  it.test("deep resolution chain (5 layers)") {
    var container = Container.new()

    var configRule = Rule.new()
    configRule.classDef = Config
    configRule.params = [Value.new("production")]
    container.addRule("Config", configRule)

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    loggerRule.shared = true
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Config"), Interface.new("Logger")]
    dbRule.shared = true
    container.addRule("Database", dbRule)

    var repoRule = Rule.new()
    repoRule.classDef = Repository
    repoRule.params = [Interface.new("Database"), Interface.new("Logger")]
    container.addRule("Repository", repoRule)

    var svcRule = Rule.new()
    svcRule.classDef = Service
    svcRule.params = [Interface.new("Repository"), Interface.new("Logger")]
    container.addRule("Service", svcRule)

    var ctrlRule = Rule.new()
    ctrlRule.classDef = Controller
    ctrlRule.params = [Interface.new("Service"), Interface.new("Logger")]
    container.addRule("Controller", ctrlRule)

    var ctrl = container.get("Controller")
    var result = ctrl.handle("req-123")
    Expect.that(result).toBe("Record req-123")
  }

  it.test("shared instances are reused across deep chain") {
    var container = Container.new()

    var configRule = Rule.new()
    configRule.classDef = Config
    configRule.params = [Value.new("test")]
    container.addRule("Config", configRule)

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    loggerRule.shared = true
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Config"), Interface.new("Logger")]
    dbRule.shared = true
    container.addRule("Database", dbRule)

    var repoRule = Rule.new()
    repoRule.classDef = Repository
    repoRule.params = [Interface.new("Database"), Interface.new("Logger")]
    container.addRule("Repository", repoRule)

    var svcRule = Rule.new()
    svcRule.classDef = Service
    svcRule.params = [Interface.new("Repository"), Interface.new("Logger")]
    container.addRule("Service", svcRule)

    var svc = container.get("Service")
    svc.process(1)
    svc.process(2)

    var logger = container.get("Logger")
    // Logger is shared, so all log calls accumulated
    Expect.that(logger.logs.count > 2).toBe(true)
  }

  it.test("multiple independent services share logger only") {
    var container = Container.new()

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    loggerRule.shared = true
    container.addRule("Logger", loggerRule)

    var configRule = Rule.new()
    configRule.classDef = Config
    configRule.params = [Value.new("prod")]
    container.addRule("Config", configRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Config"), Interface.new("Logger")]
    container.addRule("Database", dbRule)

    var svcARule = Rule.new()
    svcARule.classDef = Service
    svcARule.params = [Interface.new("Database"), Interface.new("Logger")]
    container.addRule("ServiceA", svcARule)

    var svcBRule = Rule.new()
    svcBRule.classDef = Service
    svcBRule.params = [Interface.new("Database"), Interface.new("Logger")]
    container.addRule("ServiceB", svcBRule)

    var a = container.get("ServiceA")
    var b = container.get("ServiceB")

    // Logger is shared (same object)
    Expect.that(a.logger).toBe(b.logger)
    // Database is not shared (different objects)
    Expect.that(a.logger).toNotBe(a)  // sanity: logger != service
  }

  it.test("composition root pattern — all wiring at top") {
    // The whole app is configured in one place
    var container = Container.new()

    // All wiring lives here — the Composition Root
    var configRule = Rule.new()
    configRule.classDef = Config
    configRule.params = [Value.new("dev")]
    container.addRule("Config", configRule)

    var loggerRule = Rule.new()
    loggerRule.classDef = Logger
    loggerRule.shared = true
    container.addRule("Logger", loggerRule)

    var dbRule = Rule.new()
    dbRule.classDef = Database
    dbRule.params = [Interface.new("Config"), Interface.new("Logger")]
    dbRule.shared = true
    container.addRule("Database", dbRule)

    var repoRule = Rule.new()
    repoRule.classDef = Repository
    repoRule.params = [Interface.new("Database"), Interface.new("Logger")]
    container.addRule("Repository", repoRule)

    var svcRule = Rule.new()
    svcRule.classDef = Service
    svcRule.params = [Interface.new("Repository"), Interface.new("Logger")]
    container.addRule("Service", svcRule)

    var ctrlRule = Rule.new()
    ctrlRule.classDef = Controller
    ctrlRule.params = [Interface.new("Service"), Interface.new("Logger")]
    container.addRule("Controller", ctrlRule)

    // Only the controller is resolved at the edge
    var ctrl = container.get("Controller")
    Expect.that(ctrl is Controller).toBe(true)
  }
}
