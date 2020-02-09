-- Version 2.0

--[[-----------------------------------------------------------------------------------------
This plugin creates a visual tempo marking with several enhancements:

 - The tempo value can be general text, rather than just numbers
 - The text font can be specified
 - Several types of swing tempo equation can be included
 - Both leading and trailing text can be included
 - A text scale factor can be applied

Note that this tempo marking is visual only, and does not change the tempo of the score. A regular
tempo marking with Visibility set to Never may be used in conjunction with this object.
@Base
The base note duration. It has the same values as regular Noteworthy tempos, from Eighth through Half Dotted. The default setting is Quarter.

The note durations may be cycled by selecting the object and pressing the numeric keypad 8 and 2 keys.
@Tempo
The tempo value to be displayed to the right of the "=". This can be numeric or text; examples are "ca. 60", "60-70", "ludicrous". The base note and tempo value will be suppressed when the tempo value is blank. It will be surrounded by ( ) if the leading text is non-blank or if a swing tempo equation is present.
@PreText
Leading text for the tempo. The default value is an empty string.
@PostText
Trailing text for the tempo. The default value is an empty string.
@Font
Font to be used for the leading and trailing text, ( ) and = characters. It can be any of the Noteworthy system fonts.
@Scale
The scale factor for the tempo text and symbols. This is a value from 5% to 400%, and the default setting is 100%. It can be increased/decreased by pressing the + or - keys.
@LeftSwing
Left side of the optional swing tempo equation. Options are Double Eighths, Triplet Quarter + Eighth, Dotted Eighth + Sixteenth or None. If None is selected for either the left or right side, the swing tempo equation will be suppressed. The possible values can be cycled by pressing the numeric keypad 1 and 7 keys. The entire swing tempo equation will be surrounded by ( ) when there is no tempo present and there is leading text present. The default setting is None.
@RightSwing
Right side of the optional swing tempo equation. Options are Double Eighths, Triplet Quarter + Eighth, Dotted Eighth + Sixteenth or None. If None is selected for either the left or right side, the swing tempo equation will be suppressed. The possible values can be cycled by pressing the numeric keypad 3 and 9 keys. The entire swing tempo equation will be surrounded by ( ) when there is no tempo present and there is leading text present. The default setting is None.
@ExtendBracket
This setting will extend the swing equation triplet bracket to the right of the eighth note
for the Triplet Quarter + Eighth option. The default value is on.
--]]-----------------------------------------------------------------------------------------

local userObjTypeName = ...
local idx = nwc.ntnidx
local tempoNoteSymbols = { Half = 'F', Quarter = 'G', Eighth = 'H' }
local noteheadSymbol = 'k'
local augDotSymbol = 'z'
local tripletSymbol = ''
local eighthFlagSymbol = ''
local tempoDotSymbol = 'z'
local equalsText = ' = '
local scale
local swingList = { 'None', 'Double Eighths', 'Triplet Quarter + Eighth', 'Dotted Eighth + Sixteenth' }
local tempoBase = nwc.txt.TempoBase

