module parser

import std/text/parse

pub type literal
  Int(i: int)
  Null
  Variable(s: string)

pub type operator
  Add
  Sub
  Mul
  Div

pub type parameter
  VariableParam(s: string)
  Wildcard

pub type expr
  LiteralExpr(l: literal)
  OperatorExpr(op: operator, es: list<expr>)
  LambdaExpr(params: list<parameter>, body: expr)
  ApplicationExpr(f: expr, args: list<expr>)

fun parse_bracketed(parser: parser<e,a>): <parse|e> a
  char('(')
  whitespace0()
  val x = parser()
  whitespace0()
  char(')')
  return x

fun parse_literal(): parse literal
  return choose([
    {Int(pint())},
    {pstring("()"); Null},
    {Variable(parse_parameter_name())}
  ])

fun parse_operator(): parse operator
  return choose([
    {char('+'); Add},
    {char('-'); Sub},
    {char('*'); Mul},
    {char('/'); Div},
  ])

fun parse_parameter_name(): parse string
  return string([alpha()] ++ many(alpha-num))

fun parse_parameter(): parse parameter
  return choose([
    {char('_'); return Wildcard},
    {VariableParam(parse_parameter_name())},
  ])

fun parse_literal_expr(): parse expr
  return LiteralExpr(parse_literal())
fun parse_operator_expr(): <div,parse> expr
  parse_bracketed
    val op = parse_operator()
    val es = many({whitespace0() ; return parse_expr()})
    match op
      Div -> if length(es) != 2 then fail("require exactly two expressions in a div") else ()
      Sub -> if length(es) != 2 then fail("require exactly two expressions in a sub") else ()
      _ -> ()
    OperatorExpr(op, es)
fun parse_lambda_expr(): <div,parse> expr
  parse_bracketed
    char('\\')
    val params = many({whitespace0() ; return parse_parameter()})
    whitespace0()
    pstring("->")
    whitespace0()
    val body = parse_expr()
    LambdaExpr(params, body)
fun parse_application_expr(): <div,parse> expr
  parse_bracketed
    char('@')
    whitespace0()
    val f = parse_expr()
    whitespace0()
    val args = many({whitespace0() ; return parse_expr()})
    whitespace0()
    ApplicationExpr(f, args)
fun parse_expr(): <div,parse> expr
  return choose([parse_literal_expr, parse_operator_expr, parse_lambda_expr, parse_application_expr])

pub fun parse_complete(s: string): div parse-error<expr>
  parse-eof(s.slice(), parse_expr)


pub fun pretty_print(l: literal): string
  match l
    Int(i) -> show(i)
    Null -> "()"
    Variable(s) -> s
pub fun pretty_print(o: operator): string
  match o
    Add -> "+"
    Sub -> "-"
    Mul -> "*"
    Div -> "/"
pub fun pretty_print(p: parameter): string
  match p
    Wildcard -> "_"
    VariableParam(s) -> s
pub fun pretty_print(e: expr): div string
  match e
    LiteralExpr(l) -> pretty_print(l)
    OperatorExpr(op, es) -> "(" ++ pretty_print(op) ++ " " ++ es.map(pretty_print).join(" ") ++ ")"
    LambdaExpr(params, body) -> "(\\" ++ params.map(pretty_print).join(" ") ++ " -> " ++ pretty_print(body) ++ ")"
    ApplicationExpr(f, args) -> "(@" ++ pretty_print(f) ++ " " ++ args.map(pretty_print).join(" ") ++ ")"