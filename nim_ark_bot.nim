import
  asyncdispatch, httpclient, logging, json, options, ospaths, osproc, parsecfg,
  strformat, strutils, terminal, times, random
import telebot  # nimble install telebot https://nimble.directory/pkg/telebot


const
  about_texts = fmt"""*Nim Telegram Bot* 🤖
  ☑️ *Compiled:*    `{CompileDate} {CompileTime}` ⏰
  ☑️ *Nim Version:* `{NimVersion}` 👑
  ☑️ *OS & CPU:*    `{hostOS.toUpperAscii} {hostCPU.toUpperAscii}` 💻
  ☑️ *Bot uses:*    """
  pub_ip_api  = "http://api.ipify.org"
  ark_api_ver = "http://arkdedicated.com/version"
  ark_api_sta = "http://arkdedicated.com/officialserverstatus.ini"
  helps_texts = staticRead("help_text.md")

let
  start_time  = cpuTime()
  config_ini  = loadConfig("config.ini")
  api_key     = config_ini.getSectionValue("", "api_key")
  cli_colors  = parseBool(config_ini.getSectionValue("", "terminal_colors"))

  cmd_help     = parseBool(config_ini.getSectionValue("commands", "help"))
  cmd_ping     = parseBool(config_ini.getSectionValue("commands", "ping"))
  cmd_about    = parseBool(config_ini.getSectionValue("commands", "about"))
  cmd_uptime   = parseBool(config_ini.getSectionValue("commands", "uptime"))
  cmd_donate   = parseBool(config_ini.getSectionValue("commands", "donate"))
  cmd_datetime = parseBool(config_ini.getSectionValue("commands", "datetime"))

  server_cmd_ip    = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "ip"))
  server_cmd_df    = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "df"))
  server_cmd_free  = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "free"))
  server_cmd_lshw  = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "lshw"))
  server_cmd_lsusb = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "lsusb"))
  server_cmd_lspci = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "lspci"))
  server_cmd_public_ip = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "public_ip"))

  ark_cmd_saveworld   = parseBool(config_ini.getSectionValue("ark_commands", "saveworld"))
  ark_cmd_listplayers = parseBool(config_ini.getSectionValue("ark_commands", "listplayers"))
  ark_cmd_getchat     = parseBool(config_ini.getSectionValue("ark_commands", "getchat"))
  ark_cmd_day         = parseBool(config_ini.getSectionValue("ark_commands", "day"))
  ark_cmd_night       = parseBool(config_ini.getSectionValue("ark_commands", "night"))
  ark_cmd_lastversion = parseBool(config_ini.getSectionValue("ark_commands", "lastversion"))
  ark_cmd_status      = parseBool(config_ini.getSectionValue("ark_commands", "status"))
  ark_cmd_mods        = parseBool(config_ini.getSectionValue("ark_commands", "mods"))

  rcon_ip   = config_ini.getSectionValue("rcon_server", "ip")
  rcon_port = config_ini.getSectionValue("rcon_server", "port")
  rcon_pass = config_ini.getSectionValue("rcon_server", "password")
  rcon_cmd = fmt"mcrcon -c -H {rcon_ip} -P {rcon_port} -p {rcon_pass} "

  polling_interval: int8 = parseInt(config_ini.getSectionValue("", "polling_interval")).int8

var counter: int


template handlerizer(body: untyped): untyped =
  proc cb(e: Command) {.async.} =
    inc counter
    body
    var msg = newMessage(e.message.chat.id, $message.strip())
    msg.disableNotification = true
    msg.parseMode = "markdown"
    try:
      discard bot.send(msg)  # Sometimes Telegram API just ignores requests (?).
    except Exception:
      discard
  result = cb

proc public_ipHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let
      responz = await newAsyncHttpClient().get(pub_ip_api)  # await response
      publ_ip = await responz.body                          # await body
      message = fmt"*Server Public IP Address:* `{publ_ip}`"

proc uptimeHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = fmt"*Uptime:* `{cpuTime() - start_time}` ⏰"

