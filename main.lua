#!/usr/bin/env lua5.3
--
-- Copyright (c) 2022 chiya.dev
--
-- Use of this source code is governed by the MIT License
-- which can be found in the LICENSE file and at:
--
--   https://opensource.org/licenses/MIT
--
-- This assembler was quickly hacked together using parts of the WindSeed compiler ;)
--
local argparse = require("argparse")
local log = require("log")
local pipeline = require("pipeline")
local tasks = {
  resolve = require("pipeline.resolve"),
  assemble = require("pipeline.assemble"),
  call_entrypoint = require("pipeline.call_entrypoint"),
  print_ast = require("pipeline.print_ast"),
  output = require("pipeline.output"),
}

local function get_args()
  local parser = argparse():name("luasm"):description("Lua module assembler")

  parser:option("-m --main"):description("Name of the entrypoint module"):default("main")
  parser:option("-s --spec"):description("Path to package spec"):default("package.lua")
  parser:option("-o --out"):description("Path to write output to"):default("-")

  parser:flag("-e --executable"):description("Make output executable (Linux only)")
  parser:flag("-p --pretty"):description("Pretty print output")

  parser:mutex(
    parser:flag("-q --quiet"):description("Do not print any logs."),
    parser:flag("-v --verbose"):description("Print more logs.")
  )

  return parser:parse()
end

local function build_pipeline(args)
  local main = pipeline.new("luasm")

  main:add(tasks.resolve.new())
  main:add(tasks.assemble.new())

  main:add(tasks.call_entrypoint.new {
    module = args.main,
  })

  main:add(tasks.print_ast.new {
    pretty = args.pretty,
  })

  main:add(tasks.output.new {
    path = args.out,
    executable = args.executable,
  })

  return main
end

local function main(args)
  log.enabled.error = not args.quiet
  log.enabled.warn = not args.quiet
  log.enabled.info = not args.quiet
  log.enabled.debug = not args.quiet and args.verbose

  local pipeline = build_pipeline(args)

  log.debug("execution plan: %s", pipeline:desc(true))

  local err = pipeline:run(args.spec)

  if err then
    log.error("%s", err)
    os.exit(1)
  end
end

local ok, result = xpcall(main, debug.traceback, get_args())

if not ok then
  log.error("unhandled compiler error: %s", result)
  log.error("Please report this error to @luaneko.")
end
