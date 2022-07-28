--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local templates = require("templates")

local assemble = setmetatable({
  __index = {
    desc = function()
      return "assemble modules into a require function"
    end,

    run = function(_, modules)
      local names, loaders = {}, { tag = "Table" }

      for name in pairs(modules) do
        names[#names + 1] = name
      end

      -- make module order deterministic
      table.sort(names)

      for _, name in ipairs(names) do
        -- wrap module body in loader function and assign to table field
        table.insert(loaders, {
          tag = "Pair",
          { tag = "String", name },
          { tag = "Function", { { tag = "Dots" } }, modules[name] },
        })
      end

      -- create a require function with the loader table
      local err, require = templates.get("require", { loaders = loaders })

      if err then
        return "require template failed: " .. err
      else
        return nil, require
      end
    end,
  },
}, {
  __call = function(mt)
    return setmetatable({}, mt)
  end,
})

return {
  new = assemble,
}
