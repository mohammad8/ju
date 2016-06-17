do
local function saveplug(extra, success, result)
  local msg = extra.msg
  local name = extra.name
  local receiver = get_receiver(msg)
  if success then
    local file = 'plugins/'..name..'.lua'
    print('File saving to:', result)
    os.rename(result, file)
    print('File moved to:', file)
  else
    print('Error downloading: '..msg.id)
    send_large_msg(receiver, 'Failed, please try again!', ok_cb, false)
  end
end
local function plugin_enabled( name )
  for k,v in pairs(_config.enabled_plugins) do
    if name == v then
      return k
    end
  end
  -- If not found
  return false
end

local function plugin_exists( name )
  for k,v in pairs(plugins_names()) do
    if name..'.lua' == v then
      return true
    end
  end
  return false
end

local function list_all_plugins(only_enabled)
  local text = ''
  local nsum = 0
  for k, v in pairs( plugins_names( )) do
    local status = '●'
    nsum = nsum+1
    nact = 0
    for k2, v2 in pairs(_config.enabled_plugins) do
      if v == v2..'.lua' then 
        status = '★'
      end
      nact = nact+1
    end
    if not only_enabled or status == '★' then

      v = string.match (v, "(.*)%.lua")
      text = text..nsum..'. '..v..'  '..status..'\n'
    end
  end
  local text = text..'\nThere are '..nsum..' plugins installed.\n'..nact..' plugins enabled and '..nsum-nact..' disabled'
  return text
end

local function list_plugins(only_enabled)
  local text = ''
  local nsum = 0
  for k, v in pairs( plugins_names( )) do
    --  ?? enabled, disabled disabled
    local status = '●'
    nsum = nsum+1
    nact = 0
    -- Check if is enabled
    for k2, v2 in pairs(_config.enabled_plugins) do
      if v == v2..'.lua' then 
        status = '★' 
      end
      nact = nact+1
    end
    if not only_enabled or status == '??' then

      v = string.match (v, "(.*)%.lua")
      text = text..v..'  '..status..'\n'
    end
  end
  local text = text..'\n'..nact..' plugins enabled from '..nsum..' plugins installed.'
  return text
end

local function reload_plugins( )
  plugins = {}
  load_plugins()
  return "Done"
end


local function enable_plugin( plugin_name )
  print('checking if '..plugin_name..' exists')

  if plugin_enabled(plugin_name) then
    return 'Plugin '..plugin_name..' is enabled'
  end

  if plugin_exists(plugin_name) then

    table.insert(_config.enabled_plugins, plugin_name)
    print(plugin_name..' added to _config table')
    save_config()

    return reload_plugins( )
  else
    return 'Plugin '..plugin_name..' does not exists'
  end
end

local function disable_plugin( name, chat )

  if not plugin_exists(name) then
    return 'Plugin '..name..' does not exists'
  end
  local k = plugin_enabled(name)

  if not k then
    return 'Plugin '..name..' not enabled'
  end

  table.remove(_config.enabled_plugins, k)
  save_config( )
  return reload_plugins(true)    
end

local function disable_plugin_on_chat(receiver, plugin)
  if not plugin_exists(plugin) then
    return "Plugin doesn't exists"
  end

  if not _config.disabled_plugin_on_chat then
    _config.disabled_plugin_on_chat = {}
  end

  if not _config.disabled_plugin_on_chat[receiver] then
    _config.disabled_plugin_on_chat[receiver] = {}
  end

  _config.disabled_plugin_on_chat[receiver][plugin] = true

  save_config()
  return 'Done!'
end

local function reenable_plugin_on_chat(receiver, plugin)
  if not _config.disabled_plugin_on_chat then
    return 'There aren\'t any disabled plugins'
  end

  if not _config.disabled_plugin_on_chat[receiver] then
    return 'There aren\'t any disabled plugins for this chat'
  end

  if not _config.disabled_plugin_on_chat[receiver][plugin] then
    return 'This plugin is not disabled'
  end

  _config.disabled_plugin_on_chat[receiver][plugin] = false
  save_config()
  return 'Plugin '..plugin..' is enabled again'
end

local function run(msg, matches)
local receiver = get_receiver(msg)
local group = msg.to.id
    if msg.reply_id then
   local name = matches[2]
      if matches[1] == "addplug" and matches[2] and is_sudo(msg) then
load_document(msg.reply_id, saveplug, {msg=msg,name=name})
        return 'Plugin '..name..' has been saved.'
    end
end
if matches[1]:lower() == 'addplug' and is_sudo(msg) then
  local text = matches[2]
  local b = 1
  local name = matches[3]
  local file = io.open("plugins/"..name..matches[4], "w")
  file:write(text)
  file:flush()
  file:close()
  return "Done!"
  end
if matches[1]:lower() == 'send' and is_sudo(msg) then
send_document(get_receiver(msg), "plugins/"..matches[2]..".lua", ok_cb, false)
end
  if matches[1]:lower() == 'send>' and is_sudo(msg) then
 local plg = io.popen("cat plugins/"..matches[2]..".lua" ):read('*all')
  return plg
end
  if matches[1] == 'plist' and is_sudo(msg) then --after changed to moderator mode, set only sudo
    return list_all_plugins()
  end


  if matches[1] == '+' and matches[3] == 'chat' and is_owner(msg) then
    local receiver = get_receiver(msg)
    local plugin = matches[2]
    print("enable "..plugin..' on this chat')
    return reenable_plugin_on_chat(receiver, plugin)
  end


  if matches[1] == '+' and is_sudo(msg) then --after changed to moderator mode, set only sudo
    local plugin_name = matches[2]
    print("enable: "..matches[2])
    return enable_plugin(plugin_name)
  end


  if matches[1] == '-' and matches[3] == 'chat' and is_owner(msg) then
    local plugin = matches[2]
    local receiver = get_receiver(msg)
    print("disable "..plugin..' on this chat')
    return disable_plugin_on_chat(receiver, plugin)
  end

  if matches[1] == '-' and is_sudo(msg) then
    if matches[2] == 'plugins' then
    	return 'This plugin can\'t be disabled'
    end
    print("disable: "..matches[2])
    return disable_plugin(matches[2])
  end


  if matches[1] == '*' and is_sudo(msg) then
    return reload_plugins(true)
  end
end

return {
  description = "Plugin to manage other plugins. Enable, disable or reload.", 
  usage = {
      moderator = {
          "pl - [plugin] chat : disable plugin only this chat.",
          "pl + [plugin] chat : enable plugin only this chat.",
          },
      sudo = {
          "pl : list all plugins.",
          "pl + [plugin] : enable plugin.",
          "pl - [plugin] : disable plugin.",
          "pl reload : reloads all plugins." },
          },
  patterns = {
    "^[!/#](plist)$",
    "^[!/#]pl? (+) ([%w_%.%-]+)$",
    "^[!/#]pl? (+) ([%w_%.%-]+) (chat)",
    "^[!/#]pl? (-) ([%w_%.%-]+)$",
    "^[!/#]pl? (-) ([%w_%.%-]+) (chat)",
    "^[!/#]pl? (*)$",
	"^[!/#]([Aa]ddplug) (.+) (.*) (.*)$",
	"^[!/#]([Ss]end) (.*)$",
	"^[!/#]([Ss]end>) (.*)$",
	"^[!/#]([Aa]ddplug) (.*)$",
	},
  run = run,
  moderated = true, 

}

end
