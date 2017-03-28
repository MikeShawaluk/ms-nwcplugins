-- Version 0.3

--[[--------------------------------------------------------------------------
This draws a measure repeat mark, signifying a measure that is a repetition
of a prior measure. The object only provides the marking; the necessary
notation needs to be present in the score, either as hidden notes in the
current staff, or regular notation in a separate hidden staff.

The object may be placed anywhere in the measure, although the preferred
location is the beginning of the measure.
@Type
Selects between single and double measure repeat marks. The single measure mark
is centered in the repeated measure, while the double measure mark is centered
on the bar line which separates the repeated measures.
@Label
Sets a label number to appear above the repeat mark. For single measure marks,
the label is enclosed in parentheses. For double measure marks, the label is
displayed as is. The + and - keys will increment/decrement the label number value.
The default value is 0, which disables the label. 
@Font
Sets the font for the optional label, from the available font classes. The
default font is StaffBold.
@Scale
The scale factor for the optional label. This is a value from 5% to 400%; the
default setting is 100%.
--]]--------------------------------------------------------------------------

local userObjTypeName = ...
local user = nwcdraw.user
local idx = nwc.ntnidx
local nextBar = nwc.drawpos.new()
local priorBar = nwc.drawpos.new()
local typeList = { 'Single', 'Double' }

local _spec = {
	{ id='Type', label='Repeat Type', type='enum', default=typeList[1], list=typeList },
	{ id='Label', label='Label (0 to disable)', type='int', default=0, min=0, max=100 },
	{ id='Font', label='Label Font', type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
	{ id='Scale', label='Label Scale (%)', type='int', min=5, max=400, step=5, default=100 },
}

local thickness, width, dotOffset, dotSize = 1, 3.5, 1.4, 0.2

local function _create(t)
	if idx:find('prior', 'user', userObjTypeName) then
		t.Type = idx:userProp('Type')
		t.Pos = idx:userProp('Pos')
		t.Font = idx:userProp('Font')
		t.Scale = idx:userProp('Scale')
		local inc = t.Type == typeList[1] and 0 or 1
		t.Label = idx:userProp('Label') + inc
	end
end

local function _spin(t, dir)
	t.Label = t.Label + dir
	t.Label = t.Label
end

local function drawBar(x, y, xyar)
	nwcdraw.moveTo(x-(width+thickness)*0.5/xyar, y-2)
	nwcdraw.beginPath()
	nwcdraw.lineBy(width/xyar, 4, thickness/xyar, 0, -width/xyar, -4)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local function drawDot(x, y)
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.ellipse(dotSize)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local function setFontClassScaled(font, scale, text)
	nwcdraw.setFontClass(font)
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale*.01)
	return nwcdraw.calcTextSize(text)
end

local function _draw(t)
	local xyar = nwcdraw.getAspectRatio()
	local y = -user:staffPos()
    local _, my = nwcdraw.getMicrons()
	local text, x
	
	nwcdraw.setPen('solid', my*0.1)
	nwcdraw.alignText('middle', 'center')
	nwcdraw.setFontClass(t.Font)
	nwcdraw.setFontSize(nwcdraw.getFontSize()*t.Scale*.01)
	if not priorBar:find('prior', 'objType', 'bar', 'timesig', 'clef', 'key') then return end
	if not nextBar:find('next', 'bar') then return end
	local x1 = priorBar:xyRight()
	local x2 = nextBar:xyAnchor()
	
	if t.Type == typeList[1] then
		x = (x1+x2)*0.5
		text = '(' .. t.Label .. ')'
		drawBar(x, y, xyar)
		drawDot(x+dotOffset/xyar, y-1)
		drawDot(x-dotOffset/xyar, y+1)
	else
		x = x2
		text = t.Label
		drawBar(x-thickness/xyar, y, xyar)
		drawBar(x+thickness/xyar, y, xyar)
		drawDot(x+(dotOffset+thickness)/xyar, y-1)
		drawDot(x-(dotOffset+thickness)/xyar, y+1)
	end
	
	if t.Label > 0 then
		nwcdraw.moveTo(x)
		nwcdraw.text(text)
	end	
end

return {
	spec	= _spec,
	create	= _create,
	spin	= _spin,
	draw	= _draw,
}
