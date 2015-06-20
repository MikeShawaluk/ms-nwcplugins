-- Version 0.5

--[[----------------------------------------------------------------
VerseNumbers.ms

This object will add verse numbers for specified lyric lines. If it is added as a staff signature object, it will add them to
subsequent systems.
--]]----------------------------------------------------------------

local userObjTypeName = ...
local drawpos = nwcdraw.user
local nextVerseNumObj = nwc.ntnidx.new()
local showInTargets = {edit=1, selector=1}

local function doPrintName(showAs)
	nwcdraw.setFont('Arial', 3, 'b')

	local xyar = nwcdraw.getAspectRatio()
	local w,h = nwcdraw.calcTextSize(showAs)
	local w_adj, h_adj = h/xyar, (w*xyar)+2
	if not nwcdraw.isDrawing() then return w_adj end

	nwcdraw.alignText('bottom', 'left')
		
	nwcdraw.moveTo(0,0)
	nwcdraw.beginPath()
	nwcdraw.rectangle(-w_adj,-h_adj)
	nwcdraw.endPath('fill')

	nwcdraw.moveTo(0,0.5)
	nwcdraw.setWhiteout()
	nwcdraw.text(showAs,90)
	nwcdraw.setWhiteout(false)
	return 0
end

local function csplit(str, sep)
	local ret = {}
	if str ~= '' then
		local n = 1
		for w in str:gmatch('([^' .. sep .. ']*)') do
			ret[n] = ret[n] or w
			if w == '' then n = n + 1 end
		end
	end
	return ret
end

local function findLyricPos(o)
	while o:find('next', 'noteOrRest') do
		if o:isLyricPos() then return true end
	end

	return false
end

local function iterateMethod(o, f, i) return function() i = (i or 0)+1 return o[f](o, i) end end

local obj_spec = {
	Class = { type='text', default='StaffSig' },
	StartVerseNumber = { type='int', default=1, min=1, max=99 },
	StartingVerse = { type='int', default=1, min=1, max=8 },
	MaxVerses = { type='int', default=0, min=0, max=8 },
	Separator = { type='int', default=0, min=0, max=8 },
	SpecialText = { type='text', default='' },
	Punctuation = { type='text', default='. ' }
}

local function do_create(t)
	t.Class = t.Class
	t.StartVerseNumber = t.StartVerseNumber
	t.StartingVerse = t.StartingVerse
	t.MaxVerses = t.MaxVerses
	t.Separator = t.Separator
	t.SpecialText = t.SpecialText
	t.Punctuation = t.Punctuation
end

local function do_draw(t)
	local media = nwcdraw.getTarget()
	local w = 0;
	
	if showInTargets[media] and not nwcdraw.isAutoInsert() then
		w = doPrintName(userObjTypeName)
	end
	
	if not nwcdraw.isDrawing() then return w end
	if drawpos:isHidden() then return end
	if not findLyricPos(drawpos) then return end
	if nextVerseNumObj:find('next', 'user', userObjTypeName) then
		if nextVerseNumObj < drawpos then return end
	end
	
	local st = csplit(t.SpecialText, ' ')

	nwcdraw.alignText('middle', 'right')
	nwcdraw.setFontClass('StaffLyric')
	local _, hs = nwcdraw.calcTextSize(' ')
	local s, svn, mv, sv = t.Separator, t.StartVerseNumber, t.MaxVerses, t.StartingVerse
	
	local r = 0
	local xm = math.huge
	for lt, sep in iterateMethod(drawpos, 'lyricSyllable') do
		r = r + 1
		local x, y, a = drawpos:xyLyric(r)
		local w = nwcdraw.calcTextSize(lt)
		xm = math.min(xm, x - (a == 'Center' and .5*w or 0))
	end
	
	r = 0
	for lt, sep in iterateMethod(drawpos, 'lyricSyllable') do
		r = r + 1
		local x, y = drawpos:xyLyric(r)
		if s > 0 and r > sv and (r-sv) % s == 0 then 
			nwcdraw.line(xm-.25, y+.4*hs, xm-2.5, y+.4*hs)
		end
		if r >= sv then
			nwcdraw.moveTo(xm, y)
			local v = st[r] and st[r]:gsub('_', ' ') or tostring(r+svn-sv)
			nwcdraw.text(v .. t.Punctuation)
		end
		if r == mv or r == #st then break end
	end
end


return {
	spec = obj_spec,
	create = do_create,
	width = do_draw,
	draw = do_draw
	}