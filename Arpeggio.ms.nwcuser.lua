-- Version 2.2

--[[----------------------------------------------------------------
This plugin draws an arpeggio marking next to a chord, and can optionally play the notes in 
several performance styles when the song is played. Parameters are available for adjusting the 
arpeggio's appearance and playback.

To add an arpeggio, insert the object immediately before the chord which you wish to ornament. 
The arpeggio will automatically cover the range of notes in the chord, and will update automatically 
if the chord is moved or modified.
@Side
The side of the chord on which the arpeggio marking will be drawn. The default setting is left. 
@Dir
The direction of the arpeggio, up or down. When set to down, an arrowhead will be added at the 
bottom of the arpeggio. This setting also affects the arpeggio's playback. The default setting 
is up. 
@Offset
This is used to increase or decrease the spacing between the arpeggio and its chord, and can be 
from -5.00 to 5.00 notehead widths. Positive values shift the position to the right, negative to the 
left. The default setting is 0. 
@Rate
The rate at which the arpeggio is played, as a number of notes per whole note duration. The range of 
values is 1.0 (very slow) to 128.0 (very fast), with a default setting of 32 (32nd notes).

Note that the arpeggio rate is proportional to the score's tempo. 
@Anticipated
This specifies that the arpeggio should anticipate (precede) the chord, so that the final 
played note occurs on the chord's beat position. When unchecked, standard playback with occur, 
in which the first played note of the arpeggiated chord is at the chord's beat position. The 
default setting is off (unchecked).

Note that if playback begins with an anticipated arpeggio, it will play in the
normal style, since attempting to begin its playback before the start of the score, or before
the user presses the Play button, could result in a causality violation.
@MarkerExtend
This setting allows the arpeggio marker's position to be used to extends it above or below the 
notes of the chord. This can be used to 'stretch' the arpeggio to extend to an adjacent staff. 
However, notes on other staves will not be included in the arpeggio's playback. The default 
setting is off (unchecked). 
@Play
Determines whether arpeggio playback is enabled. The default setting is true (checked). 

Note that the chord which follows the arpeggio marking should be muted for proper playback. When
this chord is tied to subsequent chords, those chords should *NOT* be muted. This will allow the
arpeggiated chord to play through the tie.
@ForceArrow
This forces the addition of the direction arrowhead for upward arpeggios. Normally, arrowheads 
are only used for downward arpeggios, but one can be added for an upward arpeggio if needed in 
a score. The default setting is off (unchecked). 
--]]----------------------------------------------------------------

if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()

	local once = 'Add'
	local noteobjTypes = { Chord = true, RestChord = true }
	
	local function applyArpeggio(o)
		if not once or o:IsFake() then return end

		if o.UserType == userObjTypeName then
			once = 'Del'
			return 'delete'
		elseif noteobjTypes[o.ObjType] then
			local opts = o:Provide('Opts')
			if once == 'Add' then
				local o2 = nwcItem.new('|User|'..userObjTypeName)
				o2.Opts.Pos = 0
				opts.Muted = ''
				once = false
				return { o2, o }
			else
				opts.Muted = nil
				once = false
			end
		end
	end

	score:forSelection(applyArpeggio)
	if not once then
		score:save()
	else
		nwcut.msgbox(('No chord found for %s'):format(userObjTypeName))
	end
	return
end

local _nwcut = { ['Toggle'] = 'ClipText' }

local userObjTypeName = ...
local user = nwcdraw.user
local idx = nwc.ntnidx

local stopItems = { Note=1, Chord=1, RestChord=1, Rest=-1, Bar=-1, RestMultiBar=-1, Boundary=-1 }

local function hasTargetNote(idx)
	while idx:find('next') do
		local d = stopItems[idx:objType()]
		if d then return d > 0 end
		if (idx:userType() == userObjTypeName) then return false end
	end
	return false
end

