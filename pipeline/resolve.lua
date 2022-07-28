--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local log = require("log")
local parser = require("lua-parser.parser")

local resolve = setmetatable({
  __index = {
    desc = function()
      return "resolve package into modules"
    end,

    run = function(_, spec_path)
      local spec, err = loadfile(spec_path, "bt", {})

      if not spec then
        return "failed to load package spec: " .. err
      end

      local ok, modules = xpcall(spec, debug.traceback)

      if not ok then
        return "failed to load package spec: " .. modules
      end

      local errs, count = {}, 0

      for name, path in pairs(modules) do
        local fd, err = io.open(path, "rb")

        if not fd then
          return "failed to read module: " .. err
        end

        local s = fd:read("a")
        fd:close()

        local node, err = parser.parse(s, path)

        if err then
          errs[#errs + 1] = err
        else
          log.debug("resolved module '%s'", name)

          modules[name] = node
          count = count + 1
        end
      end

      if #errs == 0 then
        if count == 0 then
          log.warn("no modules were resolved")
        end

        return nil, modules
      elseif #errs == 1 then
        return errs[1]
      else
        return "multiple errors:\n" .. table.concat(errs, "\n")
      end
    end,
  },
}, {
  __call = function(mt)
    return setmetatable({}, mt)
  end,
})

return {
  new = resolve,
}
