module variable-mapping

import failable

pub alias variable-mapping-generic<v> = list<(string, v)>
pub effect has-variable-mapping<v>
  fun get_mapping(): variable-mapping-generic<v>

pub fun get_variable(variable: string): <has-variable-mapping<v>,failable> v
  match find(get_mapping(), fn((k,_)){k == variable})
    Nothing -> fail("variable " ++ variable ++ " not in scope")
    Just((_, value)) -> value

pub fun extend_mapping(new_mapping: variable-mapping-generic<v>, action: () -> <has-variable-mapping<v>|e> a): <has-variable-mapping<v>|e> a
  val current_mapping = get_mapping()
  with override fun get_mapping() new_mapping ++ current_mapping
  action()
pub fun replace_mapping(new_mapping: variable-mapping-generic<v>, action: () -> <has-variable-mapping<v>|e> a): <has-variable-mapping<v>|e> a
  with override fun get_mapping() new_mapping
  action()

pub fun run_with_mapping(initial: variable-mapping-generic<v>, action: () -> <has-variable-mapping<v>|e> a): e a
  with fun get_mapping() initial
  action()