proc pingHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = "*pong*"

proc datetimeHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = $now()

proc aboutHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = about_texts & $counter

proc helpHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = helps_texts

proc donateHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = readFile("donate_text.md")

proc modsHandler(bot: Telebot): CommandCallback =
  handlerizer():
    let message = readFile("mods_list.md")


when defined(linux):
  proc dfHandler(bot: Telebot): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx("df --human-readable --local --total --print-type")[0]}`"""

  proc freeHandler(bot: Telebot): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx("free --human --total --giga")[0]}`"""

  proc ipHandler(bot: Telebot): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx("ip -brief address")[0]}`"""

  proc lshwHandler(bot: Telebot): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx("lshw -short")[0]}`"""

  proc lsusbHandler(bot: Telebot): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx("lsusb")[0]}`"""

  proc lspciHandler(bot: Telebot): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx("lspci")[0]}`"""

  proc saveworldHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "saveworld"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc listplayersHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "listplayers"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc getchatHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "getchat"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc dayHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "'settimeofday 12:00'"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc nightHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "'settimeofday 4:00'"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc lastversionHandler(bot: Telebot): CommandCallback =
    handlerizer:
      let
        responz = await newAsyncHttpClient().get(ark_api_ver)  # await response
        version = await responz.body                          # await body
        message = fmt"*Ark Survival Evolved Latest Version:* `{version}`"

  proc statusHandler(bot: Telebot): CommandCallback =
    handlerizer:
      let
        responz = await newAsyncHttpClient().get(ark_api_sta)  # await response
        status =  await responz.body                           # await body
        message = fmt"`{status}`"


proc main*() {.async.} =
  ## Main loop of the bot.
  if cli_colors:
    randomize()
    setBackgroundColor(bgBlack)
    setForegroundColor([fgRed, fgGreen, fgYellow, fgBlue, fgMagenta, fgCyan, fgWhite].rand)

  addHandler(newConsoleLogger(fmtStr="$time $levelname "))

  let bot = newTeleBot(api_key)

  if cmd_help:     bot.onCommand("help", helpHandler(bot))
  if cmd_ping:     bot.onCommand("ping", pingHandler(bot))
  if cmd_about:    bot.onCommand("about", aboutHandler(bot))
  if cmd_uptime:   bot.onCommand("uptime", uptimeHandler(bot))
  if cmd_donate:   bot.onCommand("donate", donateHandler(bot))
  if cmd_datetime: bot.onCommand("datetime", datetimeHandler(bot))

  when defined(linux):
    if server_cmd_ip:        bot.onCommand("ip", ipHandler(bot))
    if server_cmd_df:        bot.onCommand("df", dfHandler(bot))
    if server_cmd_free:      bot.onCommand("free", freeHandler(bot))
    if server_cmd_lshw:      bot.onCommand("lshw", lshwHandler(bot))
    if server_cmd_lsusb:     bot.onCommand("lsusb", lsusbHandler(bot))
    if server_cmd_lspci:     bot.onCommand("lspci", lspciHandler(bot))
    if server_cmd_public_ip: bot.onCommand("public_ip", public_ipHandler(bot))

    if ark_cmd_saveworld:    bot.onCommand("saveworld",   saveworldHandler(bot))
    if ark_cmd_listplayers:  bot.onCommand("listplayers", listplayersHandler(bot))
    if ark_cmd_getchat:      bot.onCommand("getchat",     getchatHandler(bot))
    if ark_cmd_day:          bot.onCommand("day",         dayHandler(bot))
    if ark_cmd_night:        bot.onCommand("night",       nightHandler(bot))
    if ark_cmd_lastversion:  bot.onCommand("lastversion", lastversionHandler(bot))
    if ark_cmd_status:       bot.onCommand("status",      statusHandler(bot))
    if ark_cmd_mods:         bot.onCommand("mods",        modsHandler(bot))

  bot.poll(polling_interval * 1000)


when isMainModule:
  waitFor(main())
