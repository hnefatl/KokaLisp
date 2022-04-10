module test

import failable
import interpreter
import main


// Differentiate between interpreter failures (e.g. parse error) and assertion
// failures (e.g. expression evaluated to 5 not 6).
type test-failure-stage
  InterpreterFailure(stage: main/failure-stage)
  TestFailure
fun show(stage) match stage
  InterpreterFailure(s) -> main/show(s)
  TestFailure -> "test"

// This is the same as failable-tagged, but as a separate effect so we can
// differentiate between a test failing and an interpreter stage failing.
effect testfailable
  ctl testfail(stage: test-failure-stage, err: string): a
// Utility function to inject the expression under test into any error messages.
fun with_source(source: string, action: () -> <testfailable|e> a): <testfailable|e> a
  with override ctl testfail(stage, err) testfail(stage, err ++ "\nInput expression:\n" ++ source)
  action()

// "run" a testfailable, printing errors that occur.
fun run_test(action: () -> <testfailable|e> ()): <console|e> ()
  with ctl testfail(stage, err) println("test failed in stage " ++ show(stage) ++ " with error: " ++ err)
  mask<console>(action)

fun assert_evaluates(action: () -> <failable-stage|e> a): <testfailable|e> a
  with ctl fail-tagged(stage, err) testfail(InterpreterFailure(stage), "expression failed to evaluate: " ++ err)
  mask<testfailable>(action)
fun assert_evaluates_to(action: () -> <failable-stage|e> ground-value, expected: ground-value): <testfailable|e> ()
  val x = assert_evaluates(action)
  if x == expected then () else testfail(TestFailure, "expression evaluated but got " ++ pretty_print(x) ++ " instead of " ++ pretty_print(expected))
fun assert_evaluates_to(source: string, expected: ground-value): <div,testfailable|e> ()
  with_source(source)
    assert_evaluates_to({main/interpret(source)}, expected)

fun assert_fails(action: () -> <failable-stage|e> ground-value): <testfailable|e> failure-stage
  with handler
    return(x) testfail(TestFailure, "expression succeeded instead of failing, result: " ++ pretty_print(x))
    ctl fail-tagged(stage, _) stage
  mask<testfailable>(action)
fun assert_fails(source: string): <div,testfailable|e> failure-stage
  with_source(source)
    assert_fails({main/interpret(source)})
fun assert_fails_at(source: string, expected: main/failure-stage): <div,testfailable|e> ()
  val failed_stage = assert_fails(source)
  with_source(source)
    if failed_stage != expected
    then testfail(TestFailure, "expected failure at stage " ++ show(expected) ++ " got " ++ show(failed_stage))
    else ()


fun main()
  run_test
    "(+ 1 2)".assert_evaluates_to(IntValue(3))
    "(* 2 3 4)".assert_evaluates_to(IntValue(24))
    "(/ 2 3 4)".assert_fails_at(Parser)
    "(1 + 1)".assert_fails_at(Parser)
    "(@ (\\x -> (+ y 1)) 1)".assert_fails_at(Transformer)
    "(@ (\\x -> (+ x 5)) 7)".assert_evaluates_to(IntValue(12))
    "(@ (\\x -> (* x x)) 3)".assert_evaluates_to(IntValue(9))
    "(@ (\\f x -> (@ f x 3)) (\\y z -> (* y z)) 2)".assert_evaluates_to(IntValue(6))
    "()".assert_evaluates_to(UnitValue)
    "(@ (\\_ x -> x) 1 ())".assert_evaluates_to(UnitValue)
    // This loops infinitely (WAI). Would be nice (as long as the language
    // remains simple) to implement best-effort primitive infinite-recursion
    // detection.
    //"(@ (\\f -> (@ f f)) (\\f -> (@ f f)))".assert_fails()