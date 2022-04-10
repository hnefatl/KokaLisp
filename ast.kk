module ast

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