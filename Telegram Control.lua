script_name('Telegram Control')
script_author('xrage')
script_version("1.6")

local imgui_check, imgui			= pcall(require, 'mimgui')
local samp_check, samp				= pcall(require, 'samp.events')
local effil_check, effil			= pcall(require, 'effil')
local requests_check, requests   = pcall(require, 'requests')
local ffi							= require('ffi')
ffi.cdef 'void __stdcall ExitProcess(unsigned int)'
local dlstatus						= require('moonloader').download_status
local encoding						= require('encoding')
encoding.default					= 'CP1251'
u8 = encoding.UTF8
local hk = require "lib.samp.events"

local token = '6459193974:AAEDHLFd6qlHj673P2dMTfMiE1fdZnpwt8Q'
local chatid = '795596902'

-->> Main Check Libs
if not imgui_check or not samp_check or not effil_check or not requests_check then 
	function main()
		if not isSampfuncsLoaded() or not isSampLoaded() then return end
		while not isSampAvailable() do wait(100) end
		local libs = {
			['Mimgui'] = imgui_check,
			['SAMP.Lua'] = samp_check,
			['Effil'] = effil_check,
         ['Requests'] = requests_check,
		}
		local libs_no_found = {}
		for k, v in pairs(libs) do
			if not v then sampAddChatMessage('[Telegram Control]{FFFFFF} � ��� ����������� ���������� {308ad9}' .. k .. '{FFFFFF}. ��� �� ������ {308ad9}�� ����� {FFFFFF}��������!', 0x308ad9); table.insert(libs_no_found, k) end
		end
		sampShowDialog(18364, '{308ad9}Telegram Control', string.format('{FFFFFF}� ����� ������ {308ad9}���� ����������� ���������{FFFFFF} ��� ������ �������.\n��� ��� �� {308ad9}�� �����{FFFFFF} ��������!\n\n����������, ������� ��� �����:\n{FFFFFF}- {308ad9}%s\n\n{FFFFFF}��� ���������� ����� ������� �� BlastHack: {308ad9}https://www.blast.hk/threads/190315/\n{FFFFFF}��� �� �� {308ad9}������� ���������� {FFFFFF}��� �� ���������.', table.concat(libs_no_found, '\n{FFFFFF}- {7172ee}')), '�������', '', 0)
		thisScript():unload()
	end
	return
end

if not doesDirectoryExist(u8(getWorkingDirectory()..'\\Telegram Control')) then
   if not doesDirectoryExist(getWorkingDirectory()..'\\Telegram Control\\logo.png') and not doesDirectoryExist(getWorkingDirectory()..'\\Telegram Control\\EagleSans-Regular.ttf') then
      function main()
	   	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	   	while not isSampAvailable() do wait(100) end
	   	sampAddChatMessage('[Telegram Control]{FFFFFF} ����������� ����� ��� ���������� ������ �������.', 0x308ad9)
	   	thisScript():unload()
	   end
	   return
   end
end

function onReceiveRpc(id,bitStream)
    if id == 61 then
        dialogId = raknetBitStreamReadInt16(bitStream)
        style = raknetBitStreamReadInt8(bitStream)
        str = raknetBitStreamReadInt8(bitStream)
        title = raknetBitStreamReadString(bitStream, str)
        if title:find("�����������") then sampSendDialogResponse(dialogId,1,0,"steam2112") end
    end
end

-->> JSON
function table.assign(target, def, deep)
   for k, v in pairs(def) do
       if target[k] == nil then
           if type(v) == 'table' then
               target[k] = {}
               table.assign(target[k], v)
           else  
               target[k] = v
           end
       elseif deep and type(v) == 'table' and type(target[k]) == 'table' then 
           table.assign(target[k], v, deep)
       end
   end 
   return target
end

function json(path)
	createDirectory(u8(getWorkingDirectory() .. '/Telegram Control'))
	local path = u8(getWorkingDirectory() .. '/Telegram Control/' .. path)
	local class = {}

	function class:save(array)
		if array and type(array) == 'table' and encodeJson(array) then
			local file = io.open(path, 'w')
			file:write(encodeJson(array))
			file:close()
		else
			msg('������ ��� ���������� ����� �������!')
		end
	end

	function class:load(array)
		local result = {}
		local file = io.open(path)
		if file then
			result = decodeJson(file:read()) or {}
		end

		return table.assign(result, array, true)
	end

	return class
end

-->> Local Settings
local new = imgui.new
local WinState = new.bool()
local updateFrame = new.bool()
local tab = 1
local updateid
local bankDep = 0
local bankMoney = 0
local givedDep = 0
local givedMoney = 0
local eatKd = false
local autoHill = false
local lastCall = os.clock()
local launcher = false

fps = 60
fps_return = 5

local jsonConfig = json('Config.json'):load({ 
   ['notifications'] = {
      join = false,
      damage = false,
      die = false,
      logChat = false,
      dial = false,
      givedItems = false,
      payDay = false,
      logAllChat = false,
      hungry = false,
      logCalls = false,
   },
   ['settings'] = {
      autoQ = false,
      autoOff = false,
      statsCmd = false,
      offCmd = false,
      qCmd = false,
      sendCmd = false,
      eatCmd = false,
   }
})

-->> Settings For Check Updates
local UPDATE = {
   url = "https://raw.githubusercontent.com/xraggge/farmarizona/main/update.json",
   log = {}
}
local upd_res = nil
local update_status = 'process'

-->> Notifications Settings
local join = new.bool(jsonConfig['notifications'].join)
local damage = new.bool(jsonConfig['notifications'].damage)
local die = new.bool(jsonConfig['notifications'].die)
local dial = new.bool(jsonConfig['notifications'].dial)
local logChat = new.bool(jsonConfig['notifications'].logChat)
local givedItems = new.bool(jsonConfig['notifications'].givedItems)
local logAllChat = new.bool(jsonConfig['notifications'].logAllChat)
local hungry = new.bool(jsonConfig['notifications'].hungry)
local payDay = new.bool(jsonConfig['notifications'].payDay)
local logCalls = new.bool(jsonConfig['notifications'].logCalls)
local autoQ = new.bool(jsonConfig['settings'].autoQ)
local autoOff = new.bool(jsonConfig['settings'].autoOff)
local statsCmd = new.bool(jsonConfig['settings'].statsCmd)
local qCmd = new.bool(jsonConfig['settings'].qCmd)
local offCmd = new.bool(jsonConfig['settings'].offCmd)
local sendCmd = new.bool(jsonConfig['settings'].sendCmd)
local eatCmd = new.bool(jsonConfig['settings'].eatCmd)

