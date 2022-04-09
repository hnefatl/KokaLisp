module main
import parser
import std/text/parse


pub fun main()
  //val s = "(+ 56 1 5)"
  val s = "(@ (\\x -> (+ x 3)) 1 2)"
  match parse_complete(s)
    ParseError(err, rest) -> println("error: " ++ err ++ "\nrest:\n" ++ rest.string())
    ParseOk(x) -> println(pretty_print(x))