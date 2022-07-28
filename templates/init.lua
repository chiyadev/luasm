--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local parser = require("lua-parser.parser")

local templates = {
  require = parser.parse(require("templates.require"), "require.lua")[1],
}

--- Creates a new AST from a template AST with the given substitutions.
function templates.sub(node, sub)
  sub = sub or {}

  -- find __LUASM["..."] expressions
  if node.tag == "Index" then
    local expr, index = node[1], node[2]

    if expr.tag == "Id" and expr[1] == "__LUASM" then
      if index.tag ~= "String" then
        return "malformed substitution: __LUASM table must be indexed by a string literal"
      else
        local value = sub[index[1]]
        local ty = type(value)

        if ty == "nil" then
          return nil, { tag = "Nil" }
        elseif ty == "string" then
          return nil, { tag = "String", value }
        elseif ty == "number" then
          return nil, { tag = "Number", value }
        elseif ty == "boolean" then
          return nil, { tag = "Boolean", value }
        else
          return nil, value
        end
      end
    end
  end

  -- create a deep clone of the node
  local new = {
    tag = node.tag,
    pos = node.pos,
  }

  for i = 1, #node do
    local inner = node[i]

    if type(inner) == "table" then
      local err, new_inner = templates.sub(inner, sub)

      if err then
        return err
      else
        new[i] = new_inner
      end
    else
      new[i] = inner
    end
  end

  return nil, new
end

function templates.get(name, sub)
  return templates.sub(templates[name], sub or {})
end

return templates
