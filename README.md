# playdate.nvim

Playdate SDK setup for Neovim

## Requirements

A local copy of the [Playdate SDK](https://play.date/dev/).

Optional: a local copy of [playdate-luacats](https://github.com/notpeter/playdate-luacats)

## Installation and configuration

lazy.nvim:

```lua
{
  "sqwxl/playdate.nvim",
  opts = {
    playdate_sdk_path = "/path/to/playdate-sdk", -- or set PLAYDATE_SDK_PATH
    playdate_luacats_path = "/path/to/playdate-luacats" -- or set PLAYDATE_LUACATS_PATH (optional)
    build = {
      source_dir = "src",
      output_dir = "build"
    }
    server_settings = {
      -- Server settings placed here will be merged into the defaults shown below.
    }
  }
}
```

## How it works

When loaded, the plugin looks for a [`pdxinfo`](https://sdk.play.date/2.6.2/Inside%20Playdate.html#pdxinfo) file in the current working directory to determine if it is a Playdate project. If so, it will overwrite the `lua_ls` configuration with the following (including any custom settings provided in `server_settings`):

```lua
{
  Lua = {
    completion = {
      requireSeparator = "/",
    },
    diagnostics = {
      disable = { "lowercase-global" },
      severity = {
        ["duplicate-set-field"] = "Hint",
      },
    },
    runtime = {
      builtin = {
        io = "disable",
        os = "disable",
        package = "disable",
      },
      nonstandardSymbol = {
        "+=",
        "-=",
        "*=",
        "/=",
        "//=",
        "%=",
        "<<=",
        ">>=",
        "&=",
        "|=",
        "^=",
      },
      special = { import = "require" },
    },
    workspace = {
      library = {
        options.playdate_sdk_path,
        options.playdate_luacats_clone,
      },
    },
  },
}
```

## Commands

- `:PlaydateSetup` - Sets up LuaLS for a Playdate project
- `:PlaydateBuild` - Compile the local project
- `:PlaydateRun` - Compile and run the local project in the Playdate simulator
