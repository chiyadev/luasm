--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local log = require("log")

local function pack_results(err, ...)
  return err, { ... }
end

local pipeline = setmetatable({
  __index = {
    desc = function(self, detailed)
      if detailed then
        local lines = { self:desc() .. ":" }

        for i, task in ipairs(self.tasks) do
          local j = 1

          for line in task:desc(true):gmatch("[^\n]+") do
            if j == 1 then
              line = string.format("  %d. %s", i, line)
            else
              line = string.format("   %s", line)
            end

            lines[#lines + 1] = line
            j = j + 1
          end
        end

        return table.concat(lines, "\n")
      else
        return self.name
      end
    end,

    add = function(self, task)
      table.insert(self.tasks, task)
      return self
    end,

    run = function(self, ...)
      local state = { ... }

      for _, task in ipairs(self.tasks) do
        log.debug("executing pipeline '%s' task '%s'", self:desc(), task:desc())

        local err, result = pack_results(task:run(table.unpack(state)))

        if err then
          local err = string.format("pipeline '%s' task '%s' failed: %s", self:desc(), task:desc(), err)

          return err, table.unpack(result)
        else
          state = result
        end
      end

      return nil, table.unpack(state)
    end,
  },
}, {
  __call = function(mt, name)
    return setmetatable({
      name = name or "pipeline",
      tasks = {},
    }, mt)
  end,
})

return {
  new = pipeline,
}
