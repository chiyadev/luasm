--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
local tostring, concat, unpack, byte, char, format =
  tostring, table.concat, table.unpack, string.byte, string.char, string.format

local escape_map = {
  [7] = "\\a",
  [8] = "\\b",
  [9] = "\\t",
  [11] = "\\v",
  [12] = "\\f",
  [13] = "\\r",
  [10] = "\\n",
  [34] = '\\"',
  [39] = "\\'",
  [92] = "\\\\",
}

local reserved_keywords = {
  ["and"] = true,
  ["break"] = true,
  ["do"] = true,
  ["else"] = true,
  ["elseif"] = true,
  ["end"] = true,
  ["false"] = true,
  ["for"] = true,
  ["function"] = true,
  ["goto"] = true,
  ["if"] = true,
  ["in"] = true,
  ["local"] = true,
  ["nil"] = true,
  ["not"] = true,
  ["or"] = true,
  ["repeat"] = true,
  ["return"] = true,
  ["then"] = true,
  ["true"] = true,
  ["until"] = true,
  ["while"] = true,
}

local function is_valid_identifier(s)
  if #s == 0 or reserved_keywords[s] then
    return false
  end

  for i = 1, #s do
    local c = byte(s, i)

    -- https://www.lua.org/manual/5.3/manual.html#3.1
    -- Names (also called identifiers) in Lua can be any string of letters, digits, and underscores, not beginning with a digit and not being a reserved word.
    if not ((i ~= 1 and 48 <= c and c <= 57) or (65 <= c and c <= 90) or (97 <= c and c <= 122) or c == 95) then
      return false
    end
  end

  return true
end

local function escape_str(s)
  local res, i = { '"' }, 1

  for j = 1, #s do
    local c = byte(s, j)
    local esc = escape_map[c]

    if esc then
      i = i + 1
      res[i] = esc
    elseif c < 32 or c > 126 then
      res[i + 1] = "\\"
      res[i + 2] = format("%03d", c)
      i = i + 2
    else
      i = i + 1
      res[i] = char(c)
    end
  end

  res[i + 1] = '"'
  return concat(res)
end

local op_map = {
  add = "+",
  sub = "-",
  mul = "*",
  div = "/",
  idiv = "//",
  mod = "%",
  pow = "^",
  concat = "..",
  band = "&",
  bor = "|",
  bxor = "~",
  bnot = "~",
  shl = "<<",
  shr = ">>",
  eq = "==",
  ne = "~=",
  lt = "<",
  gt = ">",
  le = "<=",
  ge = ">=",
  unm = "-",
  len = "#",
  ["and"] = "and",
  ["or"] = "or",
  ["not"] = "not",
}

local op_require_spaces = {
  ["and"] = true,
  ["or"] = true,
  ["not"] = true,
  [".."] = true,
}