local function drawSquig(x, y)
	local xo, yo = .2, -.2
	local x1, y1 = x + .5, y - .65
	local x2, y2 = x - .5, y - 1.3
	local x3, y3 = x , y - 2
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.bezier(x1, y1, x2, y2, x3, y3)
	nwcdraw.lineBy(xo, yo)
	nwcdraw.bezier(x2 + xo, y2 + yo, x1 + xo, y1 + yo, x + xo, y + yo)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local function drawArrow(x, y, dir)
	local a, b, c = .3, .3*dir, 1.5*dir
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.lineBy(-a, -b, a, b+c, a, -b-c)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local _spec = {
	{ id='Side', label='Side of Chord', type='enum', default='left', list={'left', 'right'} },
	{ id='Dir', label='Direction', type='enum', default='up', list={'up', 'down'} },
	{ id='Offset', label='Horizontal Offset', type='float', default=0, min=-5, max=5, step=.1 },
	{ id='Rate', label='Arpeggio Rate', type='float', default=32, min=1, max=128 },
	{ id='Anticipated', label='Anticipated Playback', type='bool', default=false },
	{ id='MarkerExtend', label='Extend Arpeggio with Marker', type='bool', default=false },
	{ id='Play', label='Play Notes', type='bool', default=true },
	{ id='ForceArrow', label='Force Arrowhead for Up Arpeggio', type='bool', default=false }
}

local function _audit(t)
	if t.Speed then
		t.Rate = t.Speed*4
		t.Speed = nil
	end
end

local function _draw(t)
	if not hasTargetNote(idx) then
		local w = 1
		if not nwcdraw.isDrawing() then return w end
		for y = -1, 3, 2  do
			drawSquig(w-1.6, y)
		end
		if t.Dir == 'down' then
			drawArrow(w-1.6, -3.25, -1)
		else
			if t.ForceArrow then
				drawArrow(w-1.4, 2.95, 1)
			end
		end
		return
	end
	if not nwcdraw.isDrawing() then return 0 end
	
	user:find('next', 'note')	
	local noteCount = user:noteCount()
	if noteCount == 0 then return end
	local _, my = nwcdraw.getMicrons()
	local penWidth = my*0.12
	local offset = t.Offset
	local leftOnSide = t.Side == 'left'
	local markerExtend = t.MarkerExtend	
	local ybottom, ytop = user:notePos(1)+.5, user:notePos(noteCount)-.5
	if markerExtend then
		ytop = math.max(ytop, 0)
		ybottom = math.min(ybottom, 0)
	end
	nwcdraw.setPen('solid', penWidth)
	local count = math.floor((ytop - ybottom) / 2) + 2
	local x = leftOnSide and user:xyAnchor() + offset - .75 or user:xyRight() + offset + .55
	local y = ytop + 2
	for i = 1, count do
		drawSquig(x, y)
		y = y - 2
	end
	if t.Dir == 'down' then
		drawArrow(x, ytop-count*2+1.85, -1)
	else
		if t.ForceArrow then
			drawArrow(x+.2, ytop+1.85, 1)
		end
	end
end

local play, begin = nwc.ntnidx.new(), nwc.ntnidx.new()
local function _play(t)
	if not t.Play then return end
	if not hasTargetNote(play) then return end
	local noteCount = play:noteCount()
	if noteCount == 0 then return end
	play:find('next')
	local duration = play:sppOffset()
	if duration < 1 then return end
    play:find('prior')
	begin:find('first')
 	local arpeggioShift = math.min(4 * nwcplay.PPQ / t.Rate, duration / noteCount)
    local startOffset = t.Anticipated and math.max(-arpeggioShift * (noteCount-1), begin:sppOffset()) or 0
	for i = 1, noteCount do
		local thisShift = arpeggioShift * ((t.Dir == 'down') and noteCount-i or i-1) + startOffset
		if not play:isTieIn(i) then
        	if play:isTieOut(i) then
            	nwcplay.midi(thisShift, 'noteOn', nwcplay.getNoteNumber(play:notePitchPos(i)), nwcplay.getNoteVelocity())
        	else
		    	nwcplay.note(thisShift, duration-thisShift, nwcplay.getNoteNumber(play:notePitchPos(i)))
        	end
		end
	end
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
	spec = _spec,
	width = _draw,
	draw = _draw,
	play = _play,
	audit = _audit,
	create = _create,
}
