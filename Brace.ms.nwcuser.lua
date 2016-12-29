-- Version 2.0

--[[----------------------------------------------------------------
This will draw various character shapes of configurable size, weight and direction. They can be useful for lyrics and other purposes.
@Height
The height of the shape, in units of staff position. This is a value from 0 to 100.0, and the default setting is 10.
@Width
The width of the shape, in units of notehead width. This is a value from 0 to 5.0, and the default setting is 1.
@Offset
This will adjust the horizontal position of the shape, in units of notehead width. The range of values is -100.0 to 100.0, and the default setting is 0.
@Weight
The relative line weight (thickness) of the shape. The range of values is 0.1 to 5.0, and the default setting is 1.
@Direction
The direction of the shape: Left or Right. The default setting is Right.
@Shape
The character shape to be drawn, Brace or Bracket. The default is Brace.
--]]----------------------------------------------------------------

local dirList = { 'Right', 'Left'}
local dirMult = { Right=1, Left=-1 }
local shapeList = { 'Brace', 'Bracket' }

local _spec = {
    { id='Height', label='&Height', type='float', step=0.5, min=0, max=100, default=10 },
	{ id='Width', label='&Width', type='float', step=0.1, min=0, max=5, default=1 },
	{ id='Offset', label='&Offset', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Weight', label='&Line Weight', type='float', step=0.1, min=0, max=5, default=1 },
	{ id='Direction', label='&Direction', type='enum', default=dirList[1], list=dirList },
	{ id='Shape', label='&Shape', type='enum', default=shapeList[1], list=shapeList },
}

local _menu = {
	{ type='command', name='Choose Spin Target:', disable=true },
}

for k, s in ipairs(_spec) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type ~= 'enum' then
		a.type = 'command'
		a.separator = k == 1
		_menu[#_menu+1] = a
	end
end
for k, s in ipairs(_spec) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type == 'enum' then
		a.separator = k == 2
		a.type = 'choice'
		a.list = s.list
		_menu[#_menu+1] = a
	end
end

local function _menuInit(t)
	local ap = tonumber(t.ap)
	for k, m in ipairs(_menu) do
		if m.data then
			local s = _spec[m.data]
			if s then
				local v = t[s.id]
				if m.type == 'command' then
					m.checkmark = (k == ap)
					m.name = string.format('%s\t%s', s.label, v)
				else
					m.default = v
				end
			else
				m.checkmark = (k == ap)
			end
		end
	end
end

local function _menuClick(t, menu, choice)
	if choice then
		local m = _menu[menu]
		local s = _spec[m.data]
		t[s.id] = m.list[choice]
	else
		t.ap = menu
	end
end

local function bezSegment(xa, ya, xb, yb, xc, yc, h, w, o)
	nwcdraw.bezier(xa*w+o, ya*h, xb*w+o, yb*h, xc*w+o, yc*h)
end

local function drawCurlyBrace(t)
	local x1, y1, x2, y2, x3, y3 = -.75, 1.5, .25, 4, -.5, 5
	local h, w, o = t.Height*.1, t.Width*dirMult[t.Direction], t.Offset
	local xo = t.Weight*.2
	nwcdraw.moveTo(x3*w+o, y3*h)
	nwcdraw.beginPath()
	bezSegment(x2, y2, x1, y1, 0, 0, h, w, o)
	bezSegment(x1, -y1, x2, -y2, x3, -y3, h, w, o)
	bezSegment(x2+xo, -y2, x1+xo, -y1, 0, 0, h, w, o)
	bezSegment(x1+xo, y1, x2+xo, y2, x3, y3, h, w, o)
	nwcdraw.endPath()
end

local function drawSquareBracket(t)
	local h, w, o = t.Height*.5, t.Width*dirMult[t.Direction], t.Offset
	local xo = t.Weight*.07*dirMult[t.Direction]
	local yo = t.Weight*.07*nwcdraw.getAspectRatio()
	local x1 = w*.4
	nwcdraw.moveTo(o+xo)
	nwcdraw.beginPath()
	nwcdraw.lineBy(0, h+yo, -xo*2-x1, 0, 0, -yo*2, x1, 0)
	nwcdraw.lineBy(0, (-h+yo)*2, -x1, 0, 0, -yo*2, xo*2+x1, 0)
	nwcdraw.endPath()
end

local shapeFunctions = { Brace = drawCurlyBrace, Bracket = drawSquareBracket }

local function _draw(t)
	local _, my = nwcdraw.getMicrons()
	local penWidth = my*0.12
	nwcdraw.setPen('solid', penWidth)
	shapeFunctions[t.Shape](t)
end

local function _spin(t, d)
	t.ap = t.ap or 2 -- default to Height
	local y = _menu[tonumber(t.ap)].data
	if type(y) == 'table' then
		for _, y1 in ipairs(y) do
			local x = _spec[y1].id
			t[x] = t[x] + d*_spec[y1].step
			t[x] = t[x]
		end
	else
		local x = _spec[y].id
		t[x] = t[x] + d*_spec[y].step
		t[x] = t[x]
	end
end

local function _audit(t)
	t.ap = nil
end

return {
	spec = _spec,
	spin = _spin,
	draw = _draw,
	menu = _menu,
	menuInit = _menuInit,
	menuClick = _menuClick,
	audit = _audit,
}
