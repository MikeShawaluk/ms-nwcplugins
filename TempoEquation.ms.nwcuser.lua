-- Version 0.1

--[[--------------------------------------------------------------------------
This creates a tempo equation. There are single and double note versions, each
with various durations and options

@Type
The equation type, which can be Single Note or Double Note. The default is Double Note.
@SingleLeft
The left side duration for a single note equation. The value can be whole, half, 
quarter, eighth or sixteenth, regular or dotted.  The default value is quarter.
@SingleRight
The right side duration for a single note equation. The value can be whole, half, 
quarter, eighth or sixteenth, regular or dotted.  The default value is quarter.
@DoubleLeft
The left side of a double note equation. The options are beamed eighth notes,
quarter plus eighth note triple, or beamed dotted eighth plus sixteenth notes.
The default is beamed eighth notes.
@DoubleRight
The right side of a double note equation. The options are beamed eighth notes,
quarter plus eighth note triple, or beamed dotted eighth plus sixteenth notes.
The default is quarter plus eighth note triplet.
@Scale
The scale factor for the tempo equation. This is a value from 5% to 400%,
and the default value is 100%.
@ExtendBracket
This setting will extend the triplet bracket to the right of the eighth note
in a quarter plus eighth note triplet. The default value is on.
--]]--------------------------------------------------------------------------

local userObjTypeName = ...
local idx = nwc.ntnidx
local drawidx = nwc.drawpos
local scale

local noteheadSymbols = { Whole = 'i', Half = 'j', Quarter = 'k', Eighth = 'k', Sixteenth = 'k' }
local augDotSymbol, tripletSymbol = 'z', ''
local flagSymbols = { Eighth = '', Sixteenth = '' }
local typeList = { 'Single Note', 'Double Notes' }
local singleList = {
	'Sixteenth', 
	'Sixteenth Dotted', 
	'Eighth',
	'Eighth Dotted',
	'Quarter', 
	'Quarter Dotted', 
	'Half', 
	'Half Dotted', 
	'Whole', 
	'Whole Dotted', 
}
local doubleList = {
	'Beamed Eighths', 
	'Quarter + Eighth Triplet', 
	'Dotted Eighth + Sixteenth', 
}

local _spec = {
	{ id='Type', label='Equation Type', type='enum', default=typeList[2], list=typeList },
	{ id='SingleLeft', label='Single Note Left Side', type='enum', default=singleList[5], list=singleList },
	{ id='SingleRight', label='Single Note Right Side', type='enum', default=singleList[5], list=singleList },
	{ id='DoubleLeft', label='Double Notes Left Side', type='enum', default=doubleList[1], list=doubleList },
	{ id='DoubleRight', label='Double Notes Right Side', type='enum', default=doubleList[2], list=doubleList },
	{ id='Scale', label='Scale (%)', type='int', min=5, max=400, step=5, default=100 },
	{ id='ExtendBracket', label='Extend Triplet Bracket', type='bool', default=true },
}

local function setFontClassScaled(font)
	nwcdraw.setFontClass(font)
	nwcdraw.setFontSize(nwcdraw.getFontSize() * scale)
end

local function _create(t)
	if idx:find('prior', 'user', userObjTypeName) then
		t.Type = idx:userProp('Type')
		t.SingleLeft = idx:userProp('SingleLeft')
		t.SingleRight = idx:userProp('SingleRight')
		t.DoubleLeft = idx:userProp('DoubleLeft')
		t.DoubleRight = idx:userProp('DoubleRight')
		t.Scale = idx:userProp('Scale')
		t.ExtendBracket = idx:userProp('ExtendBracket')
		t.Pos = idx:userProp('Pos')
	end
end

local function drawSingleNote(s)
    local _, my = nwcdraw.getMicrons()
	setFontClassScaled('StaffCueSymbols')
	nwcdraw.setPen('solid', my * scale * .12)
	local dur = s:match('(%S+)')
	local dotted = s:match('( Dotted)')
	local flag = flagSymbols[dur]
	nwcdraw.text(noteheadSymbols[dur])
	if dur ~= 'Whole' then
		nwcdraw.moveBy(-.025 * scale)
		nwcdraw.lineBy(0, 4.5 * scale)
		if flag then
			nwcdraw.moveBy(0, -2.6 * scale)
			nwcdraw.text(flag)
			nwcdraw.moveBy(-.1 * scale, -1.9 * scale)
		else
			nwcdraw.moveBy(0, -4.5 * scale)
		end
	end
	if dotted then 
		nwcdraw.moveBy(.15 * scale)
		nwcdraw.text(augDotSymbol)
	end
end

local function drawDoubleNote(s, t)
    local _, my = nwcdraw.getMicrons()
	setFontClassScaled('StaffCueSymbols')
	nwcdraw.setPen('solid', my * scale * .12)
	local x, y, offset
	if s == doubleList[1] then
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
	elseif s == doubleList[2] then
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
	else
		x, y = nwcdraw.xyPos()
		nwcdraw.moveBy(0.62 * scale, 4.7 * scale)
		nwcdraw.beginPath()
		nwcdraw.rectangle(1.82 * scale, .65 * scale)
		nwcdraw.closeFigure()
		nwcdraw.endPath('fill')
		nwcdraw.moveBy(1.1 * scale, -1.35 * scale)
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

local function drawEquals()
	setFontClassScaled('StaffBold')
	nwcdraw.moveBy(0, -.75 * scale)
	nwcdraw.text(' = ')
	nwcdraw.moveBy(0, .75 * scale)
end

local function _draw(t)
	scale = t.Scale * .01
	nwcdraw.alignText('baseline', 'left')
	if t.Type == typeList[1] then
		drawSingleNote(t.SingleLeft)
		drawEquals()
		drawSingleNote(t.SingleRight)
	else
		drawDoubleNote(t.DoubleLeft, t)
		drawEquals()
		drawDoubleNote(t.DoubleRight, t)
	end

end

local function toggleEnum(t, p)
	local s = _spec[p]
	local q = {}
	local list = s.list
	for k, v in ipairs(list) do
		q[v] = k
	end
	t[s.id] = list[q[t[s.id]] + 1] or list[1]
end

local function updateEnum(t, p1, p2, dir)
	local p = (t.Type == 'Single Note') and p1 or p2
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

local skip = { Type=true }

local function defaultParams(t)
	for k, s in ipairs(_spec) do
		if not skip[s.id] then t[s.id] = s.default end
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
	['7'] = { updateEnum, 2, 4, 1 },
	['1'] = { updateEnum, 2, 4, -1 },
	['9'] = { updateEnum, 3, 5, 1 },
	['3'] = { updateEnum, 3, 5, -1 },
	['5'] = { toggleEnum, 1 },
	['0'] = { toggleBool, 7 },
	['Z'] = { defaultParams },
}

local function _onChar(t, c)
	local x = string.char(c)
	local ptr = charTable[x]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3], ptr[4])
	return true
end

return {
	spec		= _spec,
	create		= _create,
	onChar		= _onChar,
	draw		= _draw,
}
