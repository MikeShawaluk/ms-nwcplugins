-- Version 2.0

--[[----------------------------------------------------------------
This will draw a glissando line between two notes, with optional text above the line. If either of the notes is a chord, the bottom notehead
of that chord will be the starting or ending point of the line. It is strictly an ornament, and has no effect on playback.
@Pen
Specifies the type for lines: solid, dot, dash or wavy. The default setting is solid.
@Text
The text to appear above the glissando line, drawn in the StaffItalic system font. The default setting is "gliss."
@Scale
The scale factor for the text above the glissando line. This is a value from 5% to 400%, and the default setting is 75%.

The text scale factor can be incremented/decremented by selecting the object and pressing the + or - keys.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@Weight
This will adjust the weight (thickness) of both straight and wavy line types. The range of values is 0.0 to 5.0, where 1 is the standard line weight. The default setting is 1.
--]]----------------------------------------------------------------

local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()
local lineStyles = { 'solid', 'dot', 'dash', 'wavy' }
local squig = '~'
local showBoxes = { edit=true }

local _spec = {
	{ id='Pen', label='Line Style', type='enum', default=lineStyles[1], list=lineStyles },
	{ id='Text', label='Text', type='text', default='gliss.' },
    { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=75 },
    { id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Weight', label='Line Weight', type='float', default=1, min=0, max=5, step=0.1 }
}

local _spec2 = {}

for k, v in ipairs(_spec) do
	_spec2[v.id] = k
end

local function _audit(t)
	if t.Style then
		if (t.Style == 'Wavy') then t.Pen = 'wavy' end
		t.Style = nil
	end
	t.ap = nil
end

local function box(x, y, ap, p)
	local m = (ap == p) and 'strokeandfill' or 'stroke'
	nwcdraw.setPen('solid', 100)
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.roundRect(0.2)
	nwcdraw.endPath(m)
end

local function _draw(t)
	local xyar = nwcdraw.getAspectRatio()
    local _, my = nwcdraw.getMicrons()
	local pen, text, weight = t.Pen, t.Text, t.Weight
	local thickness = my*.3*weight
	local xo, yo = .25, .5
	
	if not priorNote:find('prior', 'note') then return end
	if not nextNote:find('next', 'note') then return end
	
	local x1 = priorNote:xyRight()
    local y1 = priorNote:notePos(1)
	x1 = x1 + xo + t.StartOffsetX
	local y2 = nextNote:notePos(1)
	local x2 = t.EndOffsetX - xo
    local s = y1>y2 and 1 or y1<y2 and -1 or 0
	y1 = y1 - yo*s + t.StartOffsetY
	y2 = y2 + yo*s + t.EndOffsetY
	local angle = math.deg(math.atan2((y2-y1), (x2-x1)*xyar))
	if text ~= '' then
		nwcdraw.alignText('bottom', 'center')
		nwcdraw.setFontClass('StaffItalic')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*t.Scale*.01)
		nwcdraw.moveTo((x1+x2)*.5, (y1+y2)*.5)
		nwcdraw.text(text, angle)
	end
	if pen ~= 'wavy' then
		if thickness ~= 0 then
			nwcdraw.setPen(pen, thickness)	
			nwcdraw.line(x1, y1, x2, y2)
		end
	else
		nwcdraw.alignText('baseline', 'left')
		nwcdraw.setFontClass('StaffSymbols')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*weight)
		local w = nwcdraw.calcTextSize(squig)
		local len = math.sqrt((y2-y1)^2 + ((x2-x1)*xyar)^2)
		local count = math.floor(len/w/xyar)
		nwcdraw.moveTo(x1, y1-1)
		nwcdraw.text(string.rep(squig, count), angle)
	end
	if t.ap and showBoxes[nwcdraw.getTarget()] then
		local ap = tonumber(t.ap)
		box(x1, y1, ap, 1)
		box(x2, y2, ap, 2)
	end
end

local paramTable = {
	{ _spec2.StartOffsetX, _spec2.StartOffsetY },
	{ _spec2.EndOffsetX, _spec2.EndOffsetY },
}

local function toggleParam(t)
	local ap = tonumber(t.ap) or #paramTable
	ap = ap % #paramTable + 1
	t.ap = ap
end

local function updateParam(t, p, dir)
	local s = _spec[p]
	local x = s.id
	t[x] = t[x] + dir*s.step
	t[x] = t[x]
end
	
local function updateActiveParam(t, n, dir)
	local ap = tonumber(t.ap)
	if ap then 
		updateParam(t, paramTable[ap][n], dir)
	end
end

local function updateEnds(t, dir)
	updateParam(t, _spec2.StartOffsetY, dir)
	updateParam(t, _spec2.EndOffsetY, dir)
end

local skip = { Text=true }

local function defaultAllParams(t)
	for k, s in ipairs(_spec) do
		if not skip[s.id] then t[s.id] = t[s.default] end
	end
end

local function defaultActiveParam(t)
	local ap = tonumber(t.ap)
	if ap then
		for i = 1, 2 do
			local s = _spec[paramTable[ap][i]]
			t[s.id] = s.default
		end
	end
end

local function toggleEnum(t, p)
	local s = _spec[p]
	local q = {}
	for k, v in ipairs(s.list) do
		q[v] = k
	end
	t[s.id] = s.list[q[t[s.id]] + 1]
end

local charTable = {
	['+'] = { updateParam, _spec2.Scale, 1 },
	['-'] = { updateParam, _spec2.Scale, -1 },
	['7'] = { updateParam, _spec2.Weight, 1 },
	['1'] = { updateParam, _spec2.Weight, -1 },
	['8'] = { updateActiveParam, 2, 1 },
	['2'] = { updateActiveParam, 2, -1 },
	['6'] = { updateActiveParam, 1, 1 },
	['4'] = { updateActiveParam, 1, -1 },
	['5'] = { toggleParam },
	['9'] = { updateEnds, 1 },
	['3'] = { updateEnds, -1 },
	['0'] = { defaultActiveParam },
	['Z'] = { defaultAllParams },
	['.'] = { toggleEnum, _spec2.Pen },
}

local function _onChar(t, c)
	local ptr = charTable[string.char(c)]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3])
	return true
end


return {
	spec = _spec,
	audit = _audit,
	onChar = _onChar,
	draw = _draw
}
