module main

import std/os/readline

import ast
import failable
import parser
import transformer
import interpreter

pub type failure-stage
  Parser
  Transformer
  Interpreter
pub alias failable-stage = failable-tagged<failure-stage>
pub fun show(f) match f
  Parser -> "parser"
  Transformer -> "transformer"
  Interpreter -> "interpreter"
pub fun (==)(x: failure-stage, y: failure-stage) match (x, y)
  (Parser, Parser) -> True
  (Transformer, Transformer) -> True
  (Interpreter, Interpreter) -> True
  _ -> False
pub fun (!=)(x: failure-stage, y: failure-stage) !(x == y)


pub fun interpret(source: string): <div,failable-stage> ground-value
  val parsed = tag_failure(Parser)
    source.parse_complete()
  val transformed = tag_failure(Transformer)
    parsed.rename_variables_complete()
  return tag_failure(Interpreter)
    transformed.interpret_complete()

fun main()
  var break := False
  while {!break}
    print("> ")
    val source = try-default("", readline)
    if is-empty(source) then break := True else
      with ctl fail-tagged(tag: failure-stage, err) println(show(tag) ++ " error: " ++ err)
      println(pretty_print(interpret(source)))