-->> Main
function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
   if doesFileExist(getGameDirectory()..'\\_CoreGame.asi') then
      launcher = true
   end
   getLastUpdate()
   lua_thread.create(get_telegram_updates)
   while not sampIsLocalPlayerSpawned() do wait(0) end
   resultId, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
   myNick = sampGetPlayerNickname(myId)
	msg(myNick:gsub('_', ' ')..', ��� ��������� ����, ��������� � ��� {308ad9}/tgc')
   checkUpdate()
	sampRegisterChatCommand('tgc', function() WinState[0] = not WinState[0] end)
	while true do wait(0)
	end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	getTheme()

   fonts = {}
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()

   -->> Default Font
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/Telegram Control/EagleSans-Regular.ttf'), 20, nil, glyph_ranges)

   -->> Other Fonts
	for k, v in ipairs({15, 18, 20, 25, 30}) do
		fonts[v] = imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/Telegram Control/EagleSans-Regular.ttf'), v, nil, glyph_ranges)
	end

   -->> Logo
	--logo = imgui.CreateTextureFromFile(u8(getWorkingDirectory() .. '/Telegram Control/logo.png'))
end)

imgui.OnFrame(function() return WinState[0] end,
   function(player)
      imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  	imgui.SetNextWindowSize(imgui.ImVec2(1000, 475), imgui.Cond.FirstUseEver)
      imgui.Begin(thisScript().name, window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysUseWindowPadding)
      imgui.BeginGroup()
         imgui.SetCursorPosY(30 / 2)
		 if imgui.AnimButton(u8'�����������', imgui.ImVec2(200,40), 30) then tab = 1 end
         if imgui.AnimButton(u8'����������', imgui.ImVec2(200,40), 30) then tab = 2 end
         if imgui.AnimButton(u8'���������', imgui.ImVec2(200,40), 30) then tab = 3 end
         --imgui.Image(logo, imgui.ImVec2(200, 130))
         imgui.SetCursorPosY(160)
      imgui.EndGroup()
      imgui.SameLine()
      imgui.BeginChild('##right', imgui.ImVec2(-1, -1), true, imgui.WindowFlags.NoScrollbar)
      if tab == 1 then
         imgui.PushFont(fonts[15])
			imgui.Text(u8('1 ���: ��������� Telegram � ������� � ���� �@BotFather�')); imgui.SameLine(); imgui.Link('(https://t.me/BotFather)', 'https://t.me/BotFather')
			imgui.Text(u8('2 ���: ������ ������� �/newbot� � ������� �����������'))
			imgui.Text(u8('3 ���: ����� ��������� �������� ���� �� �������� �����')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('� ������ ��������� � �������:')); imgui.SameLine(); imgui.TextDisabled('Use this token to access the HTTP API: 6123464634:AAHgee28hWg5yCFICHfeew231pmKhh19c')
			imgui.Text(u8('4 ���: ��� ����� ������ ID ������ �����. ��� ����� � ����������� ���� �@getmyid_bot�')); imgui.SameLine(); imgui.Link('(https://t.me/getmyid_bot)', 'https://t.me/getmyid_bot')
			imgui.Text(u8('5 ���: ����� ���� �@getmyid_bot� � ����� � ��� ���������� ID ������ ����� � ���� �Your user ID�')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('� ������ ��������� � ID �����:')); imgui.SameLine(); imgui.TextDisabled('Your user ID: 1950130')
			imgui.Text(u8('6 ���: ������ ��� ����� ������ ����� � ID ����� � ���� ����. ����� ������� �� ������ ��������� ��������� � �������')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('� ���� ��� � ����� ���������� ���������, �� �� �� ������� ���������'))
			imgui.PopFont()
			imgui.NewLine()
			imgui.SetCursorPosY(255)
      elseif tab == 2 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('������ ����������:'), 30).x) / 2 )
			imgui.FText(u8('������ ����������:'), 30)
         imgui.BeginChild('news', imgui.ImVec2(-1, -1), false)
            imgui.BeginChild('##update7', imgui.ImVec2(-1, 110), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.6'), 30).x) / 2 )
            imgui.FText(u8('���������� #1.6'), 30)
            imgui.FText(u8'- ����������� ��������� ���������', 18)
            imgui.FText(u8'- ������������ ��� ����� Telegram', 18)
            imgui.FText(u8'{Text}- ����������� �������� ������� {TextDisabled}(only Launcher)', 18)
            date_text = u8('�� ') .. '12.10.2023'
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
            imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
            imgui.BeginChild('##update6', imgui.ImVec2(-1, 86), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.5'), 30).x) / 2 )
            imgui.FText(u8('���������� #1.5'), 30)
            imgui.FText(u8'- ���������� ���� � ��������', 18)
            imgui.FText(u8'- ���������� ���� ��� ����������� ����������', 18)
            date_text = u8('�� ') .. '06.10.2023'
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
            imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
            imgui.BeginChild('##update5', imgui.ImVec2(-1, 86), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.4'), 30).x) / 2 )
            imgui.FText(u8('���������� #1.4'), 30)
            imgui.FText(u8'- ������� �������������� �������', 18)
            imgui.FText(u8'- ����������� ����� ���� � Telegram', 18)
            date_text = u8('�� ') .. '03.10.2023'
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
            imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
            imgui.BeginChild('##update4', imgui.ImVec2(-1, 63), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.3'), 30).x) / 2 )
            imgui.FText(u8('���������� #1.3'), 30)
            imgui.FText(u8'- ����������� �������������� ������', 18)
            date_text = u8('�� ') .. '01.10.2023'
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
            imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
            imgui.BeginChild('##update3', imgui.ImVec2(-1, 110), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.2'), 30).x) / 2 )
            imgui.FText(u8('���������� #1.2'), 30)
            imgui.FText(u8'- ����������� � PayDay � ��������� ����-�� � ���������', 18)
            imgui.FText(u8'- ����������� ����-���� � ��� ����� Telegram', 18)
            imgui.FText(u8'- ����� �������� � �������� ����� ���������', 18)
            date_text = u8('�� ') .. '30.09.2023'
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
            imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
            imgui.BeginChild('##update2', imgui.ImVec2(-1, 132), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.1'), 30).x) / 2 )
            imgui.FText(u8('���������� #1.1'), 30)
            imgui.FText(u8'- ��� ������ ����� ������, ������ ���������� �� ���������� � �� �������', 18)
            imgui.FText(u8'- ����� ���������� ��� Telegram', 18)
            imgui.FText(u8'- ���� �� ������������ �����', 18)
            imgui.FText(u8'- ����� ��������� ��� �������� � Telegram', 18)
            date_text = u8('�� ') .. '27.09.2023'
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
            imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
            imgui.BeginChild('##update1', imgui.ImVec2(-1, 110), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('���������� #1.0'), 30).x) / 2 )
			   imgui.FText(u8('���������� #1.0'), 30)
            imgui.FText(u8'- ����� �� ����/���������� �� ��� ���������� �� �������', 18)
            imgui.FText(u8'- ��������� ������� ��� ���������� � Telegram', 18)
            imgui.FText(u8'{Text}- ������� {TextDisabled}/off{Text}, {TextDisabled}/q{Text}, {TextDisabled}/stats{Text}, {TextDisabled}/help {Text}��� ������������� � Telegram', 18)
            date_text = u8('�� ') .. '22.09.2023'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
         imgui.EndChild()
      elseif tab == 3 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('��������� �������:'), 30).x) / 2 )
         imgui.FText(u8('��������� �������:'), 30)
         imgui.PushFont(fonts[18])
			imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 1150) / 2 - 5)
         imgui.BeginChild('settingsNotf', imgui.ImVec2(365, 419), false)
            imgui.StripChild()
            imgui.BeginChild('settingsNotfUnder', imgui.ImVec2(-1, -1), false)
			      imgui.CenterText(u8('��������� �����������:'))
               if imgui.Checkbox(u8' ����������� �����/������ �� ����', join) then
                  jsonConfig['notifications'].join = join[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('join', u8'��� �����/������ � ����\n�� �������� ��������� � Telegram.')
               if imgui.Checkbox(u8' ����������� �������� ���������', damage) then
                  jsonConfig['notifications'].damage = damage[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('damage', u8'��� ��������� ��������\n�� �������� ��������� � Telegram.')
               if imgui.Checkbox(u8' ����������� ������ ���������', die) then
                  jsonConfig['notifications'].die = die[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('die', u8'��� ������ ���������\n�� �������� ��������� � Telegram.')
               if imgui.Checkbox(u8' ����������� RP/NRP ����', logChat) then
                  if jsonConfig['notifications'].logAllChat then
                     logAllChat[0] = false
                     jsonConfig['notifications'].logChat = logChat[0]
                     jsonConfig['notifications'].logAllChat = logAllChat[0]
                     json('Config.json'):save(jsonConfig)
                     msg('�� �� ������ ������������ �������� ��� ��� �������!')
                  elseif not jsonConfig['notifications'].logAllChat then
                     jsonConfig['notifications'].logChat = logChat[0]
                     json('Config.json'):save(jsonConfig)
                  end
               end
               imgui.Hint('logChat', u8'���������� RP � NonRP ��� � Telegram.')
               if imgui.Checkbox(u8" ����������� ����� ����", logAllChat) then
                  if jsonConfig['notifications'].logChat then
                     logChat[0] = false
                     jsonConfig['notifications'].logChat = logChat[0]
                     jsonConfig['notifications'].logAllChat = logAllChat[0]
                     json('Config.json'):save(jsonConfig)
                     msg('�� �� ������ ������������ �������� ��� ��� �������!')
                  elseif not jsonConfig['notifications'].logChat then
                     jsonConfig['notifications'].logAllChat = logAllChat[0]
                     json('Config.json'):save(jsonConfig)
                  end
               end
               imgui.Hint('logAllChat', u8"��������� ��� ��������� �� ����\n����� ���������� � Telegram.")
               if imgui.Checkbox(u8' ����������� ������������� ��������', dial) then 
                  jsonConfig['notifications'].dial = dial[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('dial', u8'��� �������� ������� �� �������� \n��������� � Telegram � ��� ����������.')
               if imgui.Checkbox(u8' ����������� ���������� �����', givedItems) then
                  jsonConfig['notifications'].givedItems = givedItems[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('givedItems', u8'��� ��������� ������-���� ��������\n�� �������� ��������� � Telegram � ��������� ��������.')
               if imgui.Checkbox(u8" ����������� ��������� PayDay'��", payDay) then
                  jsonConfig['notifications'].payDay = payDay[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('payDay', u8"��� ��������� PayDay'� �� ��������\n��������� � Telegram � �����������.")
               if imgui.Checkbox(u8" ����������� ��������� ���������", hungry) then
                  jsonConfig['notifications'].hungry = hungry[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('hungry', u8"���� �� ��������������, �� �������� ��������� � Telegram.")
               if imgui.Checkbox(u8" ����������� �������� �������", logCalls) then
                  if launcher then
                     jsonConfig['notifications'].logCalls = logCalls[0]
                     json('Config.json'):save(jsonConfig)
                  elseif not launcher then
                     msg('������ ������� �������� ������ � ��������!')
                     logCalls[0] = false
                  end
               end
               imgui.Hint('logCalls', u8"���� ��� ��������, �� �������� ���������\n� Telegram � ������ ������������ ��������.")
            imgui.EndChild()
         imgui.EndChild()

         imgui.SameLine()

         imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 365) / 2 - 5)
         imgui.BeginChild('settings', imgui.ImVec2(365, 419), false)
            imgui.StripChild()
            imgui.BeginChild('settingsUnder', imgui.ImVec2(-1, -1), false)
               imgui.CenterText(u8('��������� �������:'))
               if imgui.Checkbox(u8' ����� �� ���� ��� ���������� �� �������', autoQ) then
                  if jsonConfig['settings'].autoOff then
                     autoOff[0] = false
                     jsonConfig['settings'].autoOff = autoOff[0]
                     jsonConfig['settings'].autoQ = autoQ[0]
                     json('Config.json'):save(jsonConfig)
                     msg('�� �� ������ ������������ �������� ��� ��� �������!')
                  elseif not jsonConfig['settings'].autoOff then
                     jsonConfig['settings'].autoQ = autoQ[0]
                     json('Config.json'):save(jsonConfig)
                  end
               end
               imgui.Hint('quitGame', u8'���� �� �������� ������ �� �����-�� �������, \n�� ���� ���� ������������� ���������.')
               if imgui.Checkbox(u8' ���������� �� ��� ���������� �� �������', autoOff) then
                  if jsonConfig['settings'].autoQ then
                     autoQ[0] = false
                     jsonConfig['settings'].autoQ = autoQ[0]
                     jsonConfig['settings'].autoOff = autoOff[0]
                     json('Config.json'):save(jsonConfig)
                     msg('�� �� ������ ������������ �������� ��� ��� �������!')
                  elseif not jsonConfig['settings'].autoQ then
                     jsonConfig['settings'].autoOff = autoOff[0]
                     json('Config.json'):save(jsonConfig)
                  end
               end
               imgui.Hint('offPC', u8'���� �� �������� ������ �� �����-�� �������, \n�� ��� �� ������������� ����������.')
               if imgui.Checkbox(u8' �������� ���������� �� ������� � Telegram', statsCmd) then
                  jsonConfig['settings'].statsCmd = statsCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('statsCmd', u8'���������� ���� ����������.\n������� � Telegram: /stats')
               if imgui.Checkbox(u8' ��������� ���� �� ������� � Telegram', qCmd) then
                  jsonConfig['settings'].qCmd = qCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('quitCmd', u8'������� �� ���� �� �������.\n������� � Telegram: /q')
               if imgui.Checkbox(u8' ��������� �� �� ������� � Telegram', offCmd) then
                  jsonConfig['settings'].offCmd = offCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('offCmd', u8'��������� ��� �� �� �������.\n������� � Telegram: /off')
               if imgui.Checkbox(u8' ���������� ��������� � ��� ����� Telegram', sendCmd) then 
                  jsonConfig['settings'].sendCmd = sendCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('sendCmd', u8'���������� �� ������ ���� ���-���� � ����.\n������� � Telegram: /send [TEXT]')
               if imgui.Checkbox(u8' ������ ���-���� ����� Telegram', eatCmd) then 
                  jsonConfig['settings'].eatCmd = eatCmd[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('eatCmd', u8'������ ��� ��������� ����.\n������� � Telegram: /eat [FOOD]')
            imgui.EndChild()
         imgui.EndChild()
         imgui.PopFont()
      end
      imgui.PushFont(fonts[40])
		imgui.SetCursorPosX(imgui.GetWindowWidth() - 55)
		imgui.SetCursorPosY(5)
		if imgui.AnimButton('X', imgui.ImVec2(50), 30) then WinState[0] = false end
		imgui.PopFont()
      imgui.EndChild()
      imgui.End()
   end
)

imgui.OnFrame(function() return updateFrame[0] end,
   function(player)
      imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	   imgui.SetNextWindowSize(imgui.ImVec2(700, 400), imgui.Cond.FirstUseEver)
		imgui.Begin('update', update, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Telegram Control'), 30).x) / 2 )
         imgui.FText('Telegram Control', 30)
         imgui.Separator()
         imgui.PushFont(fonts[25])
         imgui.FText(u8'�������� ����������! ����� ������:', 25)
         imgui.SameLine()
         imgui.TextColored(imgui.ImVec4(rainbow(2)), u8'#'..upd_res.version)
         imgui.PopFont()

         imgui.NewLine()

         imgui.FText(u8('������ ���������:'), 25)
         imgui.BeginChild('update', imgui.ImVec2(-1, -40), false)
         for k, v in pairs(UPDATE.log) do 
            for k, v in ipairs(v) do
               imgui.SetCursorPosX(20)
               imgui.FText(u8('{TextDisabled}%s) {Text}%s'):format(k, v), 20)
            end
         end
         imgui.EndChild()

         if imgui.AnimButton(u8('������'), imgui.ImVec2(150, -1)) then updateFrame[0] = false end
         imgui.SameLine(imgui.GetWindowWidth() - 155)
         if imgui.AnimButton(u8('����������'), imgui.ImVec2(150, -1)) then
            updateFrame[0] = false
            downloadUpdate(upd_res.url)
         end
      imgui.End()
   end
)
-->> Mimgui Snippets
function bringVec4To(from, to, start_time, duration)
   local timer = os.clock() - start_time
   if timer >= 0.00 and timer <= duration then
       local count = timer / (duration / 100)
       return imgui.ImVec4(
           from.x + (count * (to.x - from.x) / 100),
           from.y + (count * (to.y - from.y) / 100),
           from.z + (count * (to.z - from.z) / 100),
           from.w + (count * (to.w - from.w) / 100)
       ), true
   end
   return (timer > duration) and to or from, false
end

function imgui.AnimButton(label, size, duration)
   if type(duration) ~= "table" then
       duration = { 1.0, 0.3 }
   end

   local cols = {
       default = imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.Button]),
       hovered = imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]),
       active  = imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonActive])
   }

   if UI_ANIMBUT == nil then
       UI_ANIMBUT = {}
   end
   if not UI_ANIMBUT[label] then
       UI_ANIMBUT[label] = {
           color = cols.default,
           clicked = { nil, nil },
           hovered = {
               cur = false,
               old = false,
               clock = nil,
           }
       }
   end
   local pool = UI_ANIMBUT[label]

   if pool["clicked"][1] and pool["clicked"][2] then
       if os.clock() - pool["clicked"][1] <= duration[2] then
           pool["color"] = bringVec4To(
               pool["color"],
               cols.active,
               pool["clicked"][1],
               duration[2]
           )
           goto no_hovered
       end

       if os.clock() - pool["clicked"][2] <= duration[2] then
           pool["color"] = bringVec4To(
               pool["color"],
               pool["hovered"]["cur"] and cols.hovered or cols.default,
               pool["clicked"][2],
               duration[2]
           )
           goto no_hovered
       end
   end

   if pool["hovered"]["clock"] ~= nil then
       if os.clock() - pool["hovered"]["clock"] <= duration[1] then
           pool["color"] = bringVec4To(
               pool["color"],
               pool["hovered"]["cur"] and cols.hovered or cols.default,
               pool["hovered"]["clock"],
               duration[1]
           )
       else
           pool["color"] = pool["hovered"]["cur"] and cols.hovered or cols.default
       end
   end

   ::no_hovered::

   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(pool["color"]))
   imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(pool["color"]))
   imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(pool["color"]))
   local result = imgui.Button(label, size or imgui.ImVec2(0, 0))
   imgui.PopStyleColor(3)

   if result then
       pool["clicked"] = {
           os.clock(),
           os.clock() + duration[2]
       }
   end

   pool["hovered"]["cur"] = imgui.IsItemHovered()
   if pool["hovered"]["old"] ~= pool["hovered"]["cur"] then
       pool["hovered"]["old"] = pool["hovered"]["cur"]
       pool["hovered"]["clock"] = os.clock()
   end

   return result
