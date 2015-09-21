-- Version 0.5

--[[----------------------------------------------------------------
This plugin draws a trill above or below a set of notes, and optionally plays the trill.
@Span
The number of notes/chords over which the trill line will extend and the trill will play. A setting of 0 will also specify the initial
note for playback duration, and will suppress the line. The default setting is 0.
@Scale
The scale factor for the trill marking. This is a value from 5% to 400%, and the default setting is 100%.
@AccStyle
The displayed style of the accidental symbol, when present. The choices are 1 (plain) , 2 (superscripted),
3 (above the 'tr') and 4 (surrounded by parentheses). The default setting is 1.
@Accidental
This specifies the accidental to be applied to the auxiliary note. Possible values are None, Sharp, Natural, Flat, Double Flat or Double Sharp. The default setting is None.
@LineType
This specifies the style of the extender line to be drawn. The choices are Wavy and Jagged, and the default setting is Wavy.
@WhichFirst
This determines whether the principal note or the auxiliary note should be played first in the trill. The default setting is Principal.
@AuxNoteInt
This determines the number of chromatic steps between the principal and auxiliary notes of the trill. Allowable values are Auto,
which uses the pitch of the next higher note on the staff, or an explicit value between -5 and 5 (excluding 0).
The default setting is Auto.
@Play
This enables playback of the trill. The default setting is on (checked).
@StartOffset
This will adjust the horizontal position of the trill's start point. The range of values 
is -10.00 to 10.00. The default setting is 0.
@EndOffset
This will adjust the horizontal position of the trill's end point. The range of values 
is -10.00 to 10.00. The default setting is 0.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local nextBar = nwc.drawpos.new()
local play1, play2 = nwc.ntnidx.new(), nwc.ntnidx.new()

local tr = '`_'
local sp = '_'
local lineTypeList= { 'Wavy', 'Jagged' }
local squigList = { Wavy = { '~', 1, 0 }, Jagged = { '-', .65, -1 } }
local playNoteList = { 'Sixteenth', 'Thirtysecond', 'Sixtyfourth' }
local accList = { 'None', 'Sharp', 'Natural', 'Flat', 'Double Flat', 'Double Sharp' }
local accCharList = { None='', Sharp='d', Natural='e', Flat='f', ['Double Flat']='h', ['Double Sharp']='g' }
local accNwctxtList = { None='', Sharp='#', Natural='n', Flat='b', ['Double Flat']='v', ['Double Sharp']='x'}
local playWhichFirstList = { 'Principal', 'Auxiliary' }
local auxNotePitchList = { 5, 4, 3, 2, 1, 'Auto', -1, -2, -3, -4, -5 }

local spec_Trill = {
	{ id='Span', label='Note Span', type='int', default=0, min=0 },
    { id='Scale', label='Scale (%)', type='int', min=5, max=400, step=5, default=100 },
	{ id='AccStyle', label='Accidental Style', type='int', default=1, min=1, max=4},
	{ id='Accidental', label='Accidental', type='enum', default=accList[1], list=accList },
	{ id='LineType', label='Line Type', type='enum', default=lineTypeList[1], list=lineTypeList },
	{ id='PlayNote', label='Playback Note Type', type='enum', default=playNoteList[2], list=playNoteList },
	{ id='WhichFirst', label='Play Which First', type='enum', default=playWhichFirstList[1], list=playWhichFirstList },
	{ id='AuxNoteInt', label='Auxiliary Note Interval', type='enum', default='Auto', list=auxNotePitchList },
	{ id='Play', label='Playback Enabled', type='bool', default=true },
	{ id='StartOffset', label='Start Offset', type='float', step=0.1, min=-10, max=10, default=0 },
	{ id='EndOffset', label='End Offset', type='float', step=0.1, min=-10, max=10, default=0 },
}

local function draw_Trill(t)
	local span = t.Span
	local scale = t.Scale / 100

	startNote:find('next', 'note')
	if not startNote then return end
	local x1 = startNote:xyTimeslot() + t.StartOffset
	
	for i = 1, span do
		endNote:find('next', 'noteOrRest')
	end
	endNote:find('next', 'objType', 'Bar', 'Rest', 'Note', 'RestChord', 'Chord')

	local x2 = endNote:xyAnchor() + t.EndOffset

	nwcdraw.alignText('middle', 'left')

	local len = x2-x1
	local acc = accCharList[t.Accidental]
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale)

	local trLen = nwcdraw.calcTextSize(tr)
	local spLen = nwcdraw.calcTextSize(sp)
	nwcdraw.moveTo(x1, 0)
	nwcdraw.text(tr)
	len = len - trLen
	local accLen = 0
	if acc ~= '' then
		local yo, sf = 0.8, 0.7
		if t.AccStyle == 2 then yo, sf = 1.5, 0.6 end
		if t.AccStyle == 3 then yo, sf = 4, 0.6 end
		if t.AccStyle == 4 then acc = '(_' .. acc .. '_)' end
		nwcdraw.setFontSize(nwcdraw.getFontSize()*sf)
		local ax = t.AccStyle == 3 and x1+(trLen-spLen-nwcdraw.calcTextSize(acc))*0.5 or x1+trLen
		accLen = t.AccStyle == 3 and 0 or nwcdraw.calcTextSize(acc)
		nwcdraw.moveTo(ax, scale*(yo-sf))
		nwcdraw.text(acc)
		len = len - accLen
	end

	nwcdraw.moveTo(x1+trLen+accLen, scale*squigList[t.LineType][3])
	nwcdraw.setFontClass('StaffSymbols')
	local squig, squigScale = squigList[t.LineType][1], squigList[t.LineType][2]
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale*squigScale)
	local squigLen = nwcdraw.calcTextSize(squig)

	len = len - spLen

	if span > 0 then
		local count = math.floor(len/squigLen)
		nwcdraw.text(string.rep(squig, count))
	end
end

local function play_Trill(t)
	if not t.Play then return end
	local notes = {}
	local dur = nwcplay.calcDurLength(t.PlayNote)
	play1:reset()
	play2:reset()
	local sp = play1:staffPos()
	local auxNoteInt = tonumber(t.AuxNoteInt) or 0

	play1:find('next', 'note')
	play2:find('next', 'note')

	local found
	for i = 1, math.max(1, t.Span) do
		found = play2:find('next', 'noteOrRest')
	end
	
	if not found then play2:find('last') end
	local pitchPos1 = play1:notePitchPos(1)
	local auxNotePos = string.format('%s%s', accNwctxtList[t.Accidental], sp+play1:notePos(1)+1)

	notes[1] = nwcplay.getNoteNumber(pitchPos1)
	notes[2] = auxNoteInt == 0 and nwcplay.getNoteNumber(auxNotePos) or notes[1] + auxNoteInt

	local j = t.WhichFirst == playWhichFirstList[1] and 1 or 2

	for spp = play1:sppOffset(), play2:sppOffset()-1, dur do
		nwcplay.note(spp, dur, notes[j])
		j = 3 - j
	end
end

local function spin_Trill(t, d)
	t.AccStyle = t.AccStyle + d
	t.AccStyle = t.AccStyle
end

return {
	spec = spec_Trill,
	spin = spin_Trill,
	draw = draw_Trill,
	play = play_Trill,
}
