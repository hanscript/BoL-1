-- if myHero.charName~='Poppy' then return end

local pi, pi2, atan, cos, sin, sqrt = math.pi, math.pi*2, math.atan, math.cos, math.sin, math.sqrt

local function Normalize(x,z)
    local length  = sqrt(x * x + z * z)
	return { ['x'] = x / length, ['z'] = z / length, }
end

local function NormalizeX(v1, v2, length)
	local x, z
	if v1.x==v2.x then x, z = 1, 1 else x, z = v1.x - v2.x, v1.z - v2.z	end
    local nLength  = sqrt(x * x + z * z)
	return { ['x'] = v2.x + ((x / nLength) * length), ['z'] = v2.z + ((z / nLength) * length)} 
end

local function GetLinePoint(ax, ay, bx, by, cx, cy)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)	
	return { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }, (rL < 0 and 0 or (rL > 1 and 1 or rL)) == rL
end

local function GetPath(unit)
	if unit.hasMovePath then
		if unit.pathCount == 1 then return unit.endPath end
		local unitPath = unit:GetPath(math.max(2,unit.pathIndex))
		if unitPath then
			return {x=unitPath.x,z=unitPath.z}
		end
		return unit.endPath
	end
	return unit
end

local Sector = pi * (110 / 180)
local Sector4 = Sector / 3
local function GeneratePoints(range, pMax, ePos, sPos)
	local points, c = {}, -1
	local v2 = { ['x'] = sPos.x-ePos.x, ['z'] = sPos.z-ePos.z, }
	local a = (v2.x > 0) and pi-atan(v2.z/v2.x) or pi-atan(v2.z/v2.x)+pi
	for i = a, a+Sector, Sector4 do
		if #points==pMax then break end
		points[#points+1] = { 
			['x'] = sPos.x+(range*cos(i)), 
			['z'] = sPos.z-(range*sin(i)),
			['a'] = i,
		}
		c=c+2
		if #points==pMax then break end
		points[#points+1] = { 
			['x'] = sPos.x+(range*cos(i+(pi2-(c*Sector4)))),
			['z'] = sPos.z-(range*sin(i+pi2-(c*Sector4))),
			['a'] = i+pi2-(c*Sector4),
		}
	end
	return points
end
require('HPrediction')

AddLoadCallback(function()
	local version = 0.02
	ScriptUpdate(
		version,
		true, 
		'raw.githubusercontent.com', 
		'/PewPewPew2/BoL/master/Versions/PewPoppy.version', 
		'/PewPewPew2/BoL/master/PewPoppy.lua', 
		SCRIPT_PATH.._ENV.FILE_NAME, 
		function() Print('Update Complete. Please reload. (F9 F9)') end, 
		function() Print('Loaded latest version. v'..version..'.') end, 
		function() Print('New version found, downloading now...') end,
		function() Print('There was an error during update.') end
	)

end)

function Print(text, isError)
	if isError then
		print('<font color=\'#0099FF\'>[PewPoppy] </font> <font color=\'#FF0000\'>'..text..'</font>')	
		return
	end
	print('<font color=\'#0099FF\'>[PewPoppy] </font> <font color=\'#FF6600\'>'..text..'</font>')
end

local Enemies = {}
for i=1, heroManager.iCount do
	local h = heroManager:getHero(i)
	if h and h.team~=myHero.team then
		table.insert(Enemies, h)
	end
