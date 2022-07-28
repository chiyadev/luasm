--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local log = { enabled = {} }
local colors = require("term.colors")

function log.print(...)
  io.stderr:write(..., "\n")
end

function log.error(...)
  if log.enabled.error then
    log.print(colors.red .. "error: " .. colors.reset .. string.format(...))
  end
end

function log.warn(...)
  if log.enabled.warn then
    log.print(colors.yellow .. "warning: " .. colors.reset .. string.format(...))
  end
end

function log.info(...)
  if log.enabled.info then
    log.print(string.format(...))
  end
end

function log.debug(...)
  if log.enabled.debug then
    log.print(colors.dim .. string.format(...) .. colors.reset)
  end
end

return log
