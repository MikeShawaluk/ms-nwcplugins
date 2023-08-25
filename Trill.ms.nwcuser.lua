-- Version 2.3

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
@Rate
This specifies the rate at which the trill is played, as a number of notes per whole note duration. The range of
values is 16 (slow) to 128 (very fast), with a default setting of 32 (32nd notes).
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

if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()

	local once = 'Add'
	local noteobjTypes = { Note = true, Chord = true, RestChord = true }

	local function applyTrill(o)
		if not once or o:IsFake() then return end

		if o.UserType == userObjTypeName then
			once = 'Del'
			return 'delete'
		elseif noteobjTypes[o.ObjType] then
			local opts = o:Provide('Opts')
			if once == 'Add' then
				local o2 = nwcItem.new('|User|'..userObjTypeName)
				o2.Opts.Pos = 9
				opts.Muted = ''
				once = false
				return { o2, o }
			else
				opts.Muted = nil
				once = false
			end
		end
	end

	score:forSelection(applyTrill)
	if not once then
		score:save()
	else
		nwcut.msgbox(('No note or chord found for %s'):format(userObjTypeName))
	end
	return
end

local _nwcut = { ['Toggle'] = 'ClipText' }

local userObjTypeName = ...
local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()
local nextBar = nwc.drawpos.new()
local play1, play2 = nwc.ntnidx.new(), nwc.ntnidx.new()
local idx = nwc.ntnidx

local tr, lp, rp, sp = '`_', '(_', ')_', '_'
local lineTypeList= { 'Wavy', 'Jagged' }
local squigList = { Wavy = { '~', 1, 0 }, Jagged = { '-', .65, -1 } }
local playNoteRate = { Sixteenth=16, Thirtysecond=32, Sixtyfourth=64 }
local accList = { 'None', 'Sharp', 'Natural', 'Flat', 'Double Flat', 'Double Sharp' }
local accCharList = { None='', Sharp='d', Natural='e', Flat='f', ['Double Flat']='h', ['Double Sharp']='g' }
local accNwctxtList = { None='', Sharp='#', Natural='n', Flat='b', ['Double Flat']='v', ['Double Sharp']='x'}
local playWhichFirstList = { 'Principal', 'Auxiliary' }
local auxNotePitchList = { 5, 4, 3, 2, 1, 'Auto', -1, -2, -3, -4, -5 }
local accStyleList = {
	{ 0.8, 0.7 },
	{ 1.5, 0.6 },
	{ 4, 0.6 },
	{ 0.8, 0.7 },
}

