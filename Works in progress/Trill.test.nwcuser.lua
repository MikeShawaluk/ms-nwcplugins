-- Version 0.2

--[[----------------------------------------------------------------
This plugin draws a trill above or below a set of notes.
@MinMarks
Specifies a minimum number of trill marks to show after the 'tr'. The default value is 0.
@ExtendToBar
Specifies that the trill marking should extend to the next measure bar. The default setting is checked (on).
@StartOffset
This will adjust the horizontal position of the trill's start point. The range of values 
is -10.00 to 10.00. The default setting is 0.
@EndOffset
This will adjust the horizontal position of the trill's end point. The range of values 
is -10.00 to 10.00. The default setting is 0.
@Accidental
This will optionally insert an accidental symbol between the 'tr' and the first marking. The default setting is None.
@AccStyle
This determines the style of the accidental symbol, when present. The choices are 1 (plain) , 2 (superscripted) and 3 (surrounded by parentheses). The default setting is 1.
@Scale
The scale factor for the trill marking. This is a value from 5% to 400%, and the default setting is 100%.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local tr = '`_'
local sp = '_'
local squig = '-'
local accList = { 'None', 'Sharp', 'Natural', 'Flat', 'Double Sharp', 'Double Flat' }
local accChar = { None='', Sharp='d', Natural='e', Flat='f', ['Double Sharp']='g', ['Double Flat']='h' }

local spec_Trill = {
	{ id='MinMarks', label='Minimum Marks', type='int', default=0, min=0, max=10 },
	{ id='ExtendToBar', label='Extend to Bar', type='bool', default=true },
	{ id='StartOffset', label='Start Offset', type='float', step=0.1, min=-10, max=10, default=0 },
	{ id='EndOffset', label='End Offset', type='float', step=0.1, min=-10, max=10, default=0 },
	{ id='Accidental', label='Accidental', type='enum', default=accList[1], list=accList },
	{ id='AccStyle', label='Accidental Style', type='int', default=1, min=1, max=3},
    { id='Scale', label='Scale (%)', type='int', min=5, max=400, step=5, default=100 },
}

local function draw_Trill(t)
	local span = t.Span
	local scale = t.Scale / 100

	startNote:find('next', 'noteOrRest')
	if not startNote then return end
	local x1 = startNote:xyTimeslot() + t.StartOffset

	endNote:find('next', t.ExtendToBar and 'bar' or 'noteOrRest')

	local x2 = endNote:xyRight() + t.EndOffset
	nwcdraw.alignText('middle', 'left')

	local len = x2-x1
	local acc = accChar[t.Accidental]
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale)
	local squigLen = nwcdraw.calcTextSize(squig)
	local trLen = nwcdraw.calcTextSize(tr)
	local spLen = nwcdraw.calcTextSize(sp)
	nwcdraw.moveTo(x1, 0)
	nwcdraw.text(tr)
	len = len - trLen

	if acc ~= '' then
		local yo, sf = 1, .75
		if t.AccStyle == 2 then yo, sf = .5, .5 end
		nwcdraw.setFontSize(nwcdraw.getFontSize()*sf)
		if t.AccStyle == 3 then acc = '(_' .. acc .. '_)' end
		local accLen = nwcdraw.calcTextSize(acc)
		nwcdraw.moveTo(x1+trLen, scale*(yo-sf))
		nwcdraw.text(acc)
		nwcdraw.moveTo(x1+trLen+accLen+spLen, 0)
		len = len - accLen - spLen
		nwcdraw.setFontSize(nwcdraw.getFontSize()/sf)
	end

	local count = math.max(math.floor(len/squigLen), t.MinMarks)
	nwcdraw.text(string.rep(squig, count))
end

local function spin_Trill(t, d)
	t.AccStyle = t.AccStyle + d
	t.AccStyle = t.AccStyle
end

return {
	spec = spec_Trill,
	spin = spin_Trill,
	draw = draw_Trill
}
