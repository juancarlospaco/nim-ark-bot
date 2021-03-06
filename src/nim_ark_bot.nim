import
  asyncdispatch, httpclient, logging, json, options, ospaths, osproc, parsecfg,
  strformat, strutils, terminal, times, random, posix, os
import telebot           # nimble install telebot            https://nimble.directory/pkg/telebot
import openexchangerates # nimble install openexchangerates  https://github.com/juancarlospaco/nim-openexchangerates
import zip/zipfiles      # nimble install zip

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
  plugins_folder = getCurrentDir() / "plugins"
  bash_plugins_folder = plugins_folder / "bash"
  static_plugins_folder = plugins_folder / "static"
  config_ini  = loadConfig("config.ini")
  api_key     = config_ini.getSectionValue("", "api_key")
  cli_colors  = parseBool(config_ini.getSectionValue("", "terminal_colors"))
  steamcmd_path = config_ini.getSectionValue("", "steamcmd_path")
  steamcmd_validate = parseBool(config_ini.getSectionValue("", "steamcmd_validate"))
  ark_path = config_ini.getSectionValue("", "ark_path")
  kill_ark = config_ini.getSectionValue("", "kill_ark")
  donate_text = config_ini.getSectionValue("", "donate_text")
  gameusersettings_path = config_ini.getSectionValue("", "gameusersettings_path")
  ip2ping = config_ini.getSectionValue("", "ip2ping")

  cmd_help     = parseBool(config_ini.getSectionValue("commands", "help"))
  cmd_ping     = parseBool(config_ini.getSectionValue("commands", "ping"))
  cmd_about    = parseBool(config_ini.getSectionValue("commands", "about"))
  cmd_uptime   = parseBool(config_ini.getSectionValue("commands", "uptime"))
  cmd_donate   = parseBool(config_ini.getSectionValue("commands", "donate"))
  cmd_datetime = parseBool(config_ini.getSectionValue("commands", "datetime"))
  cmd_rcon     = parseBool(config_ini.getSectionValue("commands", "rcon"))
  cmd_steam    = parseBool(config_ini.getSectionValue("commands", "steam"))
  cmd_updateark = parseBool(config_ini.getSectionValue("commands", "updateark"))
  cmd_backup    = parseBool(config_ini.getSectionValue("commands", "backup"))

  server_cmd_ip    = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "ip"))
  server_cmd_df    = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "df"))
  server_cmd_free  = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "free"))
  server_cmd_lshw  = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "lshw"))
  server_cmd_lsusb = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "lsusb"))
  server_cmd_lspci = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "lspci"))
  server_cmd_public_ip = parseBool(config_ini.getSectionValue("linux_server_admin_commands", "public_ip"))

  ark_cmd_saveworld    = parseBool(config_ini.getSectionValue("ark_commands", "saveworld"))
  ark_cmd_listplayers  = parseBool(config_ini.getSectionValue("ark_commands", "listplayers"))
  ark_cmd_getchat      = parseBool(config_ini.getSectionValue("ark_commands", "getchat"))
  ark_cmd_admin_cmd    = parseBool(config_ini.getSectionValue("ark_commands", "getchat_admin_cmd"))
  ark_cmd_getgamelog   = parseBool(config_ini.getSectionValue("ark_commands", "getgamelog"))
  ark_cmd_day          = parseBool(config_ini.getSectionValue("ark_commands", "day"))
  ark_cmd_night        = parseBool(config_ini.getSectionValue("ark_commands", "night"))
  ark_cmd_synctime     = parseBool(config_ini.getSectionValue("ark_commands", "synctime"))
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

var
  counter: int
  mods_list: seq[string]
try:
  createDir(bash_plugins_folder)
  createDir(static_plugins_folder)
  if gameusersettings_path != "":
    for line in readFile(gameusersettings_path).splitLines:
      if line.startsWith("ActiveMods="):
        mods_list = line.replace("ActiveMods=", "").split(',')
        break
  else:
    mods_list = @[]
