module main

import std/os/readline

import ast
import failable
import parser
import transformer
import interpreter

pub fun interpret(source: string): <div,failable> ground-value
  with override ctl fail(err) fail("parser error: " ++ err)
  val parsed = source.parse_complete()
  with override ctl fail(err) fail("transformation error: " ++ err)
  val transformed = parsed.rename_variables_complete()
  with override ctl fail(err) fail("interpreter error: " ++ err)
  return transformed.interpret_complete()

fun main()
  var break := False
  while {!break}
    print("> ")
    val source = try-default("", readline)
    if is-empty(source) then break := True else
      with ctl fail(err) println(err)
      println(pretty_print(interpret(source)))