module interpreter

import parser

type ground-value
  IntValue(i: int)
  NullValue
  // Can't use the closure type alias since the compiler crashes. Recursive type defn?
  LambdaValue(params: list<parameter>, body: expr, closure: list<(string, ground-value)>)
pub fun pretty_print(v: ground-value): string
  match v
    IntValue(i) -> show(i)
    NullValue -> "()"
    LambdaValue -> "<lambda>"

alias closure-generic<a> = list<(string, a)>
alias closure = closure-generic<ground-value>
fun get_variable(closure: closure-generic<a>, variable: string): failable a
  match find(closure, fn((k,_)){k == variable})
    Nothing -> fail("variable " ++ variable ++ " not in scope")
    Just((_, value)) -> value


effect failable
  ctl fail(msg: string): a


pub fun interpret_complete(e: expr): div either<string, ground-value>
  with ctl fail(err: string) Left(err)
  Right(interpret(e, []))

fun interpret(e: expr, closure: closure): <div,failable> ground-value
  match e
    LiteralExpr(l: literal) -> interpret(l, closure)
    OperatorExpr(op: operator, es: list<expr>) -> {
      val es' = es.map(fn(e'){e'.interpret(closure)})
      match op
        Add -> eval_arith_op((+), 0, es')
        Sub -> eval_binary_arith_op((-), es')
        Mul -> eval_arith_op((*), 1, es')
        Div -> eval_binary_arith_op((/), es')
    }
    LambdaExpr(params: list<parameter>, body: expr) -> LambdaValue(params, body, closure)
    ApplicationExpr(f: expr, args: list<expr>) -> eval_application(f, args, closure)

fun interpret(l: literal, closure: closure): failable ground-value
  match l
    Int(i) -> IntValue(i)
    Null -> NullValue
    Variable(v) -> closure.get_variable(v)

// Evaluate a function application, failing if it's not a valid application.
fun eval_application(f: expr, args: list<expr>, closure: closure): <div,failable> ground-value
  match interpret(f, closure)
    LambdaValue(params: list<parameter>, body: expr, body_closure: closure) -> {
      val args' = args.map(fn(a'){interpret(a', closure)})
      if length(params) != length(args') then fail("param and arg lists are different lengths") else ()
      // zip together the formal and actual args/params dropping wildcarded
      // params, then prepend this to the original function's closure since
      // the args are closer-scoped.
      fun drop_wildcards(param: parameter, value: ground-value) match param
        VariableParam(variable) -> Just((variable, value))
        Wildcard -> Nothing
      val args_closure = zipwith(params, args', drop_wildcards).concat-maybe()
      interpret(body, args_closure ++ body_closure)
    }
    _ -> fail("function in application evaluated to a non-lambda")

// Perform a generic arithmetic operation on arguments.
fun eval_arith_op(op: (int,int) -> int, init: int, args: list<ground-value>): failable ground-value
  fun extract_int_or_fail(x) match x
    IntValue(x') -> x'
    _ -> fail("non-int passed to arithmetic operator")
  IntValue(args.map(extract_int_or_fail).foldl(init, op))
// Special case for operators like `-` and `/` which only work on two arguments.
fun eval_binary_arith_op(op: (int,int) -> int, args: list<ground-value>): failable ground-value
  match args
    Cons(IntValue(lhs'), Cons(IntValue(rhs'), _)) -> IntValue(op(lhs', rhs'))
    _ -> fail("invalid use of binary operator with precendence")