except Exception:
  mods_list = @[]
  echo "Failed to parse ActiveMods from GameUserSettings.ini, fallback to No MODs."


template handlerizer(body: untyped): untyped =
  ## Template to send simple markdown chat text messages.
  inc counter
  body
  var msg = newMessage(update.message.chat.id, $message.strip())
  msg.disableNotification = true
  msg.parseMode = "markdown"
  discard bot.send(msg)

template handlerizerLocation(body: untyped): untyped =
  ## Template to send Geo Location sharing.
  inc counter
  body
  let
    geo_uri = "*GEO URI:* geo:$1,$2    ".format(latitud, longitud)
    osm_url = "*OSM URL:* https://www.openstreetmap.org/?mlat=$1&mlon=$2".format(latitud, longitud)
  var
    msg = newMessage(update.message.chat.id,  geo_uri & osm_url)
    geo_msg = newLocation(update.message.chat.id, longitud, latitud)
  msg.disableNotification = true
  geo_msg.disableNotification = true
  msg.parseMode = "markdown"
  discard bot.send(geo_msg)
  discard bot.send(msg)

template handlerizerDocument(body: untyped): untyped =
  ## Template to send attached Document file.
  inc counter
  body
  var document = newDocument(update.message.chat.id, "file://" & document_file_path)
  document.caption = document_caption.strip
  document.disableNotification = true
  discard bot.send(document)

proc handleUpdate(bot: TeleBot, update: Update) {.async.} =
  ## This function implements basic Chat from Telegram to Ark, via in-game Chat.
  inc counter
  var response = update.message.get
  if response.text.isSome:
    let
      who = response.chat.first_name.get.strip & response.chat.last_name.get.strip
      wat = response.text.get.strip.toLowerAscii
      cmd = rcon_cmd & quoteShell("serverchat $1:$2.".format(who, wat))
      message1 = "💬 *ARK ➡️ $1:* `$2`.".format(who, execCmdEx(cmd)[0].strip)
    var
      msg0 = newMessage(response.chat.id, "💬 *$1 ➡️ ARK:* $2.".format(who, wat))
      msg1 = newMessage(response.chat.id, message1)
    msg0.disableNotification = true
    msg1.disableNotification = true
    msg0.parseMode = "markdown"
    msg1.parseMode = "markdown"
    discard await bot.send(msg0)
    discard await bot.send(msg1)

proc public_ipHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let
      responz = await newAsyncHttpClient().get(pub_ip_api)  # await response
      publ_ip = await responz.body                          # await body
      message = fmt"*Server Public IP Address:* `{publ_ip}`"

proc uptimeHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let message = fmt"""⏰ *Uptime:* ⏰
    Ark Server:   `{execCmdEx("uptime --pretty")[0]}`
    Telegram Bot: `{cpuTime() - start_time}`"""

proc pingHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let message = fmt"""`{execCmdEx("ping -c 1 -t 1 -W 1 " & ip2ping)[0]}`"""

proc datetimeHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let message = $now()

proc aboutHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let message = about_texts & $counter

proc helpHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let message = helps_texts

proc donateHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let message = donate_text

proc modsHandler(bot: Telebot, update: Command) {.async.} =
  var mods = "*Ark Survival Evolved MODs:* "
  if mods_list.len > 0:  # Server has Mods.
    mods.add("🔥 Total number of active Ark MODs: " & $mods_list.len)
    for modid in mods_list:
      mods.add("🔌 https://steamcommunity.com/sharedfiles/filedetails/?id=" & $modid)
  else:
    mods = "💩 _The Ark Server has no MODs installed and active._ 💩"
  handlerizer:
    let message = mods

proc dollarHandler(bot: Telebot, update: Command) {.async.} =
  let
    money_json = waitFor oer_client.latest()      # Updated Prices.
    names_json = waitFor oer_client.currencies()  # Friendly Names.
  var dineros = ""
  for crrncy in money_json.pairs:
    if crrncy[0] in oer_currenc:
      dineros.add fmt"*{crrncy[0]}* _{names_json[crrncy[0]]}_: `{crrncy[1]}`,  "
  handlerizer:
    let message = dineros

