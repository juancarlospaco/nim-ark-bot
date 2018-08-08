# nim-ark-bot

Ark Survival Evolved Dedicated Server Bot uses Telegram Chat API, Nim Programming Language, RCON.


# Use

1. Extract all files together to any folder (optionally check SHA1 or SHA256 for integrity).
2. Edit `config.ini` to customize.
3. Run `nim_ark_bot`, talk to your Ark Telegram Bot on any Telegram App or WebApp.


# Requisites

- RCON Enabled in the Ark Server Settings.
- The Bot does NOT require Nim installed.
- The Bot does NOT require Telegram installed.

Your Linux Server needs to have some very basic trivial commands installed:

- `df`
- `free`
- `ip`
- `lshw`
- `lsusb`
- `lspci`
- `mcrcon`


## Compile

To compile from sources, get the Code:

```bash
git clone https://github.com/juancarlospaco/nim-ark-bot.git
cd nim-ark-bot/
```

Compile:

```bash
nim e build.nims
```

**Optional**, Compilation and Run for Development only (Hacks, testing, dev, etc)

```bash
nim c -r -d:ssl nim_ark_bot.nim
```


## Config

- Rename the file `config.ini.TEMPLATE` to `config.ini`.
- Edit the file `config.ini` to set `api_key`, `polling_interval`, etc.

You can hack any of the `*.ini` and `*.md` to customize.

## Plugins

On run the bot creates the following folders:

```
./plugins/
./plugins/bash/
./plugins/static/
```

**Bash scripts plugins:**

`./plugins/bash/` are for `*.sh` Bash scripts plugins,
the filename must be all lowercase and not contain whitespaces and end with `*.sh`,
the filename will be the command to trigger the plugin, eg `foo.sh` will be `/foo` on Telegram chat,
output of the script will be sent as string to chat by the bot,
anything you want the bot to say just print it to standard output.

Example Bash plugin:

```bash
# example.sh
echo "This is an example Bash plugin."
```

**Static Files plugins:**

`./plugins/static/` are for `*.*` Static Files "plugins",
the filename must be all lowercase and not contain whitespaces,
the filename will be the command to trigger the plugin, eg `baz.jpg` will be `/baz` on Telegram chat,
the file will be sent as attached Document file to chat by the bot,
anything you want the bot to share just copy it to that folder.

Example Static Files plugin: Any file is Ok.


**Nim-based Plugins:**

Maybe in the future we implement it, but right now it has few builtin functionalities
that if you want to create a new functionality using Nim just send the Pull Request,
to be integrated into the Core directly instead of as a Plugin,
all functionalities can be Enabled / Disabled from the `config.ini` anyways.


## Run

```bash
./nim_ark_bot
```

The binary executable needs the following files on the same current folder:

- `config.ini`

Example:

```
/home/user/bot/nim_ark_bot
/home/user/bot/config.ini
```

**Optional**, you can use any Linux command like `chrt`, `trickle`, `firejails`, `docker`, `rkt` with the Bot too.


## Requisites

*For Compilation only!, if it compiles it does not need Nim nor Telebot.*

- [Nim](https://nim-lang.org/install_unix.html) `>= 0.18.0`
- [Telebot](https://github.com/ba0f3/telebot.nim) [`nimble install telebot`](https://nimble.directory/pkg/telebot)
- [OpenExchangeRates](https://github.com/juancarlospaco/nim-openexchangerates#nim-openexchangerates) [`nimble install openexchangerates`](https://nimble.directory/pkg/openexchangerates)


# FAQ

- How to Start the Bot?.  Run it.
- How to Stop the Bot?.  Kill it.
- How to Get API Key?. [Get the Telegram `api_key` for free.](https://telegram.me/BotFather)
- [Whats RCON?.](http://www.ark-survival.net/en/2015/07/09/rcon-tutorial/)
- [Whats Ark?.](https://survivetheark.com)
- [Whats Telegram?.](https://telegram.org)
- [Whats Nim?.](https://nim-lang.org)
- [Whats Bot?.](https://core.telegram.org/bots)
- This can work as "Cross Ark Chat"?. Yes, you need 1 Bot for each Ark Server.
- Why not a Web Control Panel?. This can work with Servers with Dynamic Public IP address. No Databases.
- Why not Discord?. Discord WebApp is buggy, Discord Desktop App is heavy, Discord eats like 6 Gigabytes of RAM, this weights 135 Kilobytes.


# Features

- 1 File, 0 Dependencies, No Database.
- Customize using INI config and MarkDown MD files.
- 135 Kilobytes size. Tiny CPU & Net use.
- 1 plain text source code file of ~200 lines.
- No install, just copy it and run it.
- No uninstall, just kill it and delete it.
- Does not write anything to Disk.
- Works with Ark Servers with Dynamic Public IP address.
- Works with Ark Servers with Fixed Public IP address.


### Performance Profiling

**Optional**, this is for advanced developers only.

Find and uncomment the line `import nimprof` on `nim_telegram_bot.nim`.

```bash
nim c --profiler:on --stacktrace:on -d:ssl -d:release --app:console --opt:size nim_telegram_bot.nim
./nim_telegram_bot
```

Then open the file `profile_results.txt`.


## Check code

**Optional**, this is for advanced developers only.

How to Lint the code.

```bash
nimble check
nim check src/nim_telegram_bot.nim
```


### CrossCompile

**Optional**, this is for advanced developers only.

Linux -> Windows, this allows to generate a `*.EXE` for Windows on Linux.

On Linux install all this packages:

```
mingw-w64-binutils mingw-w64-crt mingw-w64-gcc mingw-w64-headers mingw-w64-winpthreads mingw-w64-gcc-base mingw-w64-*
```

Usually only installing `mingw-w64-gcc` gets all the rest as dependency.

Names are from ArchLinux AUR, should be similar on other Distros