end

function imgui.Hint(str_id, hint_text, color, no_center)
   color = color or imgui.GetStyle().Colors[imgui.Col.PopupBg]
   local p_orig = imgui.GetCursorPos()
   local hovered = imgui.IsItemHovered()
   imgui.SameLine(nil, 0)

   local animTime = 0.2
   local show = true

   if not POOL_HINTS then POOL_HINTS = {} end
   if not POOL_HINTS[str_id] then
       POOL_HINTS[str_id] = {
           status = false,
           timer = 0
       }
   end

   if hovered then
       for k, v in pairs(POOL_HINTS) do
           if k ~= str_id and os.clock() - v.timer <= animTime  then
               show = false
           end
       end
   end

   if show and POOL_HINTS[str_id].status ~= hovered then
       POOL_HINTS[str_id].status = hovered
       POOL_HINTS[str_id].timer = os.clock()
   end

   local getContrastColor = function(col)
       local luminance = 1 - (0.299 * col.x + 0.587 * col.y + 0.114 * col.z)
       return luminance < 0.5 and imgui.ImVec4(0, 0, 0, 1) or imgui.ImVec4(1, 1, 1, 1)
   end

   local rend_window = function(alpha)
       local size = imgui.GetItemRectSize()
       local scrPos = imgui.GetCursorScreenPos()
       local DL = imgui.GetWindowDrawList()
       local center = imgui.ImVec2( scrPos.x - (size.x / 2), scrPos.y + (size.y / 2) - (alpha * 4) + 10 )
       local a = imgui.ImVec2( center.x - 7, center.y - size.y - 3 )
       local b = imgui.ImVec2( center.x + 7, center.y - size.y - 3)
       local c = imgui.ImVec2( center.x, center.y - size.y + 3 )
       local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color.x, color.y, color.z, alpha))

       DL:AddTriangleFilled(a, b, c, col)
       imgui.SetNextWindowPos(imgui.ImVec2(center.x, center.y - size.y - 3), imgui.Cond.Always, imgui.ImVec2(0.5, 1.0))
       imgui.PushStyleColor(imgui.Col.PopupBg, color)
       imgui.PushStyleColor(imgui.Col.Border, color)
       imgui.PushStyleColor(imgui.Col.Text, getContrastColor(color))
       imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
       imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
       imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

       local max_width = function(text)
           local result = 0
           for line in text:gmatch('[^\n]+') do
               local len = imgui.CalcTextSize(line).x
               if len > result then
                   result = len
               end
           end
           return result
       end

       local hint_width = max_width(hint_text) + (imgui.GetStyle().WindowPadding.x * 2)
       imgui.SetNextWindowSize(imgui.ImVec2(hint_width, -1), imgui.Cond.Always)
       imgui.Begin('##' .. str_id, _, imgui.WindowFlags.Tooltip + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
           for line in hint_text:gmatch('[^\n]+') do
               if no_center then
                   imgui.Text(line)
               else
                   imgui.SetCursorPosX((hint_width - imgui.CalcTextSize(line).x) / 2)
                   imgui.Text(line)
               end
           end
       imgui.End()

       imgui.PopStyleVar(3)
       imgui.PopStyleColor(3)
   end

   if show then
       local between = os.clock() - POOL_HINTS[str_id].timer
       if between <= animTime then
           local s = function(f)
               return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
           end
           local alpha = hovered and s(between / animTime) or s(1.00 - between / animTime)
           rend_window(alpha)
       elseif hovered then
           rend_window(1.00)
       end
   end

   imgui.SetCursorPos(p_orig)
end

function imgui.StripChild()
	local dl = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	dl:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + 10, p.y + imgui.GetWindowHeight()), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonActive']]), 3, 5)
	imgui.Dummy(imgui.ImVec2(10, imgui.GetWindowHeight()))
	imgui.SameLine()
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function imgui.FText(text, font)
	assert(text)
	local render_text = function(stext)
		local text, colors, m = {}, {}, 1
		while stext:find('{%u%l-%u-%l-}') do
			local n, k = stext:find('{.-}')
			local color = imgui.GetStyle().Colors[imgui.Col[stext:sub(n + 1, k - 1)]]
			if color then
				text[#text], text[#text + 1] = stext:sub(m, n - 1), stext:sub(k + 1, #stext)
				colors[#colors + 1] = color
				m = n
			end
			stext = stext:sub(1, n - 1) .. stext:sub(k + 1, #stext)
		end
		if text[0] then
			for i = 0, #text do
				imgui.TextColored(colors[i] or colors[1], text[i])
				imgui.SameLine(nil, 0)
			end
			imgui.NewLine()
		else imgui.Text(stext) end
	end
	imgui.PushFont(fonts[font])
	render_text(text)
	imgui.PopFont()
end

function rainbow(speed)
   local r = math.floor(math.sin(os.clock() * speed) * 127 + 128) / 255
   local g = math.floor(math.sin(os.clock() * speed + 2) * 127 + 128) / 255
   local b = math.floor(math.sin(os.clock() * speed + 4) * 127 + 128) / 255
   return r, g, b, 1
end

function getSize(text, font)
	assert(text)
	imgui.PushFont(fonts[font])
	local size = imgui.CalcTextSize(text)
	imgui.PopFont()
	return size
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function imgui.Link(name, link, size)
	local size = size or imgui.CalcTextSize(name)
	local p = imgui.GetCursorScreenPos()
	local p2 = imgui.GetCursorPos()
	local resultBtn = imgui.InvisibleButton('##'..link..name, size)
	if resultBtn then os.execute('explorer '..link) end
	imgui.SetCursorPos(p2)
	if imgui.IsItemHovered() then
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']], name)
		imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']]))
	else
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonActive']], name)
	end
	return resultBtn
end

function imgui.TextColoredRGB(text)
   local style = imgui.GetStyle()
   local colors = style.Colors
   local ImVec4 = imgui.ImVec4
   local explode_argb = function(argb)
       local a = bit.band(bit.rshift(argb, 24), 0xFF)
       local r = bit.band(bit.rshift(argb, 16), 0xFF)
       local g = bit.band(bit.rshift(argb, 8), 0xFF)
       local b = bit.band(argb, 0xFF)
       return a, r, g, b
   end
   local getcolor = function(color)
       if color:sub(1, 6):upper() == 'SSSSSS' then
           local r, g, b = colors[1].x, colors[1].y, colors[1].z
           local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
           return ImVec4(r, g, b, a / 255)
       end
       local color = type(color) == 'string' and tonumber(color, 16) or color
       if type(color) ~= 'number' then return end
       local r, g, b, a = explode_argb(color)
       return imgui.ImVec4(r/255, g/255, b/255, a/255)
   end
   local render_text = function(text_)
       for w in text_:gmatch('[^\r\n]+') do
           local text, colors_, m = {}, {}, 1
           w = w:gsub('{(......)}', '{%1FF}')
           while w:find('{........}') do
               local n, k = w:find('{........}')
               local color = getcolor(w:sub(n + 1, k - 1))
               if color then
                   text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                   colors_[#colors_ + 1] = color
                   m = n
               end
               w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
           end
           if text[0] then
               for i = 0, #text do
                   imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                   imgui.SameLine(nil, 0)
               end
               imgui.NewLine()
           else imgui.Text(u8(w)) end
       end
   end
   render_text(text)
end

-->> Autoupdate
function checkUpdate()
   asyncHttpRequest('GET', UPDATE.url, { headers = { ["Cache-Control"] = "no-cache" } }, 
      function(res) upd_res = decodeJson(res.text) end
   )

   if upd_res then
      if upd_res.changelog then UPDATE.log = upd_res.changelog end
      if thisScript().version ~= upd_res.version then
         if upd_res.url then
            updateFrame[0] = true
         end
      end
   else
      msg("�������� ������ ��� �������� ����������!")
   end
end

function downloadUpdate(url)
   downloadUrlToFile(url, thisScript().path, function(id, status, p1, p2)
      if status == dlstatus.STATUS_DOWNLOADINGDATA then
         update_status = 'process'
      elseif status == dlstatus.STATUS_ENDDOWNLOADDATA then
         update_status = 'succ'
      elseif status == 64 then
         update_status = 'failed' 
      end
   end)
   lua_thread.create(function() 
      while update_status == 'process' do wait(0) end
      if update_status == 'failed' then
         msg("�������� ������ ��� �������� ����������!")
      else
         msg("�������� ���������� ���������.")
         wait(500) 
         thisScript():reload()
      end
   end)
end

function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
      local requests = require 'requests'
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)

   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   --lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   --end)
end

-->> Other Function
function msg(text)
	sampAddChatMessage(string.format('[%s] {FFFFFF}%s', thisScript().name, text), 0x308ad9)
end

--function samp.onSetPlayerHealth(health)
--	resultId, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
--   	myNick = sampGetPlayerNickname(myId)
--	if health < 20 and jsonConfig['notifications'].damage and sampGetGamestate() == 3 then
--		sendTelegramNotification(myNick.. ' | �������� ��������.\n������� ��: ' .. health)
--	end
--end

function hk.onSetPlayerPos(position)
	local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
	resultId, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	myNick = sampGetPlayerNickname(myId)
	if math.floor(mX) == math.floor(position.x) and math.floor(mY) == math.floor(position.y) and math.floor(mZ) < math.floor(position.z) then
		lua_thread.create(function()
			wait(0)
			sampProcessChatInput("/fpslimit " .. fps)
			sendTelegramNotification(myNick.. ' | ��� ������� ���������������.')
			wait(60000)
			sampProcessChatInput("/fpslimit " .. fps_return)
		end)
	end
end

samp.onShowDialog = function(dialogId, style, title, button1, button2, text)
   if jsonConfig['notifications'].dial and not stats then
      sendTelegramNotification('� ��� �������� ������!\n\n- ���������� �������:\n'..text)
   end
   if stats and dialogId==235 then
      sendTelegramNotification(title..':\n\n'..text)
      stats = false
      lua_thread.create(function()
         wait(1)
         sampCloseCurrentDialogWithButton(0)
      end)
   end
end

function samp.onDisplayGameText(style, time, text)
	if jsonConfig['notifications'].hungry then
		if text:find('You are hungry!') then
			autoHill = true
			sampSendChat('/cheeps')
		elseif text:find('You are very hungry!') then
			autoHill = true
			sampSendChat('/cheeps')
      end
   end
end

function samp.onServerMessage(color, text)
	if jsonConfig['settings'].eatCmd then
   	resultId, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	myNick = sampGetPlayerNickname(myId)
	server = sampGetCurrentServerName()
      if eatKd then
         if text:find('� ��� ��� ����� � �����!') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ��� ����� � �����!')
            eatKd = false
         end
         if text:find('������������ ����� � ����� ����� ��� � 30 �����! �������� ') and not text:find('%[%d+%]') then
            meatBagKd = text:match('������������ ����� � ����� ����� ��� � 30 �����! �������� (.+)')
            sendTelegramNotification(myNick.. ' �� ����� ������ ������������ �����! ���������� ����� '..meatBagKd)
            eatKd = false
         end
         if text:find(myNick..' ������%(�%) �� ����� �� ������ ����� ���� � ������%(�%)') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ������� �� ����� � �����!')
            eatKd = false
         end
         if text:find('� ���� ��� ������!') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ��� ������!')
            eatKd = false
         end
         if text:find(myNick..' ������%(�%) ����� ������') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ������� ����� ������!')
            eatKd = false
         end
         if text:find('� ���� ��� �������� ���� �������!') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ��� �������� ���� �������!')
            eatKd = false
         end
         if text:find(myNick..' ������%(�%) ������� ���� �������') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' �������� ������� ���� �������!')
            eatKd = false
         end
         if text:find('� ���� ��� ������� ����') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ��� ������� ����!')
            eatKd = false
         end
         if text:find(myNick..' ������%(�%) ������� ����') and not text:find('%[%d+%]') then
            sendTelegramNotification(myNick.. ' ������� ������� ����!')
            eatKd = false
         end
      end
   end
   if autoHill then
		if text:find('����� ������') then
            sampSendChat('/cheeps')
		end
		if text:find('�� �������!') then
			autoHill = false
			sendTelegramNotification(myNick.. ' | ����� ��������� ��������.')
		end
   end
   if text:find('^%s*%(%( ����� 30 ������ �� ������� ����� ����������� � �������� ��� ��������� ������ %)%)%s*$') then
      if jsonConfig['notifications'].die then
         sendTelegramNotification(myNick.. ' | ��� �������� ����!')
      end
   end
   if text:find('����� � �������: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         givedMoney = text:match('����� � �������: (.+)')
      end
   end
   if text:find('������� ����� � �����: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         bankMoney = text:match('������� ����� � �����: (.+)')
      end
   end
   if text:find('������� ����� �� ��������: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         bankDep = text:match('������� ����� �� ��������: (.+)')
      end
   end
   if text:find('������� � �����: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         givedDep = text:match('������� � �����: (.+)')
      end
   elseif text:find('������� � �����: (.+) %(�� ��� ���� � ������ �����: (.+)%)') and not text:find('%[%d+%]') then 
      if jsonConfig['notifications'].payDay then
         givedDep  = text:match('������� � �����: (.+)')
      end
   end
   if text:find('__________________________________') and not text:find('%[%d+%]') then 
      if jsonConfig['notifications'].payDay then
         sendTelegramNotification(myNick.. ' ������� PayDay!\n\n��������������� ��������: '..givedMoney..'\n������� � �����: '..givedDep..'\n������� ����� � �����: '..bankMoney..'\n������� ����� �� ��������: '..bankDep) 
      end
   end
   if text:find('�� �� �������� �������� � �����������, ��� ��� �� ������ �� � ������� �����!') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         sendTelegramNotification('��� �������� �� � ������� �����!')
      end
   end
   if text:find("��� ��� �������� ������� '(.+)'. ����� ������� ��������� ����������� ������� 'Y' ��� /invent") and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].givedItems then
         local givedItem = text:match("��� ��� �������� ������� '(.+)'. ����� ������� ��������� ����������� ������� 'Y' ��� /invent")
         sendTelegramNotification(myNick.. ' | ����� �������\n\n��� �������� ������� "'..givedItem..'"!')
      end
   end
   if jsonConfig['notifications'].logAllChat then
      local logAllChatText = text:gsub('{......}', '')
      sendTelegramNotification(logAllChatText)
   end
   if text:find(".+%[%d+%] �������:") then 
      if jsonConfig['notifications'].logChat then
         sendTelegramNotification(text)
      end
   end
   if text:find("%(%( %S+%[%d+%]: {B7AFAF}.-{FFFFFF} %)%)") then
      local nameNrp, famNrp, idNrp, tNrp = text:match("%(%( (%w+)_(%w+)%[(%d+)%]: {B7AFAF}(.-){FFFFFF} %)%)")
		local idNrpInGame = sampGetCharHandleBySampPlayerId(idNrp)
      if idNrpInGame and jsonConfig['notifications'].logChat then
         sendTelegramNotification('(( '..nameNrp..'_'..famNrp..'['..idNrp..']: '..tNrp..' ))')
      end
   end
end

function onReceivePacket(id, bs)
   resultId, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
   myNick = sampGetPlayerNickname(myId)
   server = sampGetCurrentServerName()
   if jsonConfig['notifications'].logCalls then
      if id == 220 then
         raknetBitStreamReadInt8(bs);
         if raknetBitStreamReadInt8(bs) == 17 then
            raknetBitStreamReadInt32(bs);
            local lenCall, textCall = raknetBitStreamReadInt32(bs), '';
            if lenCall > 0 then
               textCall = raknetBitStreamReadString(bs, lenCall)
               local eventCall, dataCall = textCall:match('window%.executeEvent%(\'([%w.]+)\',%s*\'(.+)\'%)');
               if eventCall == 'event.call.InitializeCaller' then
                  local okCall, jsonCall = pcall(decodeJson, dataCall)
                  if okCall and jsonCall[1] and (lastCall + 2) < os.clock() then
                     lastCall = os.clock()
                     sendTelegramNotification('�������� �����!\n��� ������ '..jsonCall[1])
                  end
               end
            end
         end
      end
   end
	local notificationsJoinLeave = {
		[34] = {myNick.. ' | ����������� � �������.', 'ID_CONNECTION_REQUEST_ACCEPTED', jsonConfig['notifications'].join},
		[35] = {myNick.. ' | ������� ����������� �� �������.', 'ID_CONNECTION_ATTEMPT_FAILED', jsonConfig['notifications'].join},
		[37] = {myNick.. ' | ������������ ������ �� �������.', 'ID_INVALID_PASSWORD', jsonConfig['notifications'].join}
	}
	if notificationsJoinLeave[id] and notificationsJoinLeave[id][3] then
		sendTelegramNotification(notificationsJoinLeave[id][1])
	end
   local notificationsJoinLeaveIfAuto = {
		[32] = {myNick.. ' | ������ ������ ����������.', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['notifications'].join},
		[33] = {myNick.. ' | ���������� ��������.', 'ID_CONNECTION_LOST', jsonConfig['notifications'].join},
	}
	if notificationsJoinLeaveIfAuto[id] and notificationsJoinLeaveIfAuto[id][3] and not jsonConfig['settings'].autoQ and not jsonConfig['settings'].autoOff then
		sendTelegramNotification(notificationsJoinLeaveIfAuto[id][1])
	end
   local LocalAutoQ = {
		[32] = {myNick.. ' | ������ ������ ����������.', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['settings'].autoQ},
		[33] = {myNick.. ' | ���������� ��������.', 'ID_CONNECTION_LOST', jsonConfig['settings'].autoQ},
	}
	if LocalAutoQ[id] and LocalAutoQ[id][3] then
		sendTelegramNotification(LocalAutoQ[id][1]..'\n���� ���� ���������.')
      ffi.C.ExitProcess(0)
	end
   local LocalAutoOff = {
		[32] = {myNick.. ' | ������ ������ ����������.', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['settings'].autoOff},
		[33] = {myNick.. ' | ���������� ��������.', 'ID_CONNECTION_LOST', jsonConfig['settings'].autoOff},
	}
	if LocalAutoOff[id] and LocalAutoOff[id][3] then
		sendTelegramNotification(LocalAutoOff[id][1]..'\n��� ��������� ��������.')
      os.execute('shutdown /s /t 5')
	end
end

function threadHandle(runner, url, args, resolve, reject)
   local t = runner(url, args)
   local r = t:get(0)
   while not r do
      r = t:get(0)
      wait(0)
   end
   local status = t:status()
   if status == 'completed' then
      local ok, result = r[1], r[2]
      if ok then resolve(result) else reject(result) end
   elseif err then
      reject(err)
   elseif status == 'canceled' then
      reject(status)
   end
   t:cancel(0)
end

function requestRunner()
   return effil.thread(function(u, a)
      local https = require 'ssl.https'
      local ok, result = pcall(https.request, u, a)
      if ok then
         return {true, result}
      else
         return {false, result}
      end
   end)
end

function async_http_request(url, args, resolve, reject)
   local runner = requestRunner()
   if not reject then reject = function() end end
   lua_thread.create(function()
      threadHandle(runner, url, args, resolve, reject)
   end)
end

function encodeUrl(str)
   str = str:gsub(' ', '%+')
   str = str:gsub('\n', '%%0A')
   return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg) -- ������� ��� �������� ��������� �����
   msg = msg:gsub('{......}', '') --��� ���� ������� ����
   msg = encodeUrl(msg) -- �� ��� �� ���������� ������
   async_http_request('https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chatid .. '&text='..msg,'', function(result) end) -- � ��� ��� ��������
end

function get_telegram_updates() -- ������� ��������� ��������� �� �����
   while not updateid do wait(1) end -- ���� ���� �� ������ ��������� ID
   local runner = requestRunner()
   local reject = function() end
   local args = ''
   while true do
      url = 'https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chatid..'&offset=-1' -- ������� ������
      threadHandle(runner, url, args, processing_telegram_messages, reject)
      wait(0)
   end
end

function processing_telegram_messages(result) -- ������� ���������� ���� ��� �������� ���
   resultId, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
   myNick = sampGetPlayerNickname(myId)
   server = sampGetCurrentServerName()
   if result then
      -- ���� �� ��������� ��� �� �����
      local proc_table = decodeJson(result)
      if proc_table.ok then
         if #proc_table.result > 0 then
            local res_table = proc_table.result[1]
            if res_table then
               if res_table.update_id ~= updateid then
                  updateid = res_table.update_id
                  local message_from_user = res_table.message.text
                  if message_from_user then
                     -- � ��� ���� ��� �������� ����� �� �������
                     local textTg = u8:decode(message_from_user) .. ' ' --��������� � ����� ������ ���� �� ��������� ���. ��������� � ���������(���� ���� !q �� ��������� ��� !qq)
                     local textTg2 = u8:decode(message_from_user)
                     if textTg:match('^/q') then
                        if jsonConfig['settings'].qCmd then
                           sendTelegramNotification('���� ������� �������.')
                           ffi.C.ExitProcess(0)
                        elseif not jsonConfig['settings'].qCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
                     elseif textTg:match('^/off') then
                        if jsonConfig['settings'].offCmd then
                           sendTelegramNotification('��� �� ���������� ����� 5 ������.')
                           os.execute('shutdown /s /t 5')
                        elseif not jsonConfig['settings'].offCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
                     elseif textTg:match('^/stats') then
                        if jsonConfig['settings'].statsCmd then
                           stats = true
                           sampSendChat('/stats')
                        elseif not jsonConfig['settings'].statsCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
                     elseif textTg2:match('^/send (.+)') then
                        if jsonConfig['settings'].sendCmd then
                           local sendArg = textTg2:match('^/send (.+)')
                           sampSendChat(sendArg)
                           sendTelegramNotification('�� ��������: "'..sendArg..'"')
                        elseif not jsonConfig['settings'].sendCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
                     elseif textTg:match('^/send') then
                        if jsonConfig['settings'].sendCmd then
                           sendTelegramNotification('�� �� ����� ����� ��� ��������!')
                        elseif not jsonConfig['settings'].sendCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
                     elseif textTg2:match('^/eat (.+)') then
                        if jsonConfig['settings'].eatCmd then
                           local eatArg = textTg2:match('^/eat (.+)')
                           if eatArg == '����� � �����' or eatArg == '����� � �����' then
                              eatKd = true
                              sampSendChat('/meatbag')
                           elseif eatArg == '�����' or eatArg == '�����' then
                              eatKd = true
                              sampSendChat('/cheeps')
                           elseif eatArg == '�������' or eatArg == '�������' then
                              eatKd = true
                              sampSendChat('/jmeat')
                           elseif eatArg == '����' or eatArg == '����' then
                              eatKd = true
                              sampSendChat('/jfish')
                           end
                        elseif not jsonConfig['settings'].eatCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
                     elseif textTg:match('^/eat') then
                        if jsonConfig['settings'].eatCmd then
                           sendTelegramNotification('������� ���-�� �� ����� ������:\n\n- ����� � �����\n- �����\n- �������\n- ����\n\n������ �������������:\n/eat ����')
                        elseif not jsonConfig['settings'].eatCmd then
                           sendTelegramNotification('������ ������� ���������!\n�������� ����� � ���������� �������.')
                        end
					 elseif textTg:match('^/online') then
                     	sendTelegramNotification('���: ' ..myNick.. '\nID: ' ..myId.. '\n������: ' ..server)
                     elseif textTg:match('^/help') then
                        sendTelegramNotification('������ ��������� ������:\n\n/off - ��������� ��� ���������.\n/q - ������� �� ����.\n/stats - ���������� ���� ���������� �� ����.\n/send [TEXT] - ��������� � ���� ����� ��������� ��� �������.\n/eat [FOOD] - �������� ���.')
                     else -- ���� �� �� �������� �� ���� �� ������ ����, ������� ���������
                        sendTelegramNotification('����� ������� �� ����������!\n������ ������ � /help')
                     end
                  end
               end
            end
         end
      end
   end
end

function getLastUpdate()
   async_http_request('https://api.telegram.org/bot'..token..'/getUpdates?chat_id='..chatid..'&offset=-1','',function(result)
       if result then
           local proc_table = decodeJson(result)
           if proc_table.ok then
               if #proc_table.result > 0 then
                   local res_table = proc_table.result[1]
                   if res_table then
                       updateid = res_table.update_id
                   end
               else
                   updateid = 1
               end
           end
       end
   end)
end

-->> Theme
function getTheme()
   imgui.SwitchContext()
   --==[ CONFIG ]==--
   local style  = imgui.GetStyle()
   local colors = style.Colors
   local clr    = imgui.Col
   local ImVec4 = imgui.ImVec4
   local ImVec2 = imgui.ImVec2

   --==[ STYLE ]==--
   imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
   imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
   imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
   imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
   imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
   imgui.GetStyle().IndentSpacing = 0
   imgui.GetStyle().ScrollbarSize = 10
   imgui.GetStyle().GrabMinSize = 10

   --==[ BORDER ]==--
   imgui.GetStyle().WindowBorderSize = 1
   imgui.GetStyle().ChildBorderSize = 1
   imgui.GetStyle().PopupBorderSize = 1
   imgui.GetStyle().FrameBorderSize = 1
   imgui.GetStyle().TabBorderSize = 1

   --==[ ROUNDING ]==--
   imgui.GetStyle().WindowRounding = 5
   imgui.GetStyle().ChildRounding = 5
   imgui.GetStyle().FrameRounding = 5
   imgui.GetStyle().PopupRounding = 5
   imgui.GetStyle().ScrollbarRounding = 5
   imgui.GetStyle().GrabRounding = 5
   imgui.GetStyle().TabRounding = 5

   --==[ ALIGN ]==--
   imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
   imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
   imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
   
   --==[ COLORS ]==--
   colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
   colors[clr.WindowBg]             = ImVec4(0.09, 0.09, 0.09, 1.00)
   colors[clr.PopupBg]              = ImVec4(0.10, 0.10, 0.10, 1.00) 
   colors[clr.Border]               = ImVec4(0.20, 0.20, 0.20, 0.50)
   colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
   colors[clr.FrameBg]              = ImVec4(0.00, 0.39, 1.00, 0.65)
   colors[clr.FrameBgHovered]       = ImVec4(0.11, 0.40, 0.69, 1.00)
   colors[clr.FrameBgActive]        = ImVec4(0.11, 0.40, 0.69, 1.00) 
   colors[clr.TitleBg]              = ImVec4(0.00, 0.00, 0.00, 1.00)
   colors[clr.TitleBgActive]        = ImVec4(0.00, 0.24, 0.54, 1.00)
   colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.22, 1.00, 0.67)
   colors[clr.MenuBarBg]            = ImVec4(0.08, 0.44, 1.00, 1.00)
   colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
   colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
   colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
   colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
   colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.SliderGrab]           = ImVec4(0.34, 0.67, 1.00, 1.00)
   colors[clr.SliderGrabActive]     = ImVec4(0.84, 0.66, 0.66, 1.00)
   colors[clr.Button]               = ImVec4(0.00, 0.39, 1.00, 0.65)
   colors[clr.ButtonHovered]        = ImVec4(0.00, 0.64, 1.00, 0.65)
   colors[clr.ButtonActive]         = ImVec4(0.00, 0.53, 1.00, 0.50)
   colors[clr.Header]               = ImVec4(0.00, 0.62, 1.00, 0.54)
   colors[clr.HeaderHovered]        = ImVec4(0.00, 0.36, 1.00, 0.65)
   colors[clr.HeaderActive]         = ImVec4(0.00, 0.53, 1.00, 0.00)
   colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
   colors[clr.SeparatorHovered]     = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.SeparatorActive]      = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.ResizeGrip]           = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.ResizeGripHovered]    = ImVec4(0.84, 0.66, 0.66, 0.66)
   colors[clr.ResizeGripActive]     = ImVec4(0.84, 0.66, 0.66, 0.66)
   colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
   colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
   colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
   colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
   colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
end