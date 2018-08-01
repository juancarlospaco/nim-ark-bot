import
  asyncdispatch, httpclient, logging, json, options, ospaths, osproc, parsecfg,
  strformat, strutils, terminal, times, random, posix
import telebot  # nimble install telebot / https://nimble.directory/pkg/telebot / Version 0.3.3
import openexchangerates  # nimble install openexchangerates  https://github.com/juancarlospaco/nim-openexchangerates


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

  cmd_bash0 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin0_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin0_command"))
  cmd_bash1 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin1_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin1_command"))
  cmd_bash2 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin2_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin2_command"))
  cmd_bash3 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin3_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin3_command"))
  cmd_bash4 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin4_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin4_command"))
  cmd_bash5 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin5_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin5_command"))
  cmd_bash6 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin6_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin6_command"))
  cmd_bash7 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin7_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin7_command"))
  cmd_bash8 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin8_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin8_command"))
  cmd_bash9 = (name: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin9_name"), command: config_ini.getSectionValue("bash_plugin_commands", "bash_plugin9_command"))

  ark_cmd_saveworld    = parseBool(config_ini.getSectionValue("ark_commands", "saveworld"))
  ark_cmd_listplayers  = parseBool(config_ini.getSectionValue("ark_commands", "listplayers"))
  ark_cmd_getchat      = parseBool(config_ini.getSectionValue("ark_commands", "getchat"))
  ark_cmd_admin_cmd    = parseBool(config_ini.getSectionValue("ark_commands", "getchat_admin_cmd"))
  ark_cmd_day          = parseBool(config_ini.getSectionValue("ark_commands", "day"))
  ark_cmd_night        = parseBool(config_ini.getSectionValue("ark_commands", "night"))
  ark_cmd_lastversion  = parseBool(config_ini.getSectionValue("ark_commands", "lastversion"))
  ark_cmd_status       = parseBool(config_ini.getSectionValue("ark_commands", "status"))
  ark_cmd_mods         = parseBool(config_ini.getSectionValue("ark_commands", "mods"))
  ark_cmd_destroywilddinos = parseBool(config_ini.getSectionValue("ark_commands", "destroywilddinos"))
  ark_bot_start_notify = parseBool(config_ini.getSectionValue("ark_commands", "bot_start_notify"))

  cmd_geo0 = (lat: parseFloat(config_ini.getSectionValue("geo_location_sharing", "geo_plugin0_lat")), lon: parseFloat(config_ini.getSectionValue("geo_location_sharing", "geo_plugin0_lon")))

  rcon_ip   = config_ini.getSectionValue("rcon_server", "ip")
  rcon_port = config_ini.getSectionValue("rcon_server", "port")
  rcon_pass = config_ini.getSectionValue("rcon_server", "password")
  rcon_cmd = fmt"mcrcon -c -H {rcon_ip} -P {rcon_port} -p {rcon_pass} "

  polling_interval: int8 = parseInt(config_ini.getSectionValue("", "polling_interval")).int8
  oer_api_key = config_ini.getSectionValue("openexchangerates", "api_key")
  oer_currenc = config_ini.getSectionValue("openexchangerates", "currencies").split(",")
  oer_round = parseBool(config_ini.getSectionValue("openexchangerates", "round_prices"))
  oer_client = AsyncOER(timeout: 3, api_key: oer_api_key, base: "USD", local_base: "",
                        round_float: oer_round, prettyprint: false, show_alternative: true)

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

template handlerizerLocation(body: untyped): untyped =
  proc cb(e: Command) {.async.} =
    inc counter
    body
    let
      geo_uri = "*GEO URI:* geo:$1,$2    ".format(latitud, longitud)
      osm_url = "*OSM URL:* https://www.openstreetmap.org/?mlat=$1&mlon=$2".format(latitud, longitud)
    var
      msg = newMessage(e.message.chat.id,  geo_uri & osm_url)
      geo_msg = newLocation(e.message.chat.id, longitud, latitud)
    msg.disableNotification = true
    geo_msg.disableNotification = true
    msg.parseMode = "markdown"
    discard bot.send(geo_msg)
    discard bot.send(msg)
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

proc dollarHandler(bot: Telebot): CommandCallback =
  let
    money_json = waitFor oer_client.latest()      # Updated Prices.
    names_json = waitFor oer_client.currencies()  # Friendly Names.
  var dineros = ""
  for crrncy in money_json.pairs:
    if crrncy[0] in oer_currenc:
      dineros.add fmt"*{crrncy[0]}* _{names_json[crrncy[0]]}_: `{crrncy[1]}`,  "
  handlerizer():
    let message = dineros

proc geoHandler(bot: Telebot, latitud, longitud: float): CommandCallback =
  handlerizerLocation():
    let
      latitud = latitud
      longitud = longitud


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
      var getchat_output = execCmdEx(cmd)[0]
      if not ark_cmd_admin_cmd:
        var filtered_getchat_output = ""
        for chat_line in getchat_output.splitLines():
          if not chat_line.strip.startsWith("ADMIN CMD: "):
            filtered_getchat_output.add(chat_line & "\n")
        getchat_output = filtered_getchat_output.strip
      let message = fmt"""{getchat_output}"""

  proc dayHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "'settimeofday 12:00'"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc nightHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "'settimeofday 4:00'"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc destroywilddinosHandler(bot: Telebot): CommandCallback =
    let cmd = rcon_cmd & "destroywilddinos"
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

  proc cmd_bashHandler(bot: Telebot, command: string): CommandCallback =
    handlerizer():
      let message = fmt"""`{execCmdEx(command)[0]}`"""


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
  if oer_api_key != "": bot.onCommand("dollar", dollarHandler(bot))
  if cmd_geo0.lat != 0.0 and cmd_geo0.lon != 0.0: bot.onCommand("serverlocation", geoHandler(bot, cmd_geo0.lat, cmd_geo0.lon))

  when defined(linux):
    if server_cmd_ip:        bot.onCommand("ip", ipHandler(bot))
    if server_cmd_df:        bot.onCommand("df", dfHandler(bot))
    if server_cmd_free:      bot.onCommand("free", freeHandler(bot))
    if server_cmd_lshw:      bot.onCommand("lshw", lshwHandler(bot))
    if server_cmd_lsusb:     bot.onCommand("lsusb", lsusbHandler(bot))
    if server_cmd_lspci:     bot.onCommand("lspci", lspciHandler(bot))
    if server_cmd_public_ip: bot.onCommand("public_ip", public_ipHandler(bot))

    if ark_cmd_saveworld:    bot.onCommand("saveworld",    saveworldHandler(bot))
    if ark_cmd_listplayers:  bot.onCommand("listplayers",  listplayersHandler(bot))
    if ark_cmd_getchat:      bot.onCommand("getchat",      getchatHandler(bot))
    if ark_cmd_day:          bot.onCommand("day",          dayHandler(bot))
    if ark_cmd_night:        bot.onCommand("night",        nightHandler(bot))
    if ark_cmd_lastversion:  bot.onCommand("lastversion",  lastversionHandler(bot))
    if ark_cmd_status:       bot.onCommand("status",       statusHandler(bot))
    if ark_cmd_mods:         bot.onCommand("mods",         modsHandler(bot))
    if ark_cmd_destroywilddinos: bot.onCommand("destroywilddinos", destroywilddinosHandler(bot))

    if ark_bot_start_notify: echo execCmdEx(rcon_cmd & "'broadcast Ark_Telegram_Bot_Started.'")

    if cmd_bash0.name != "" and cmd_bash0.command != "":
      bot.onCommand($cmd_bash0.name, cmd_bashHandler(bot, cmd_bash0.command))
    if cmd_bash1.name != "" and cmd_bash1.command != "":
      bot.onCommand($cmd_bash1.name, cmd_bashHandler(bot, cmd_bash1.command))
    if cmd_bash2.name != "" and cmd_bash2.command != "":
      bot.onCommand($cmd_bash2.name, cmd_bashHandler(bot, cmd_bash2.command))
    if cmd_bash3.name != "" and cmd_bash3.command != "":
      bot.onCommand($cmd_bash3.name, cmd_bashHandler(bot, cmd_bash3.command))
    if cmd_bash4.name != "" and cmd_bash4.command != "":
      bot.onCommand($cmd_bash4.name, cmd_bashHandler(bot, cmd_bash4.command))
    if cmd_bash5.name != "" and cmd_bash5.command != "":
      bot.onCommand($cmd_bash5.name, cmd_bashHandler(bot, cmd_bash5.command))
    if cmd_bash6.name != "" and cmd_bash6.command != "":
      bot.onCommand($cmd_bash6.name, cmd_bashHandler(bot, cmd_bash6.command))
    if cmd_bash7.name != "" and cmd_bash7.command != "":
      bot.onCommand($cmd_bash7.name, cmd_bashHandler(bot, cmd_bash7.command))
    if cmd_bash8.name != "" and cmd_bash8.command != "":
      bot.onCommand($cmd_bash8.name, cmd_bashHandler(bot, cmd_bash8.command))
    if cmd_bash9.name != "" and cmd_bash9.command != "":
      bot.onCommand($cmd_bash9.name, cmd_bashHandler(bot, cmd_bash9.command))

    discard nice(19.cint)  # smooth cpu priority

  bot.poll(int32(polling_interval * 1000))


when isMainModule:
  waitFor(main())