local print_ast = setmetatable({
  __index = {
    desc = function()
      return "convert syntax tree into code"
    end,

    run = function(self, node)
      local indent = string.rep(" ", self.config.pretty and 2 or 0)
      local pretty = #indent ~= 0

      local print = setmetatable({}, {
        __call = function(self, node)
          return self[node.tag](node)
        end,
      })

      local result, index, level = {}, 1, 1

      local function print_str(s)
        result[index] = s
        index = index + 1
      end

      local function print_indent()
        if pretty then
          for _ = 2, level do
            print_str(indent)
          end
        end
      end

      local function while_indented(fn, ...)
        level = level + 1
        fn(...)
        level = level - 1
      end

      local function print_separated(sep, list)
        for i = 1, #list do
          if i ~= 1 then
            print_str(sep)
          end

          print(list[i])
        end
      end

      function print.Block(node)
        for i = 1, #node do
          -- line indent
          print_indent()

          -- statement
          print(node[i])

          -- statement separator
          print_str(pretty and ";\n" or ";")
        end
      end

      function print.Do(node)
        -- open
        print_str(pretty and "do\n" or "do ")

        -- body
        while_indented(print.Block, node)

        -- close
        print_indent()
        print_str("end")
      end

      function print.Set(node)
        -- lhs
        print_separated(pretty and ", " or ",", node[1])

        -- assignment
        print_str(pretty and " = " or "=")

        -- rhs
        print_separated(pretty and ", " or ",", node[2])
      end

      function print.While(node)
        -- header
        print_str("while ")

        -- condition
        print(node[1])

        -- open
        print_str(pretty and " do\n" or " do ")

        -- body
        while_indented(print, node[2])

        -- close
        print_indent()
        print_str("end")
      end

      function print.Repeat(node)
        -- header
        print_str(pretty and "repeat\n" or "repeat ")

        -- body
        while_indented(print, node[1])

        -- close
        print_indent()
        print_str("until ")

        -- condition
        print(node[2])
      end

      function print.If(node)
        local i = 1
        while i <= #node do
          if i ~= 1 then
            print_indent()
          end

          if i ~= #node then
            -- if or elseif
            print_str(i == 1 and "if " or "elseif ")

            -- condition
            print(node[i])

            -- open
            print_str(pretty and " then\n" or " then ")

            -- body
            while_indented(print, node[i + 1])

            i = i + 2
          else
            -- else
            print_str(pretty and "else\n" or "else ")

            -- body
            while_indented(print, node[i])

            i = i + 1
          end
        end

        -- close
        print_indent()
        print_str("end")
      end

      function print.Fornum(node)
        local ident, init, limit = node[1], node[2], node[3]
        local step, body

        if #node == 4 then
          body = node[4]
        else
          step, body = node[4], node[5]
        end

        -- header
        print_str("for ")

        -- identifier
        print(ident)

        -- assignment
        print_str(pretty and " = " or "=")

        -- initial value
        print(init)

        -- separator
        print_str(pretty and ", " or ",")

        -- limit value
        print(limit)

        if step then
          -- separator
          print_str(pretty and ", " or ",")

          -- step value
          print(step)
        end

        -- open
        print_str(pretty and " do\n" or " do ")

        -- body
        while_indented(print, body)

        -- close
        print_indent()
        print_str("end")
      end

      function print.Forin(node)
        -- header
        print_str("for ")

        -- identifiers
        print_separated(pretty and ", " or ",", node[1])

        -- separator
        print_str(" in ")

        -- expressions
        print_separated(pretty and ", " or ",", node[2])

        -- open
        print_str(pretty and " do\n" or " do ")

        -- body
        while_indented(print, node[3])

        -- close
        print_indent()
        print_str("end")
      end

      function print.Local(node)
        -- header
        print_str("local ")

        -- identifiers
        print_separated(pretty and ", " or ",", node[1])

        if #node[2] ~= 0 then
          -- assignment
          print_str(pretty and " = " or "=")

          -- expressions
          print_separated(pretty and ", " or ",", node[2])
        end
      end

      function print.Localrec(node)
        -- syntactic sugar for `local id; id = function() ... end`
        print.Local { node[1], {} }

        print_str(pretty and ";\n" or ";")
        print_indent()

        print.Set { node[1], node[2] }
      end

      function print.Goto(node)
        print_str("goto ")
        print_str(node[1])
      end

      function print.Label(node)
        print_str("::")
        print_str(node[1])
        print_str("::")
      end

      function print.Return(node)
        print_str("return ")
        print_separated(pretty and ", " or ",", node)
      end

      function print.Break()
        print_str("break")
      end

      function print.Nil()
        print_str("nil")
      end

      function print.Dots()
        print_str("...")
      end

      function print.Boolean(node)
        print_str(tostring(node[1]))
      end

      function print.Number(node)
        print_str(tostring(node[1]))
      end

      function print.String(node)
        print_str(escape_str(node[1]))
      end

      function print.Function(node)
        -- header
        print_str("function(")

        -- parameters
        print_separated(pretty and ", " or ",", node[1])

        -- open
        print_str(pretty and ")\n" or ")")

        -- body
        while_indented(print, node[2])

        -- close
        print_indent()
        print_str("end")
      end

      function print.Table(node)
        if #node == 0 then
          -- empty table
          print_str("{}")
        elseif #node == 1 then
          -- one element table
          print_str(pretty and "{ " or "{")
          print(node[1])
          print_str(pretty and " }" or "}")
        else
          -- many element table
          print_str(pretty and "{\n" or "{")

          while_indented(function()
            for i = 1, #node do
              print_indent()

              -- entry
              print(node[i])

              -- entry separator
              print_str(pretty and ",\n" or ",")
            end
          end)

          -- close
          print_indent()
          print_str("}")
        end
      end

      function print.Pair(node)
        local left, right = node[1], node[2]

        if left.tag == "String" and is_valid_identifier(left[1]) then
          -- identifier assignment-like table entry
          print_str(left[1])

          -- assignment
          print_str(pretty and " = " or "=")

          -- value
          print(right)
        else
          -- string index assignment-like table entry
          print_str("[")
          print(left)

          -- assignment
          print_str(pretty and "] = " or "]=")

          -- value
          print(right)
        end
      end

      function print.Op(node)
        local op, left, right = op_map[node[1]], node[2], node[3]

        if right then
          -- double operand operator
          print(left)
          print_str((pretty or op_require_spaces[op]) and (" " .. op .. " ") or op)
          print(right)
        else
          -- single operand operator
          print_str(op_require_spaces[op] and (op .. " ") or op)
          print(left)
        end
      end

      function print.Paren(node)
        print_str("(")
        print(node[1])
        print_str(")")
      end

      function print.Call(node)
        -- callee expression
        print(node[1])

        -- argument list
        print_str("(")
        print_separated(pretty and ", " or ",", { unpack(node, 2) })
        print_str(")")
      end

      function print.Invoke(node)
        -- callee expression
        print(node[1])

        -- member name
        print_str(":")
        print_str(node[2][1])

        -- argument list
        print_str("(")
        print_separated(pretty and ", " or ",", { unpack(node, 3) })
        print_str(")")
      end

      function print.Id(node)
        print_str(node[1])
      end

      function print.Index(node)
        local expr, index = node[1], node[2]

        -- table expression
        print(expr)

        if index.tag == "String" and is_valid_identifier(index[1]) then
          -- identifier assignment
          print_str(".")
          print_str(index[1])
        else
          -- string index assignment
          print_str("[")
          print(index)
          print_str("]")
        end
      end

      print(node)

      return nil, concat(result)
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
  new = print_ast,
}