local _spec = {
	{ id='Base', label='Base', type='enum', default='Quarter', list=tempoBase },
	{ id='Tempo', label='Tempo', type='text', default='60' },
	{ id='PreText', label='Leading Text', type='text', default='' },
	{ id='PostText', label='Trailing Text', type='text', default='' },
	{ id='Font', label='Font', type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
    { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=100 },
	{ id='LeftSwing', label='Left Side Swing Notes', type='enum', default=swingList[1], list=swingList },
	{ id='RightSwing', label='Right Side Swing Notes', type='enum', default=swingList[1], list=swingList },
	{ id='ExtendBracket', label='Extend Triplet Bracket', type='bool', default=true },
}

local function setFontClassScaled(font)
	nwcdraw.setFontClass(font)
	nwcdraw.setFontSize(nwcdraw.getFontSize() * scale)
end

local function drawSingleNote(s)
    local _, my = nwcdraw.getMicrons()
	setFontClassScaled('StaffCueSymbols')
	nwcdraw.setPen('solid', my * scale * .12)
	local dur = s:match('(%S+)')
	local dotted = s:match('( Dotted)')
	nwcdraw.text(noteheadSymbol)
	nwcdraw.moveBy(-.025 * scale)
	nwcdraw.lineBy(0, 4.5 * scale)
	if dur == 'Eighth' then
		nwcdraw.moveBy(0, -2.6 * scale)
		nwcdraw.text(eighthFlagSymbol)
		nwcdraw.moveBy(-.1 * scale, -1.9 * scale)
	else
		nwcdraw.moveBy(0, -4.5 * scale)
	end

	if dotted then 
		nwcdraw.text(augDotSymbol)
	end
end

local function drawScaledTextOffset(s, font, offset)
	setFontClassScaled(font)
	nwcdraw.moveBy(0, -offset * scale)
	nwcdraw.text(s)
	nwcdraw.moveBy(0, offset * scale)
end

local function drawScaledTextIf(s, font, cond)
	if cond then
		setFontClassScaled(font)
		nwcdraw.text(s)
	end
end

local function drawDoubleNote(s, t)
    local _, my = nwcdraw.getMicrons()
	setFontClassScaled('StaffCueSymbols')
	nwcdraw.setPen('solid', my * scale * .12)
	local x, y, offset
	if s == swingList[2] then -- Double Eighths
		x, y = nwcdraw.xyPos()
		nwcdraw.moveBy(0.62 * scale, 4.7 * scale)
		nwcdraw.beginPath()
		nwcdraw.rectangle(1.42 * scale, .65 * scale)
		nwcdraw.closeFigure()
		nwcdraw.endPath('fill')
		nwcdraw.moveTo(x, y)
		drawSingleNote('Quarter')
		nwcdraw.moveBy(.7 * scale)
		drawSingleNote('Quarter')
	elseif s == swingList[3] then -- Triplet Quarter + Eighth
		x, y = nwcdraw.xyPos()
		offset = t.ExtendBracket and 0.25 or 0
		nwcdraw.moveBy(-.04 * scale, 5.8 * scale)
		nwcdraw.lineBy(0, .7 * scale, (offset+.8) * scale, 0)
		nwcdraw.moveBy(1 * scale)
		nwcdraw.lineBy((offset+0.65) * scale, 0, 0, -.7 * scale)
		nwcdraw.moveBy((-1.52-offset) * scale, -.3 * scale)
		nwcdraw.text(tripletSymbol)
		nwcdraw.moveTo(x, y)
		drawSingleNote('Quarter')
		nwcdraw.moveBy(1.15 * scale)
		drawSingleNote('Eighth')
	else -- Dotted Eighth + Sixteenth
		x, y = nwcdraw.xyPos()
		nwcdraw.moveBy(0.62 * scale, 4.7 * scale)
		nwcdraw.beginPath()
		nwcdraw.rectangle(1.82 * scale, .65 * scale)
		nwcdraw.closeFigure()
		nwcdraw.endPath('fill')
		nwcdraw.moveBy(1.1 * scale, -1 * scale)
		nwcdraw.beginPath()
		nwcdraw.rectangle(.7 * scale, .65 * scale)
		nwcdraw.closeFigure()
		nwcdraw.endPath('fill')	
		nwcdraw.moveTo(x, y)
		drawSingleNote('Quarter Dotted')
		nwcdraw.moveBy(0.7 * scale)
		drawSingleNote('Quarter')
	end
end

local function _create(t)
	if idx:find('prior', 'user', userObjTypeName) then
		for i,s in ipairs(_spec) do
			t[s.id] = idx:userProp(s.id)
		end
		t.Pos = idx:userProp('Pos')
	end
end

local function _draw(t)
	local tempo = t.Tempo
	local base = t.Base
	local font = t.Font
	local showSwing = t.LeftSwing ~= swingList[1] and t.RightSwing ~= swingList[1]
	scale = t.Scale * .01

	local note = base:match('(%S+)')
	local dotted = base:match('( Dotted)')	

	setFontClassScaled(font)
	nwcdraw.alignText('baseline', 'left')

	drawScaledTextIf(t.PreText, font, true)
	drawScaledTextIf(' ', font, t.PreText ~= '')
	
	if tempo ~= '' then
		local showParens = showSwing or t.PreText ~= ''
		drawScaledTextIf('(', font, showParens)
		setFontClassScaled('StaffSymbols')
		nwcdraw.text(tempoNoteSymbols[note])
		if dotted then
			drawScaledTextOffset(augDotSymbol, 'StaffCueSymbols', -.4)
		end
		setFontClassScaled(font)
		nwcdraw.text(equalsText .. tempo)
		drawScaledTextIf(')', font, showParens)
		nwcdraw.text(' ')
	end
	
	if showSwing then
		local showParens = t.PreText ~= '' and tempo == ''
		drawScaledTextIf('( ', font, showParens)
		drawDoubleNote(t.LeftSwing, t)
		drawScaledTextOffset(equalsText, font, .75)
		drawDoubleNote(t.RightSwing, t)
		drawScaledTextIf(' )', font, showParens)
		nwcdraw.text(' ')
	end
	
	drawScaledTextIf(t.PostText, font, true)
end

local function updateEnum(t, p, dir)
	local s = _spec[p]
	local q = {}
	local list = s.list
	for k, v in ipairs(list) do
		q[v] = k
	end
	local limit = (dir < 0) and 1 or #list
	t[s.id] = list[q[t[s.id]] + dir] or list[limit]
end

local function updateParam(t, p, dir)
	local s = _spec[p]
	local x = s.id
	t[x] = t[x] + dir*s.step
	t[x] = t[x]
end

local function defaultParams(t)
	for k, s in ipairs(_spec) do
		t[s.id] = s.default
	end
end

local function toggleBool(t, p)
	local s = _spec[p]
	local x = s.id
	t[x] = not t[x]
end

local charTable = {
	['+'] = { updateParam, 6, 1 },
	['-'] = { updateParam, 6, -1 },
	['7'] = { updateEnum, 7, 1 },
	['1'] = { updateEnum, 7, -1 },
	['9'] = { updateEnum, 8, 1 },
	['3'] = { updateEnum, 8, -1 },
	['8'] = { updateEnum, 1, 1 },
	['2'] = { updateEnum, 1, -1 },
	['0'] = { toggleBool, 9 },
	['Z'] = { defaultParams },
}

local function _onChar(t, c)
	local x = string.char(c)
	local ptr = charTable[x]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3])
	return true
end

return {
	spec = _spec,
	create = _create,
	onChar = _onChar,
	draw = _draw,
}
