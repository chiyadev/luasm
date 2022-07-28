# luasm

A **Lua 5.1-5.3/JIT** module assembler that combines multiple modules into a single module.

This project was quickly hacked together using large portions of the WindSeed compiler, in _1.5 hours_. It probably has many bugs!

## Dependencies

- [Lua 5.3][1]
- [lpeglabel][2]

luasm itself requires **Lua 5.3** to work. It can accept code written for any of **Lua 5.1-5.3/JIT** as input. Output is compatible with **Lua 5.1-5.3/JIT** depending on the syntax features used in the input.

Ensure lpeglabel is available in a Lua `CPATH` i.e. in the _current directory_ or `/usr/lib/lua/5.3/` for Linux.

## Building

This assembler can [assemble itself][3]. Just clone the repository and assemble the assembler.

```sh
git clone 'git@github.com:chiyadev/luasm.git'
cd luasm

# option 1: assemble as a module
lua5.3 main.lua -o luasm.lua

# option 2: assemble as an executable (Linux only)
lua5.3 main.lua -eo luasm
chmod +x luasm
mv luasm /usr/local/bin
```

You can place `luasm` in any convenient directory of your liking, preferably in a `PATH` like `/usr/local/bin`.

## How to use

Create a `package.lua` file in your project, returning a table of modules to assemble. For example,

```lua
return {
  "main" = "src/main.lua",
  "utils" = "src/utils.lua"
}
```

Then run the assembler in your project directory.

```sh
luasm -o out.lua
```

That's it.

## Options

See all available command line options using the `--help` flag.

## License

luasm is licensed under the [MIT License](LICENSE).

[1]: https://www.lua.org/versions.html#5.3
[2]: https://github.com/sqmedeiros/lpeglabel
[3]: https://en.wikipedia.org/wiki/Bootstrapping_(compilers)
