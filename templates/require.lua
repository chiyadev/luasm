--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
return [[
(function(get_loaders)
  local loaders, preload_env, loaded_env, require_env = nil, package.preload, package.loaded, require

  local function require(modname)
    local loaded = loaded_env[modname]

    if loaded ~= nil and loaded ~= false then
      return loaded
    end

    local preload = preload_env[modname]

    if preload == nil then
      local loader = loaders[modname]

      if loader ~= nil then
        local result = loader(modname)

        if result ~= nil then
          loaded_env[modname] = result
        elseif loaded_env[modname] == nil then
          loaded_env[modname] = true
        end

        return loaded_env[modname]
      end
    end

    return require_env(modname)
  end

  loaders = get_loaders(require)

  return require
end)(function(require)
  -- make all references to `require` in nested modules upvalues
  return __LUASM.loaders
end)
]]