end
local PushDistance = {
	[70] = 310,
	[80] = 310,
	[90] = 310,
	[100] = 310,
	[110] = 310,
	[120] = 310,
	[130] = 310,
	[140] = 310,
	[150] = 410,
	[160] = 420,
	[170] = 430,
	[180] = 350,
	[190] = 270,
	[200] = 280,
	[210] = 290,
	[220] = 390,
	[230] = 310,
	[240] = 410,
	[250] = 330,
	[260] = 430,
	[270] = 350,
	[280] = 360,
	[290] = 370,
	[300] = 380,
	[310] = 390,
	[320] = 400,
	[330] = 410,
	[340] = 420,
	[360] = 350,
	[370] = 360,
	[380] = 370,
	[390] = 380,
	[400] = 390,
	[410] = 400,
	[430] = 420,
	[440] = 430,
	[450] = 350,
	[460] = 270,
	[470] = 370,
	[480] = 380,
	[490] = 390,
	[500] = 400,
	[510] = 310,
	[520] = 420,
	[530] = 430,
	[540] = 350,
	[550] = 360,
	[560] = 370,
	[570] = 380,
	[580] = 390,
	[590] = 400,
	[600] = 410,
	[610] = 420,
	[620] = 430,
	[630] = 350,
	[640] = 360,
	[650] = 370,
}		
local HP = HPrediction()
local HP_Q = HPSkillshot({type = 'PromptLine', delay = 0.375, range = 350, width = 150, speed = math.huge})
local HP_R = HPSkillshot({type = 'PromptLine', delay = 0.450, range = 550, width = 275, speed = math.huge})
local HP_R2 = HPSkillshot({type = 'DelayLine', delay = 0, range = 1200, width = 275, speed = 1600})
local pFlash = myHero:GetSpellData(SUMMONER_1).name:lower() == 'summonerflash' and SUMMONER_1 or (myHero:GetSpellData(SUMMONER_2).name:lower() == 'summonerflash') and SUMMONER_2 or nil	
local channelingR = 0
local pMenu = scriptConfig('Poppy', 'Poppy')
pMenu:addParam('info', '-General-', SCRIPT_PARAM_INFO, '')  
pMenu:addParam('Key', ' Carry Key', SCRIPT_PARAM_ONKEYDOWN, false, 32)
pMenu:addParam('KS', 'Killsteal', SCRIPT_PARAM_ONKEYTOGGLE, true, ('T'):byte())
pMenu:addParam('space', '', SCRIPT_PARAM_INFO, '')
pMenu:addParam('info', '-Hammer Shock-', SCRIPT_PARAM_INFO, '')
pMenu:addParam('KSQ', 'Killsteal Q', SCRIPT_PARAM_ONOFF, true)
pMenu:addParam('space', '', SCRIPT_PARAM_INFO, '')
pMenu:addParam('info', '-Heroic Charge-', SCRIPT_PARAM_INFO, '')
pMenu:addParam('FlashKey', 'Flash E', SCRIPT_PARAM_ONKEYDOWN, false, ('C'):byte())
pMenu:addParam('ForceE', 'Force E (No Wall Check)', SCRIPT_PARAM_ONKEYDOWN, false, 20)
pMenu:addParam('space', '  Carry Key must be ON for Force', SCRIPT_PARAM_INFO, '')
pMenu:addParam('space', '', SCRIPT_PARAM_INFO, '')
pMenu:addParam('info', '-Keeper\'s Verdict-', SCRIPT_PARAM_INFO, '')
pMenu:addParam('ForceR', 'Force R', SCRIPT_PARAM_ONKEYDOWN, false, 20)
pMenu:addParam('KSR', 'Killsteal R', SCRIPT_PARAM_ONOFF, true)
pMenu:addParam('MinR', 'Cast R if can hit X', SCRIPT_PARAM_SLICE, 3, 2, 5)
pMenu:addParam('SecondCast', 'Allow Auto Second Cast', SCRIPT_PARAM_ONOFF, true)
local amDashing, poppyShield = 0, nil

local function checkLine(s, e)
	for i=50, 350, 50 do
		local cp = NormalizeX(e, s, i)
		if IsWall2(D3DXVECTOR3(cp.x,myHero.y,cp.z)) then
			return true
		end
	end			
end

local function checkWallCollision(cStart, cEnd)	
	if checkLine(cStart, cEnd) then
		local d1 = Normalize(cStart.x-(cStart.x-(cStart.z-cEnd.z)), cStart.z-(cStart.z+(cStart.x-cEnd.x)))
		local lEnd = {['x'] = cEnd.x + d1.x*-35, ['z'] = cEnd.z + d1.z*-35}
		local lStart = {['x'] = cStart.x + d1.x*-35, ['z'] = cStart.z + d1.z*-35}
		if checkLine(lStart, lEnd) then
			local rEnd = {['x'] = cEnd.x + d1.x*35, ['z'] = cEnd.z + d1.z*35}
			local rStart = {['x'] = cStart.x + d1.x*35, ['z'] = cStart.z + d1.z*35}
			if checkLine(rStart, rEnd) then
				return true
			end
		end
	end
	return false
end