local _spec = {
	{ id='Span', label='Note Span', type='int', default=0, min=0 },
	{ id='Scale', label='Scale (%)', type='int', min=5, max=400, step=5, default=100 },
	{ id='AccStyle', label='Accidental Style', type='int', default=1, min=1, max=#accStyleList },
	{ id='Accidental', label='Accidental', type='enum', default=accList[1], list=accList },
	{ id='LineType', label='Line Type', type='enum', default=lineTypeList[1], list=lineTypeList },
	{ id='Rate', label='Playback Rate', type='int', default=32, min=8, max=128 },
	{ id='WhichFirst', label='Play Which First', type='enum', default=playWhichFirstList[1], list=playWhichFirstList },
	{ id='AuxNoteInt', label='Auxiliary Note Interval', type='enum', default='Auto', list=auxNotePitchList },
	{ id='Play', label='Playback Enabled', type='bool', default=true },
	{ id='StartOffset', label='Start Offset', type='float', step=0.1, min=-10, max=10, default=0 },
	{ id='EndOffset', label='End Offset', type='float', step=0.1, min=-10, max=10, default=0 },
}

local stopItems = { Note=1, Chord=1, RestChord=1, Rest=-1, Bar=-1, RestMultiBar=-1, Boundary=-1 }

local function hasTargetNote(idx)
	while idx:find('next') do
		local d = stopItems[idx:objType()]
		if d then return d > 0 end
		if (idx:userType() == userObjTypeName) then return false end
	end
	return false
end

local function _span(t)
	return t.Span
end

local function _audit(t)
	local barSpan = (idx:find('span', _span(t)) or idx:find('last')) and idx:find('prior','bar') and (idx:indexOffset() > 0)
	t.Class = barSpan and 'Span' or 'Standard'
	if t.PlayNote then
		t.Rate = playNoteRate[t.PlayNote] or 32
		t.PlayNote = nil
	end
end

local function _draw(t)
	local atSpanFront = not user:isAutoInsert()
	local span = _span(t)
	local scale = t.Scale / 100
	local accStyle = t.AccStyle
	local accStyleVars = accStyleList[accStyle]
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale)
	local trLen = nwcdraw.calcTextSize(tr)

	if not hasTargetNote(idx) then
		if not nwcdraw.isDrawing() then return trLen end
		nwcdraw.alignText('middle', 'right')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*scale)
		nwcdraw.text(tr)
		return
	end
	if not nwcdraw.isDrawing() then return 0 end

	nwcdraw.alignText('middle', 'left')
	startNote:find('next', 'note')
	local x1 = startNote:xyTimeslot() + t.StartOffset

	local atSpanEnd = endNote:find('span', _span(t))

	if not atSpanEnd then
		endNote:find('last')
	else
		endNote:find('next', 'noteRestBar')
	end

	local x2 = endNote:xyAnchor() + t.EndOffset
	local acc = accCharList[t.Accidental]

	local spLen = nwcdraw.calcTextSize(sp)
	local lpLen = nwcdraw.calcTextSize(lp)
	local rpLen = nwcdraw.calcTextSize(rp)

	nwcdraw.moveTo(x1, 0)
	local accLen = 0
	nwcdraw.text(tr)

	if atSpanFront then
		if acc ~= '' then
			local yo, sf = accStyleVars[1], accStyleVars[2]
			if accStyle == 4 then acc = lp .. acc .. sp .. rp end
			nwcdraw.setFontSize(nwcdraw.getFontSize()*sf)
			local ax = accStyle == 3 and x1+(trLen-spLen-nwcdraw.calcTextSize(acc))*0.5 or x1+trLen
			accLen = accStyle == 3 and 0 or nwcdraw.calcTextSize(acc)
			nwcdraw.moveTo(ax, scale*(yo-sf))
			nwcdraw.text(acc)
		end
	else
		local yo = 1
		nwcdraw.moveTo(x1-lpLen, yo)
		nwcdraw.text(lp)
		nwcdraw.moveTo(x1+trLen, yo)
		nwcdraw.text(rp)
		accLen = rpLen
	end

	if span > 0 then
		local x, y = x1+trLen+accLen, scale*squigList[t.LineType][3]
		nwcdraw.setFontClass('StaffSymbols')
		local squig, squigScale = squigList[t.LineType][1], squigList[t.LineType][2]
		nwcdraw.setFontSize(nwcdraw.getFontSize()*scale*squigScale)
		local w = nwcdraw.calcTextSize(squig)
		nwcdraw.moveTo(x, y)
		repeat
			nwcdraw.text(squig)
			x = nwcdraw.xyPos()
		until x >= x2 - w
	end
end

local function _play(t)
	if not t.Play then return end
	if not hasTargetNote(idx) then return end
	local maxOffset = nwcplay.MAXSPPOFFSET or (32*nwcplay.PPQ)
	local notes = {}
	local dur = (4*nwcplay.PPQ/t.Rate)
	play1:reset()
	play2:reset()
	local sp = play1:staffPos()
	local auxNoteInt = tonumber(t.AuxNoteInt) or 0

	if not play1:find('next', 'note') then return end
	play2:find('next', 'note')

	local found
	for i = 1, math.max(1, t.Span) do
		found = play2:find('next', 'noteOrRest')
	end

	if not found then play2:find('last') end
	local topNote = play1:noteCount()
	local pitchPos1 = play1:notePitchPos(topNote)
	local auxNotePos = string.format('%s%s', accNwctxtList[t.Accidental], sp+play1:notePos(topNote)+1)

	notes[1] = nwcplay.getNoteNumber(pitchPos1)
	notes[2] = auxNoteInt == 0 and nwcplay.getNoteNumber(auxNotePos) or notes[1] + auxNoteInt

	local j = t.WhichFirst == playWhichFirstList[1] and 1 or 2
	local startPos = math.min(play1:sppOffset(), maxOffset)
	local endPos = math.min(play2:sppOffset()-1, maxOffset-dur)
	for spp = startPos ,endPos, dur do
		nwcplay.note(spp, dur, notes[j])
		j = 3 - j
	end
end

local function _spin(t, d)
	t.Span = t.Span + d
	t.Span = t.Span
end

local function _create(t)
	if idx:find('prior', 'user', userObjTypeName) then
		local params = { 'Pos' }
		for k, s in ipairs(_spec) do
			params[#params+1] = s.id
		end
		for k, s in ipairs(params) do
			t[s] = idx:userProp(s)
		end
	end
end

return {
	nwcut = _nwcut,
	span = _span,
	audit = _audit,
	spec = _spec,
	spin = _spin,
	draw = _draw,
	width = _draw,
	play = _play,
	create = _create,
}
