module main

import std/text/parse

import parser
import interpreter

pub fun main()
  //val s = "(+ 56 1 5)"
  //val s = "(@ (\\x -> (+ x 3)) 1 2)"
  //val s = "(@ (\\print -> (+ x 3)) 1 2)"
  //val s = "(@ (\\x -> (+ x 5)) 7)"
  val s = "(@ (\\f x -> (@ f x 3)) (\\y z -> (* y z)) 2)"
  match parse_complete(s)
    ParseError(err, rest) -> println("parse error: " ++ err ++ "\nrest:\n" ++ rest.string())
    ParseOk(x) -> match interpret_complete(x)
      Left(err) -> println("interpreter error: " ++ err)
      Right(result) -> println(pretty_print(result))