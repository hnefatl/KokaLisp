module main

import ast
import failable
import parser
import transformer
import interpreter

pub fun main()
  //val s = "(+ 56 1 5)"
  //val s = "(@ (\\x -> (+ x 3)) 1 2)"
  //val s = "(@ (\\print -> (+ x 3)) 1 2)"
  //val s = "(@ (\\x -> (+ x 5)) 7)"
  val s = "(@ (\\f x -> (@ f x 3)) (\\y z -> (* y z)) 2)"

  with ctl fail(err) println("parser error: " ++ err)
  val parsed = s.parse_complete()
  with override ctl fail(err) println("transformation error: " ++ err)
  val transformed = parsed.rename_variables_complete()
  println(pretty_print(transformed))
  with override ctl fail(err) println("interpreter error: " ++ err)
  val interpreted = transformed.interpret_complete()
  println(pretty_print(interpreted))