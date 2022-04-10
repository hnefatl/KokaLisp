module test

import failable
import interpreter
import main

// This is the same as failable, but as a separate effect so we can
// differentiate between a test failing and an interpreter stage failing.
effect testfailable
  ctl testfail(err: string): a

fun run_test(action: () -> <testfailable|e> ()): <console|e> ()
  with ctl testfail(err) println("test failed with error: " ++ err)
  mask<console>(action)

fun assert_evaluates(action: () -> <failable|e> a): <testfailable|e> a
  with ctl fail(err) testfail("expression failed to evaluate: " ++ err)
  mask<testfailable>(action)
fun assert_evaluates_to(action: () -> <failable|e> ground-value, expected: ground-value): <testfailable|e> ()
  val x = assert_evaluates(action)
  if x == expected then () else testfail("expression evaluated but got " ++ pretty_print(x) ++ " instead of " ++ pretty_print(expected))
fun assert_evaluates_to(source: string, expected: ground-value): <div,testfailable|e> ()
  with override fun testfail(err) testfail(err ++ "\nInput expression:\n" ++ source)
  assert_evaluates_to({main/interpret(source)}, expected)

fun assert_fails(action: () -> <failable|e> ground-value): <testfailable|e> ()
  with handler
    return(x) testfail("expression succeeded instead of failing, result: " ++ pretty_print(x))
    ctl fail(err) ()
  mask<testfailable>(action)
fun assert_fails(source: string): <div,testfailable|e> ()
  with override fun testfail(err) testfail(err ++ "\nInput expression:\n" ++ source)
  assert_fails({main/interpret(source)})


fun main()
  run_test
    "(+ 1 2)".assert_evaluates_to(IntValue(3))
    "(* 2 3 4)".assert_evaluates_to(IntValue(24))
    "(/ 2 3 4)".assert_fails()
    "(@ (\\x -> (+ x 5)) 7)".assert_evaluates_to(IntValue(12))
    "(@ (\\x -> (* x x)) 3)".assert_evaluates_to(IntValue(9))
    "(@ (\\f x -> (@ f x 3)) (\\y z -> (* y z)) 2)".assert_evaluates_to(IntValue(6))