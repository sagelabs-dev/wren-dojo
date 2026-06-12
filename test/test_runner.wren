// test_runner.wren — Minimal test harness for wren-dojo.
// No external dependencies. Uses Wren's built-in Fiber.try() for error capture.

class TestRunner {
  static runAll(tests) {
    var passed = 0
    var failed = 0
    for (test in tests) {
      var result = run(test.name, test.fn)
      if (result) {
        passed = passed + 1
      } else {
        failed = failed + 1
      }
    }
    System.print("=== %(passed) passed, %(failed) failed ===")
    return failed == 0
  }
  
  static run(name, fn) {
    var fiber = Fiber.new(fn)
    var error = fiber.try()
    if (error != null) {
      System.print("  FAIL: %(name)")
      System.print("    %(error)")
      return false
    } else {
      System.print("  PASS: %(name)")
      return true
    }
  }
}

class Assert {
  static equal(a, b) {
    if (a != b) {
      Fiber.abort("Expected %(a) to equal %(b)")
    }
  }
  
  static isTrue(a) {
    if (!a) {
      Fiber.abort("Expected true, got %(a)")
    }
  }
  
  static isFalse(a) {
    if (a) {
      Fiber.abort("Expected false, got %(a)")
    }
  }
  
  static notNull(a) {
    if (a == null) {
      Fiber.abort("Expected non-null")
    }
  }
  
  static same(a, b) {
    // Identity check — for shared instances
    if (a != b) {
      Fiber.abort("Expected same instance, got different")
    }
  }
  
  static throws(fn) {
    var fiber = Fiber.new(fn)
    var error = fiber.try()
    if (error == null) {
      Fiber.abort("Expected error but none thrown")
    }
  }
}
