module transformer

import ast
import failable
import variable-mapping

alias has-renames = has-variable-mapping<string>

effect variable-counter
  fun get_next_variable_name(): string

pub fun rename_variables_complete(e: expr): <div,failable> expr
  var counter := 0
  with fun get_next_variable_name() {
    counter := counter + 1
    return "v" ++ show(counter - 1)
  }
  run_with_mapping([])
    rename_variables(e)

fun rename_variables(expr: expr): <has-renames,variable-counter,div,failable> expr
  match expr
    LiteralExpr(l) -> LiteralExpr(rename_variables(l))
    OperatorExpr(op, es) -> OperatorExpr(op, es.map(rename_variables))
    LambdaExpr(params, body) -> rename_lambda_variables(params, body)
    ApplicationExpr(f, args) -> ApplicationExpr(rename_variables(f), args.map(rename_variables))

fun rename_variables(l: literal): <has-renames,failable> literal
  match l
    Variable(s) -> Variable(get_variable(s))
    _ -> l

fun rename_lambda_variables(params: list<parameter>, body: expr): <has-renames,variable-counter,div,failable> expr
  val (new_params, maybe_param_renames) = params.map(fn(p){
    match p
      Wildcard -> (Wildcard, Nothing)
      VariableParam(v) -> {
        val new_name = get_next_variable_name()
        (VariableParam(new_name), Just((v, new_name)))
      }
  }).unzip()
  val param_renames = maybe_param_renames.concat-maybe()
  param_renames.extend_mapping
    LambdaExpr(new_params, rename_variables(body))
