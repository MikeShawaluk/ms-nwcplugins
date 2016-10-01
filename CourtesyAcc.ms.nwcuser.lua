-- Version 0.1

--[[-----------------------------------------------------------------------------------------
This plugin creates a "courtesy" accidental, by drawing ( ) around an existing accidental sign
on a note or chord. It is usually necessary to increase accidental spacing for the
note/chord being ornamented so the markings do not collide with the note.
@Offset
This increases or decreases the distance between the courtesy marks and the accidental
sign being ornamented. It has a range of 0 to 0.50, and the default value is 0.2.
@Note
This specifies which note of the chord should receive the ornament. If the specified note does
not have a visible accidental, then no courtesy marks are added. The default value is 1.
--]]-----------------------------------------------------------------------------------------

local drawpos = nwcdraw.user
local accTable = {
	['v'] = 'h',
	['b'] = 'f',
	['n'] = 'e',
	['#'] = 'd',
	['x'] = 'g',
}
local leftParen, rightParen = '(', ')'
local accFontStuff = {
	[false] = { 'StaffSymbols', 1 },
	[true] = { 'StaffCueSymbols', 0.7 },
}
local _spec = {
    { id='Offset', label='Offset', type='float', min=0, max=0.5, step=0.05, default=0.2 },
	{ id='Note', label='Note number', type='int', min=1, max=20, step=1, default=1 },
}

local function _draw(t)
	if not drawpos:find('next', 'note') then return end
	local isGrace = drawpos:isGrace()
	nwcdraw.setFontClass(accFontStuff[isGrace][1])
	local note, offset = t.Note, t.Offset * accFontStuff[isGrace][2]
	local x, y, acc = drawpos:xyNoteAccidental(note)
	if not acc then return end
	local accWidth = nwcdraw.calcTextSize(accTable[string.char(acc)])
	nwcdraw.alignText('baseline', 'right')
	nwcdraw.moveTo(x - offset, y)
	nwcdraw.text(leftParen)
	nwcdraw.alignText('baseline', 'left')
	nwcdraw.moveTo(x + accWidth + offset, y)
	nwcdraw.text(rightParen)
end

local function updateParam(t, n, dir)
	local s = _spec[n]
	local x = s.id
	t[x] = t[x] + dir * s.step
	t[x] = t[x]
end

local charTable = {
	['8'] = { updateParam, 2, 1 },
	['2'] = { updateParam, 2, -1 },
	['+'] = { updateParam, 1, 1 },
	['-'] = { updateParam, 1, -1 },
}

local function _onChar(t, c)
	local x = string.char(c)
	local ptr = charTable[x]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3])
	return true
end

return {
	onChar = _onChar,
	draw = _draw,
	spec = _spec,
}