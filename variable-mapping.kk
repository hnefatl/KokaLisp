module variable-mapping

import failable

pub alias variable-mapping-generic<a> = list<(string, a)>
pub fun get_variable(closure: variable-mapping-generic<a>, variable: string): failable a
  match find(closure, fn((k,_)){k == variable})
    Nothing -> fail("variable " ++ variable ++ " not in scope")
    Just((_, value)) -> value