local function checkE(t, from)
	local myPos = from or NormalizeX(GetPath(myHero), myHero, (GetLatency()*0.0005)*myHero.ms)
	local d1 = GetDistance(t, myPos)	
	local p1 = NormalizeX(t, myPos, (d1 + (PushDistance[math.round(d1 * 0.1, 0)*10] or 350)))
	if checkWallCollision(t, p1) then
		if t.hasMovePath then
			local pp = NormalizeX(GetPath(t), t, (d1 / 1800) * t.ms)
			local p2 = NormalizeX(pp, myPos, (GetDistance(pp, myPos) + (PushDistance[math.round(GetDistance(myPos, pp) * 0.1, 0)*10] or 350)))
			if checkWallCollision(pp, p2) then
				return true
			end						
		else
			return true
		end
	end
end

local function immuneCheck(unit)
	local buffs = _Pewalk and _Pewalk.GetBuffs(unit) or {}
	return buffs['blackshield'] == nil and buffs['fioraw'] == nil
end

AddNewPathCallback(function(unit,startPos,endPos,isDash,dashSpeed,dashGravity,dashDistance)
	if unit.valid and isDash and unit.type == 'AIHeroClient' then
		if unit.isMe then
			amDashing = os.clock() + (GetDistance(startPos, endPos) / dashSpeed) - (GetLatency() * 0.0005)
		elseif unit.team ~= myHero.team and amDashing < os.clock() and GetDistanceSqr(startPos, endPos) > 22500 then
			local dp, bp = GetLinePoint(startPos.x, startPos.z, endPos.x, endPos.z, myHero.x, myHero.z)
			if (bp and GetDistanceSqr(dp) < 160000) or GetDistanceSqr(endPos) < 160000 or GetDistanceSqr(startPos) < 160000 then
				CastSpell(_W)
			end
		end
	end
end)

local IceBlocks, Soldiers, J4Wall = {}, {}, {}
local Pillar
AddCreateObjCallback(function(o)
	if o.valid then
		if o.name == 'IceBlock' then
			o.endTime = os.clock() + 4
			table.insert(IceBlocks, o)
		elseif o.name == 'AzirRSoldier' and o.team == myHero.team then
			o.endTime = os.clock() + 4.75
			table.insert(Soldiers, o)
		elseif o.name == 'JarvanIVWall' then
			o.endTime = os.clock() + 3
			table.insert(J4Wall, o)
		elseif o.name == 'PlagueBlock' then
			o.endTime = os.clock() + 5.5
			Pillar = o
		end
	end
end)

function IsWall2(p)
	if IsWall(p) then
		return true
	end
	for i=#IceBlocks, 1, -1 do
		local b = IceBlocks[i]
		if b and b.valid and b.endTime > os.clock() then
			if GetDistanceSqr(p, b) < 3600 then
				return true
			end
		else
			table.remove(IceBlocks, i)
		end
	end
	for i=#J4Wall, 1, -1 do
		local b = J4Wall[i]
		if b and b.valid and b.endTime > os.clock() and not b.dead then
			if GetDistanceSqr(p, b) < 10000 then
				return true
			end
		else
			table.remove(J4Wall, i)
		end
	end
	for i=#Soldiers, 1, -1 do
		local b = Soldiers[i]
		if b and b.valid and b.endTime > os.clock() then
			if GetDistanceSqr(p, b) < 3600 then
				return true
			end
		else
			table.remove(Soldiers, i)
		end
	end
	if Pillar then
		if Pillar.valid and Pillar.endTime > os.clock() then
			if GetDistanceSqr(p, Pillar) < 10000 then
				return true
			end			
		else
			Pillar = nil
		end
	end
end

