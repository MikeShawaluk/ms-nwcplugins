-- Version 1.0

--[[----------------------------------------------------------------
This plugin will add verse numbers to lyrics on a staff. The numbers will be drawn using the current "StaffLyric" font, to match the size and style of the lyrics. The verse numbers can appear just once,
or will appear on successive systems when Class is set to StaffSig.

Each verse number will be positioned right-justified before the first lyric-bearing note or rest that follows the object. The verse numbers are vertically aligned based on the widest syllable.
@StartVerseNumber
The starting point for numbering the verses. The default setting is 1.
@StartingVerse
The number of the first lyric line to receive a number. The range of values is 1 to 8, and the default setting is 1.
@MaxVerses
The number of the last lyric line to receive a number. The range of values is either 'All', or a number from 1 to 8. The default setting is 'All'.
@Separator
Inserts a short horizontal separator line between the verse numbers every 'n' lyric lines. The default setting is 'Off'.
@SpecialText
Allows a user-specified series of verse labels to be used instead of ascending numbers. To use this, enter the individual labels, separated by spaces. The default setting is an empty string, which disables this option.
@Punctuation
Text to append to each verse number. The default setting is ". " (a period followed by a single space)
--]]----------------------------------------------------------------

local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)
local drawpos = nwcdraw.user
local nextVerseNumObj = nwc.ntnidx.new()

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
local startingVerseList = { '1', '2', '3', '4', '5', '6', '7', '8' }
local maxVerseList = { 'All', '1', '2', '3', '4', '5', '6', '7', '8' }
local separatorList = { 'Off', '1', '2', '3', '4', '5', '6', '7', '8' }

local spec_VerseNumbers = {
	{ id='StartVerseNumber', label='Start Verse Number', type='int', default=1, min=1, max=99 },
	{ id='StartingVerse', label='Starting Verse', type='enum', default=startingVerseList[1], list=startingVerseList },
	{ id='MaxVerses', label='Maximum Verses', type='enum', default=maxVerseList[1], list=maxVerseList },
	{ id='Separator', label='Separator Position', type='enum', default=separatorList[1], list=separatorList },
	{ id='SpecialText', label='Special Text', type='text', default='' },
	{ id='Punctuation', label='Punctuation', type='text', default='. ' }
}

local function create_VerseNumbers(t)
	t.Class = 'StaffSig'
end

local function draw_VerseNumbers(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if not nwcdraw.isDrawing() then return w end

	if drawpos:isHidden() then return end
	if not findLyricPos(drawpos) then return end
	if nextVerseNumObj:find('next', 'user', userObjTypeName) then
		if nextVerseNumObj < drawpos then return end
	end
    local mx, my = nwcdraw.getMicrons()
	local penWidth = my*.189
	nwcdraw.setPen('solid', penWidth)
	local st = csplit(t.SpecialText, ' ')
	nwcdraw.alignText('middle', 'right')
	nwcdraw.setFontClass('StaffLyric')
	local _, hs = nwcdraw.calcTextSize(' ')
	local svn = t.StartVerseNumber
	local sv = tonumber(t.StartingVerse)
	local s = tonumber(t.Separator) or 0
	local mv = tonumber(t.MaxVerses) or 0
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
	spec = spec_VerseNumbers,
	create = create_VerseNumbers,
	width = draw_VerseNumbers,
	draw = draw_VerseNumbers
}