proc geoHandler(latitud, longitud: float,): CommandCallback =
  proc cb(bot: Telebot, update: Command) {.async.} =
    handlerizerLocation:
      let
        latitud = latitud
        longitud = longitud
  return cb

proc staticHandler(static_file: string): CommandCallback =
  proc cb(bot: Telebot, update: Command) {.async.} =
    handlerizerDocument:
      let
        document_file_path = static_file
        document_caption   = static_file
  return cb

proc rconHandler(bot: Telebot, update: Command) {.async.} =
  let
    rcon_ip   = rcon_ip
    rcon_port = rcon_port
    rcon_pass = rcon_pass
  handlerizer:
    let message = fmt"*RCON IP:* `{rcon_ip}`, *RCON PORT:* `{rcon_port}`, *RCON PASS:* `{rcon_pass}`."

proc steamHandler(bot: Telebot, update: Command) {.async.} =
  handlerizer:
    let
      responz = await newAsyncHttpClient().get(pub_ip_api)
      publ_ip = await responz.body
      respon = await newAsyncHttpClient().get("http://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=" & $publ_ip)
      steam_api = await respon.body
      message = fmt"*Steam API Response:* `{steam_api}`"


when defined(linux):
  proc dfHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let message = fmt"""`{execCmdEx("df --human-readable --local --total --print-type")[0]}`"""

  proc freeHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let message = fmt"""`{execCmdEx("free --human --total --giga")[0]}`"""

  proc ipHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let message = fmt"""`{execCmdEx("ip -brief address")[0]}`"""

  proc lshwHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let message = fmt"""`{execCmdEx("lshw -short")[0]}`"""

  proc lsusbHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let message = fmt"""`{execCmdEx("lsusb")[0]}`"""

  proc lspciHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let message = fmt"""`{execCmdEx("lspci")[0]}`"""

  proc saveworldHandler(bot: Telebot, update: Command) {.async.} =
    echo execCmdEx(rcon_cmd & quoteShell("serverchat World_Saved"))
    let cmd = rcon_cmd & "saveworld"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc listplayersHandler(bot: Telebot, update: Command) {.async.} =
    let cmd = rcon_cmd & "listplayers"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc getgamelogHandler(bot: Telebot, update: Command) {.async.} =
    let cmd = rcon_cmd & "GetGameLog"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc backupHandler(bot: Telebot, update: Command) {.async.} =
    echo execCmdEx(rcon_cmd & quoteShell("serverchat Ark_Server_Backup_Completed"))
    let
      origin = ark_path / "ShooterGame/Saved"
      destin = ark_path / $now() & "-ark-backup.zip"
    var z: ZipArchive
    discard z.open(destin, fmWrite)
    for file2zip in walkDirRec(origin):
      z.addFile(file2zip)
    z.close
    handlerizer:
      let message = fmt"""*Ark Server Backup:* from `{origin}` to `{destin}`."""

  proc getchatHandler(bot: Telebot, update: Command) {.async.} =
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

  proc dayHandler(bot: Telebot, update: Command) {.async.} =
    echo execCmdEx(rcon_cmd & quoteShell("serverchat Ark_Time_set_to_Day"))
    let cmd = rcon_cmd & "'settimeofday 12:00'"
    handlerizer:
      let message = fmt"""*Ark In-Game Time = Day.* `{execCmdEx(cmd)[0]}`"""

  proc nightHandler(bot: Telebot, update: Command) {.async.} =
    echo execCmdEx(rcon_cmd & quoteShell("serverchat Ark_Time_set_to_Night"))
    let cmd = rcon_cmd & "'settimeofday 4:00'"
    handlerizer:
      let message = fmt"""*Ark In-Game Time = Night.* `{execCmdEx(cmd)[0]}`"""

  proc synctimeHandler(bot: Telebot, update: Command) {.async.} =
    echo execCmdEx(rcon_cmd & quoteShell("serverchat Ark_Time_set_to_Real_Life_Time"))
    let
      n0w = now()
      cmd = fmt"{rcon_cmd} 'settimeofday {n0w.hour}:{n0w.minute}'"
    handlerizer:
      let message = fmt"""*Ark In-Game Time = Real Life Time.* `{execCmdEx(cmd)[0]}`"""

  proc destroywilddinosHandler(bot: Telebot, update: Command) {.async.} =
    echo execCmdEx(rcon_cmd & quoteShell("serverchat Ark_Wild_Dinos_Destroyed"))
    let cmd = rcon_cmd & "destroywilddinos"
    handlerizer:
      let message = fmt"""`{execCmdEx(cmd)[0]}`"""

  proc lastversionHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let
        responz = await newAsyncHttpClient().get(ark_api_ver)  # await response
        version = await responz.body                          # await body
        message = fmt"*Ark Survival Evolved Latest Version:* `{version}`"

  proc statusHandler(bot: Telebot, update: Command) {.async.} =
    handlerizer:
      let
        responz = await newAsyncHttpClient().get(ark_api_sta)  # await response
        status =  await responz.body                           # await body
        message = fmt"`{status}`"

  proc cmd_bashHandler(command: string): CommandCallback =
    proc cb(bot: Telebot, update: Command) {.async.} =
      handlerizer:
        let message = fmt"""`{execCmdEx(command)[0]}`"""
    return cb

  proc updatearkHandler(bot: Telebot, update: Command) {.async.} =
    ## This function will try to Update Ark & Ark Mods, lots of trial and error.
    var
      cmd = rcon_cmd & quoteShell("broadcast Updating_Ark_Server_Now.")
      validate = if steamcmd_validate: "validate " else: ""
      output, message: string
      exitCode: int
    handlerizer:
      message = "♻️ *Ark Server and Mods Updater:* Update takes a long time... ♻️"
    (output, exitCode) = execCmdEx(cmd)                   # Broadcast Update.
    for i in 9..0:
      cmd = rcon_cmd & quoteShell("serverchat About_to_Update_Ark_Server: " & $i)
      echo execCmdEx(cmd)
      discard sleepAsync(120 * 1000)
    handlerizer:
      message = "*Broadcasting 'Updating Ark Server':* `$1`".format(output)
    if exitCode == 1:
      cmd = rcon_cmd & "saveworld"
      (output, exitCode) = execCmdEx(cmd)                 # Save the world.
      handlerizer:
        message = "*Executing 'saveworld' on Ark Server:* `$1`".format(output)
      if exitCode == 1:
        cmd = rcon_cmd & quoteShell("broadcast World_Saved,Now_Shutting_Down_Server.")
        (output, exitCode) = execCmdEx(cmd)               # Broadcast shutdown.
        handlerizer:
          message = "*Broadcasting 'Shutting Down Server':* `$1`".format(output)
        if exitCode == 1:
          if kill_ark != "":
            (output, exitCode) = execCmdEx(kill_ark)        # Kill Ark Server.
            handlerizer:
              message = "*Shutting Down the Ark Server:* `$1`".format(output)
          else:
            exitCode = 0
          if exitCode == 0:
            cmd = fmt"{steamcmd_path} +login anonymous +force_install_dir {ark_path} +app_update 376030 {validate}+quit"
            (output, exitCode) = execCmdEx(cmd)           # Update Ark.
            handlerizer:
              message = "*Updating the Ark Server itself:* `$1`".format(output)
            if exitCode == 0:
              if mods_list.len > 0:  # Server has Mods.
                var modupdatelist: string
                for modid in mods_list:
                  modupdatelist.add(fmt"+workshop_download_item 346110 {modid} ")
                cmd = fmt"{steamcmd_path} +login anonymous +force_install_dir {ark_path} {modupdatelist} {validate}+quit"
                (output, exitCode) = execCmdEx(cmd)         # Update Mods.
                handlerizer:
                  message = "*Updating Ark Server MODs:* `$1`".format(output)
              else:  # Server has no Mods?.
                exitCode = 0
              if exitCode == 0:                           # Auto-Restart script should Start Ark.
                handlerizer:
                  message = "♻️ *Ark Server and Mods Updated!:* OK, Completed. ♻️"


