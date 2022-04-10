module typechecker

import ast
import failable
import variable-mapping

// Fully resolved type of an expression. There's no type inference or
// higher-level types, only the type system corresponding to predicate logic
// (can't remember the names now). That is, `(\x -> x)`` has a single type
// determined by its call site (`(@ (\x -> x) 5)` results in it being int->int),
// and it's not `forall a. a -> a`.
// Downsides: restrictive, fragile if new types get added to the languages.
// Upsides: comparatively simple.
pub type ast-type
  IntType
  UnitType
  LambdaType(params: list<ast-type>, ret: ast-type)
type ast-type-wip
  TypeVar(name: string)
  AstType(t: ast-type)

// This is a mess:
// - list_equals_ast_type can't be inferred as non-divergent, so needs to be
//   wrapped using `unsafe-no-div`.
// - seems like Koka gets a bit confused with multiple definitions of `(==)` for
//   different user-defined types: iirc it was complaining about ambiguity, like
//   it could tell the different user types apart? Might've just been a symptom
//   of the recursive issue above though.
fun ast_type_equals(x: ast-type, y: ast-type): bool match (x, y)
  (IntType, IntType) -> True
  (UnitType, UnitType) -> True
  (LambdaType(params1, ret1), LambdaType(params2, ret2)) -> unsafe-no-div
    list_equals_ast_type(params1, params2) && ast_type_equals(ret1, ret2)
  _ -> False
fun ast_type_wip_equals(x: ast-type-wip, y: ast-type-wip): bool match (x, y)
  (TypeVar(x'), TypeVar(y')) -> x' == y'
  (AstType(x'), AstType(y')) -> ast_type_equals(x', y')
  _ -> False
fun list_equals_ast_type(xs: list<ast-type>, ys: list<ast-type>): div bool match (xs, ys)
  (Nil, Nil) -> True
  (Cons(x, xs'), Cons(y, ys')) -> ast_type_equals(x, y) && list_equals_ast_type(xs', ys')
  _ -> False

alias type-constraints = list<(string, list<ast-type-wip>)>
effect type-accumulator
  fun add_constraint(name: string, t: ast-type-wip): ()

// Update the first element in xs matching the key using f, if it exists.
fun update_map(xs: list<(string, b)>, key: string, f: (b) -> e b): e list<a>
  match xs
    Nil -> Nil
    Cons((k, v), xs') -> if k == key then Cons((k, f(v)), xs') else Cons(x, update_map(xs', key, f))
fun insert_set(xs: list<ast-type-wip>, v: ast-type-wip): list<ast-type-wip>
  match xs.find(fn(x){ast_type_wip_equals(v, x)})
    Nothing -> Cons(v, xs)
    _ -> xs

//fun run_type_accumulator(initial_types: action: () -> <type-accumulator|e> a): e a
//  var constraints := initial_types
//  with fun add_constraint(name, t) constraints.update_map(name) fn(cs) {
//    
//  }


// TODO: strategy was going to be:
// - walk the syntax tree, generating for each variable a set of constraints
//   (`ast-type-wip`).
// - when inserting into a set, can unify together to either fail or remove type
//   variables. Probably more complicated than just that.
// - had thoughts of threading through information about "original variable x
//   at position 17 is now called v9" so we can give decent error messages.
pub fun type_check_complete(e: expr): <div,failable> variable-mapping-generic<ast-type>
  fail("not implemented")

fun type_check(e: expr): <div,type-accumulator,failable> ast-type-wip
  match e
    LiteralExpr(l) -> type_check(l)
    //OperatorExpr(_, es) -> 
fun type_check(l: literal): <type-accumulator,failable> ast-type-wip
  match l
    Int(_) -> IntType
    Unit -> UnitType
    Variable(v) -> get_variable(v)

