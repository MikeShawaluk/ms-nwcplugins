-- Version 1.0

--[[--------------------------------------------------------------------------
This creates a boxed bar label, which defaults to the bar number when no
text is entered.

When the object is added to a score, the settings will default to those of the
preceding object in the score, if one is present.
@Text
Alternate text to be displayed. When blank, the bar number of the next
encountered bar line is used.
@Font
The font class to be used. The default value is StaffBold.
@Scale
The scale factor for the text and box. This is a value from 5% to 400%; the
default setting is 100%. The + and - keys will increase/decrease the value by 5%.
--]]--------------------------------------------------------------------------

local userObjTypeName = ...
local idx = nwc.ntnidx
local drawidx = nwc.drawpos

local object_spec = {
	{ id='Text', label='Alternate Text', type='text', default='' },
	{ id='Font', label='Font', type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
	{ id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=100 },
}

local function setFontClassScaled(font, scale, text)
	nwcdraw.setFontClass(font)
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale*.01)
	return nwcdraw.calcTextSize(text)
end

local function do_create(t)
	if idx:find('prior', 'user', userObjTypeName) then
		t.Font = idx:userProp('Font')
		t.Scale = idx:userProp('Scale')
		t.Pos = idx:userProp('Pos')
	end
end

local function do_spin(t,d)
	t.Scale = t.Scale + d*5
	t.Scale = t.Scale
end

local function do_draw(t)
	local xyar = nwcdraw.getAspectRatio()
    local _, my = nwcdraw.getMicrons()
	local pen = 'solid'
	drawidx:find('next', 'bar')
	local text = t.Text == '' and drawidx:barCounter()+nwcdraw.getPageSetup('StartingBar') or t.Text
	local thickness = my*.3

	nwcdraw.alignText('middle', 'center')
	local w, h = setFontClassScaled(t.Font, t.Scale, text)
	local hb = h/2 + .3
	local wb = math.max(hb/xyar, w/2 + .2)
	nwcdraw.roundRect(wb, hb)
	nwcdraw.text(text)
end

return {
	spec		= object_spec,
	create		= do_create,
	spin		= do_spin,
	draw		= do_draw,
}