proc main*() {.async.} =
  ## Main loop of the bot.
  if cli_colors:
    randomize()
    setBackgroundColor(bgBlack)
    setForegroundColor([fgRed, fgGreen, fgYellow, fgBlue, fgMagenta, fgCyan, fgWhite].rand)

  addHandler(newConsoleLogger(fmtStr="$time $levelname "))

  let bot = newTeleBot(api_key)
  bot.onUpdate(handleUpdate)

  if cmd_help:     bot.onCommand("help",     helpHandler)
  if cmd_ping:     bot.onCommand("ping",     pingHandler)
  if cmd_about:    bot.onCommand("about",    aboutHandler)
  if cmd_uptime:   bot.onCommand("uptime",   uptimeHandler)
  if cmd_donate:   bot.onCommand("donate",   donateHandler)
  if cmd_datetime: bot.onCommand("datetime", datetimeHandler)
  if cmd_rcon:     bot.onCommand("rcon",     rconHandler)
  if cmd_steam:    bot.onCommand("steam",    steamHandler)
  if cmd_backup:   bot.onCommand("backup",   backupHandler)
  if oer_api_key != "": bot.onCommand("dollar", dollarHandler)
  if cmd_geo0.lat != 0.0 and cmd_geo0.lon != 0.0:
    bot.onCommand("serverlocation", geoHandler(cmd_geo0.lat, cmd_geo0.lon))

  for static_file in walkFiles(static_plugins_folder / "/*.*"):
    var (dir, name, ext) = splitFile(static_file)
    bot.onCommand(name.toLowerAscii, staticHandler(static_file))

  when defined(linux):
    if server_cmd_ip:        bot.onCommand("ip",          ipHandler)
    if server_cmd_df:        bot.onCommand("df",          dfHandler)
    if server_cmd_free:      bot.onCommand("free",        freeHandler)
    if server_cmd_lshw:      bot.onCommand("lshw",        lshwHandler)
    if server_cmd_lsusb:     bot.onCommand("lsusb",       lsusbHandler)
    if server_cmd_lspci:     bot.onCommand("lspci",       lspciHandler)
    if server_cmd_public_ip: bot.onCommand("public_ip",   public_ipHandler)

    if ark_cmd_saveworld:    bot.onCommand("saveworld",   saveworldHandler)
    if ark_cmd_listplayers:  bot.onCommand("listplayers", listplayersHandler)
    if ark_cmd_getchat:      bot.onCommand("getchat",     getchatHandler)
    if ark_cmd_getgamelog:   bot.onCommand("getgamelog",  getgamelogHandler)
    if ark_cmd_day:          bot.onCommand("day",         dayHandler)
    if ark_cmd_night:        bot.onCommand("night",       nightHandler)
    if ark_cmd_synctime:     bot.onCommand("synctime",    synctimeHandler)
    if ark_cmd_lastversion:  bot.onCommand("lastversion", lastversionHandler)
    if ark_cmd_status:       bot.onCommand("status",      statusHandler)
    if ark_cmd_mods:         bot.onCommand("mods",        modsHandler)
    if cmd_updateark:        bot.onCommand("updateark",   updatearkHandler)
    if ark_cmd_destroywilddinos: bot.onCommand("destroywilddinos", destroywilddinosHandler)

    for bash_file in walkFiles(bash_plugins_folder / "/*.sh"):
      var (dir, name, ext) = splitFile(bash_file)
      bot.onCommand(name.toLowerAscii, cmd_bashHandler(bash_file))

    if ark_bot_start_notify:
      echo execCmdEx(rcon_cmd & quoteShell("broadcast Ark_Telegram_Bot_Started."))
      echo execCmdEx(rcon_cmd & quoteShell("serverchat Ark_Telegram_Bot_Started."))

    discard nice(19.cint)  # smooth cpu priority

  bot.poll(int32(polling_interval * 1000))


when isMainModule:
  waitFor(main())
