--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local call_entrypoint = setmetatable({
  __index = {
    desc = function()
      return "call into the entrypoint module using require"
    end,

    run = function(self, require)
      return nil, {
        tag = "Call",
        require,
        { tag = "String", self.config.module },
      }
    end,
  },
}, {
  __call = function(mt, config)
    return setmetatable({
      config = config or {},
    }, mt)
  end,
})

return {
  new = call_entrypoint,
}
