--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local output = setmetatable({
  __index = {
    desc = function()
      return "write to output stream"
    end,

    run = function(self, data)
      local path = self.config.path or "-"

      if self.config.executable then
        data = "#!/usr/bin/env lua5.3\n" .. data
      end

      if path == "-" then
        local _, err = io.stdout:write(data)
        return err
      else
        local fd, err = io.open(path, "wb")

        if fd then
          _, err = fd:write(data)
          fd:close()
        end

        return err
      end
    end,
  },
}, {
  __call = function(mt, config)
    return setmetatable({
      config = config,
    }, mt)
  end,
})

return {
  new = output,
}
