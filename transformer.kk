module transformer

import ast
import failable
import variable-mapping

alias renames = variable-mapping-generic<string>

effect variable-counter
  fun get_next_variable_name(): string

pub fun rename_variables_complete(e: expr): <div,failable> expr
  var counter := 0
  with fun get_next_variable_name() {
    counter := counter + 1
    return "v" ++ show(counter - 1)
  }
  rename_variables(e, [])

fun rename_variables(expr: expr, renames: renames): <div,failable,variable-counter> expr
  match expr
    LiteralExpr(l) -> LiteralExpr(rename_variables(l, renames))
    OperatorExpr(op, es) -> OperatorExpr(op, es.map(fn(e){rename_variables(e, renames)}))
    LambdaExpr(params, body) -> rename_lambda_variables(params, body, renames)
    ApplicationExpr(f, args) -> ApplicationExpr(rename_variables(f, renames), args.map(fn(a){rename_variables(a, renames)}))

fun rename_variables(l: literal, renames: renames): failable literal
  match l
    Variable(s) -> Variable(renames.get_variable(s))
    _ -> l

fun rename_lambda_variables(params: list<parameter>, body: expr, renames: renames): <div,failable,variable-counter> expr
  val (new_params, maybe_param_renames) = params.map(fn(p){
    match p
      Wildcard -> (Wildcard, Nothing)
      VariableParam(v) -> {
        val new_name = get_next_variable_name()
        (VariableParam(new_name), Just((v, new_name)))
      }
  }).unzip()
  val param_renames = maybe_param_renames.concat-maybe()
  LambdaExpr(new_params, rename_variables(body, param_renames ++ renames))
