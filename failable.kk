module failable

pub effect failable
  ctl fail(msg: string): a

pub effect failable-tagged<v>
  ctl fail-tagged(tag: v, msg: string): a
pub fun tag_failure(tag: v, action: () -> <failable|e> a): <failable-tagged<v>|e> a
  with ctl fail(msg) fail-tagged(tag, msg)
  mask<failable-tagged>(action)