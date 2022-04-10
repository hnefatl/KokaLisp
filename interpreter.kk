module interpreter

import ast 
import failable
import variable-mapping

pub type ground-value
  IntValue(i: int)
  NullValue
  // Can't use the closure type alias since the compiler crashes. Recursive type defn?
  LambdaValue(params: list<parameter>, body: expr, closure: variable-mapping-generic<ground-value>)
pub fun pretty_print(v: ground-value): string
  match v
    IntValue(i) -> show(i)
    NullValue -> "()"
    LambdaValue -> "<lambda>"
pub fun (==)(x: ground-value, y: ground-value): bool
  match (x, y)
    (IntValue(x'), IntValue(y')) -> x' == y'
    (NullValue, NullValue) -> True
    // Say lambdas are always inequal. Not strictly true, but simplify for now
    // since I don't want to write out equalities for all the syntax.
    _ -> False
pub fun (!=)(x: ground-value, y: ground-value): bool
  return !(x == y)

alias closure = variable-mapping-generic<ground-value>
alias has-closure = has-variable-mapping<ground-value>

pub fun interpret_complete(e: expr): <div,failable> ground-value
  run_with_mapping([])
    interpret(e)

fun interpret(e: expr): <has-closure,div,failable> ground-value
  match e
    LiteralExpr(l: literal) -> interpret(l)
    OperatorExpr(op: operator, es: list<expr>) -> {
      val es' = es.map(interpret)
      match op
        Add -> eval_arith_op((+), 0, es')
        Sub -> eval_binary_arith_op((-), es')
        Mul -> eval_arith_op((*), 1, es')
        Div -> eval_binary_arith_op((/), es')
    }
    LambdaExpr(params: list<parameter>, body: expr) -> LambdaValue(params, body, get_mapping())
    ApplicationExpr(f: expr, args: list<expr>) -> eval_application(f, args)

fun interpret(l: literal): <has-closure,failable> ground-value
  match l
    Int(i) -> IntValue(i)
    Null -> NullValue
    Variable(v) -> get_variable(v)

// Evaluate a function application, failing if it's not a valid application.
fun eval_application(f: expr, args: list<expr>): <has-closure,div,failable> ground-value
  match interpret(f)
    LambdaValue(params: list<parameter>, body: expr, body_closure: closure) -> {
      val args' = args.map(interpret)
      if length(params) != length(args') then fail("param and arg lists are different lengths") else ()
      // zip together the formal and actual args/params dropping wildcarded
      // params, then prepend this to the original function's closure since
      // the args are closer-scoped.
      fun drop_wildcards(param: parameter, value: ground-value) match param
        VariableParam(variable) -> Just((variable, value))
        Wildcard -> Nothing
      val args_closure = zipwith(params, args', drop_wildcards).concat-maybe()
      // args take priority over any variables that were in the old scope of the
      // body. We replace the mapping so no other variables leak into the body's
      // scope.
      (args_closure ++ body_closure).replace_mapping
        interpret(body)
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