AddTickCallback(function()
	if pMenu.Key then
		if myHero:CanUseSpell(_Q) == READY then
			local t = _Pewalk.GetTarget(375)
			if t then
				local CP, HC = HP:GetPredict(HP_Q, t, Vector(myHero))
				if CP then
					if HC > 1.4 then
						CastSpell(_Q, CP.x, CP.z)
					elseif pMenu.KS and pMenu.KSQ then
						local qDamage = 15 + (25 * myHero:GetSpellData(_Q).level) + (.8 * myHero.addDamage) + (.06 * t.maxHealth)
						if qDamage > t.health then
							CastSpell(_Q, CP.x, CP.z)
						end
					end
				end
			end
		end
		if myHero:CanUseSpell(_E) == READY then
			local t = _Pewalk.GetTarget(425 + myHero.boundingRadius, true)
			if t then
				if checkE(t) or pMenu.ForceE then
					if immuneCheck(t) then
						CastSpell(_E, t)
					end
				end
			end
			for i, e in ipairs(Enemies) do
				if e~=t and _Pewalk.ValidTarget(e, 425 + myHero.boundingRadius, true) and immuneCheck(e) then
					if _Pewalk.IsHighPriority(e, 2) and checkE(e) then
						CastSpell(_E, e)
					end
				end
			end
		end
		if myHero:CanUseSpell(_R) == READY then
			local t = _Pewalk.GetTarget(450)
			if t then
				local CP, HC, NH = HP:GetPredict(HP_R, t, Vector(myHero), 3)
				if CP and HC > 1 and (NH >= pMenu.MinR or pMenu.ForceR) then
					CastSpell(_R, CP.x, CP.z)
					CastSpell2(_R, D3DXVECTOR3(CP.x,myHero.y,CP.z))
				elseif pMenu.KS and pMenu.KSR and HC > 0.75 then
					local fd = 100 + (myHero:GetSpellData(_R).level * 100) + (myHero.addDamage * 0.9)
					local ar = 100 / (100 + ((t.armor * myHero.armorPenPercent) - myHero.armorPen))
					if t.health + t.shield < fd * ar then
						CastSpell(_R, CP.x, CP.z)
						CastSpell2(_R, D3DXVECTOR3(CP.x,myHero.y,CP.z))
					end
				end
			end				
		end	
	end	
	if pMenu.FlashKey and pFlash then
		if myHero:CanUseSpell(_E) == READY and myHero:CanUseSpell(pFlash) == READY then
			local t = _Pewalk.GetTarget(850)
			local d = (425 + myHero.boundingRadius) ^ 2
			if t and immuneCheck(t) then
				local myPos = NormalizeX(GetPath(myHero), myHero, (GetLatency()*0.0005)*myHero.ms)
				local tPos = NormalizeX(GetPath(t), t, (GetLatency()*0.0005)*t.ms)
				for _, p in ipairs(GeneratePoints(400, 7, tPos, myPos)) do
					if GetDistanceSqr(p, tPos) < d and not IsWall(D3DXVECTOR3(p.x,myHero.y,p.z)) and checkE(tPos, p) then
						CastSpell(pFlash, p.x, p.z)
						DelayAction(function() CastSpell(_E, t) end)
						return
					end
				end
			end
		end
	end
	if channelingR + 4 > os.clock() and pMenu.SecondCast then
		local windUp = os.clock() - channelingR
		if windUp > 1 then
			local t = _Pewalk.GetTarget(1200)
			if t then
				local CP, HC = HP:GetPredict(HP_R2, t, Vector(myHero))
				if CP and HC > 0.5 then
					CastSpell2(_R, D3DXVECTOR3(CP.x, myHero.y, CP.z))
				end
			end
		end
	end
end)

local recip = 0
AddDrawCallback(function()	
	if poppyShield and poppyShield.valid and not poppyShield.dead then
		local tr = poppyShield.time - os.clock()
		if tr > 0 then
			DrawText3D(('%.2f'):format(tr),poppyShield.x,poppyShield.y + 150,poppyShield.z,36,0xFFFF9900,true)
		end
	end
	if pMenu.KS then
		local sr = 70 * (sin(recip) + 2.5)
		local cr = 70 * (cos(recip) + 2.5)
		DrawCircle(myHero.x, myHero.y, myHero.z, sr, RGB(300-sr, 0, sr-70))
		DrawCircle(myHero.x, myHero.y, myHero.z, cr, RGB(300-cr, 0, cr-70))
		recip = recip+0.02
	end
end)
	
AddCreateObjCallback(function(o)
	if o.valid and o.name == 'Shield' and o.team == myHero.team then 
		poppyShield = o
		poppyShield.time = os.clock() + 5 - (GetLatency() * 0.0005)
	end
end)

AddAnimationCallback(function(unit, animation)
	if unit.valid and unit.isMe then
		if animation=='' then
			channelingR = os.clock()
		elseif animation:find('Spell4') then
			channelingR = 0
		end
	end
end)

class "ScriptUpdate"
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    AddDrawCallback(function() self:OnDraw() end)
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
    print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function ScriptUpdate:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.Socket:connect('sx-bol.eu', 80)
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

function ScriptUpdate:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function ScriptUpdate:GetOnlineVersion()
    if self.GotScriptVersion then return end

    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</s'..'ize>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1,ContentEnd-1)))
            self.OnlineVersion = tonumber(self.OnlineVersion)
            if self.OnlineVersion and self.OnlineVersion > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end

function ScriptUpdate:DownloadUpdate()
    if self.GotScriptUpdate then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotScriptUpdate = true
    end
end
