-- Version 0.1

--[[--------------------------------------------------------------------------
This plugin is used to create 6-string guitar tablature on a custom (6 line) staff.
It can be used in conjunction with the TabClef.ms object to create the tablature 'clef'
(the letters TAB printed vertically)

To place the tablature, create notes or chords for each
string position, of the desired duration, positioning them only on the lines. 
(They will play the wrong notes during entry.) Then 
insert an instance of the plugin to the left of each note/chord, and set the Fret property to the fret 
numbers for each active string, separated by spaces. Then
select all of the notes and make the following changes:
 - Stem length set to 0 and muted (Edit > Properties)
 - Noteheads set to Blank Space (Notes > Noteheads > Blank Space)
@Fret
The list of fret positions for each string having a note present. Each position is a number with a minimum 
value of 0, which represents an open string. The default is '0'.
@Strum
For playback, the direction in which the chord is strummed: down (low- to high-pitched strings) 
or up (high- to low-pitched strings). The default is down.
@Play
Determines whether playback is enabled. The default setting is true (checked). 
--]]--------------------------------------------------------------------------

local userObjTypeName = ...
local user = nwcdraw.user
local strumStyles = { 'up', 'down' }
local stringNotes = {40, 45, 50, 55, 59, 64} -- 6 string guitar, E tuning

local spec_Tab = {
	{ id='Fret', label='Fret', type='text', default='0' },
	{ id='Strum', label='Strum Direction', type='enum', default='down', list=strumStyles },
	{ id='Play', label='Play Notes', type='bool', default=true },
}

local function draw_Tab(t)
	if not user:find('next', 'note') then return end
	nwcdraw.alignText('middle','center')
	nwcdraw.setFontClass('PageSmallText')
	local nc = user:noteCount()
	local x, y = user:durationBase(1) == 'Whole' and 0.65 or 0.5
	local i = 1
	for f in t.Fret:gmatch('%S+') do
		if i > nc then break end
		y = user:notePos(i)
		nwcdraw.moveTo(x, y)
		nwcdraw.setWhiteout(true)
		nwcdraw.beginPath()
		nwcdraw.ellipse(.4)
		nwcdraw.closeFigure()
		nwcdraw.endPath('fill')
		nwcdraw.setWhiteout(false)
		nwcdraw.moveTo(x, y)
		nwcdraw.text(f)
		i = i+1
	end
end

local _play = nwc.ntnidx.new()
local function play_Tab(t)
	if not t.Play then return end
	local fret, strum = t.Fret, t.Strum
	local k = {}
	_play:find('next', 'note')
	local nc = _play:noteCount()
	local i = 1
	for f in t.Fret:gmatch('%S+') do
		if i > nc then break end
		local sp = (_play:notePitchPos(i):match('([%-%d]+)')+8)/2
		local fp = tonumber(f) or 0
		local n = stringNotes[sp] 
		if n then k[#k+1] = n+fp end
		i = i+1
	end
	_play:find('next')
	local duration = _play:sppOffset()-1
	_play:find('prior')
	if duration < 1 then return end
	local noteCount = #k
	if k then
		local arpeggioShift = math.min(duration, nwcplay.PPQ)/12
		local thisShift = 0
		for i, v in ipairs(k) do
			local thisShift = arpeggioShift * ((strum == 'down') and i or noteCount-i)
			nwcplay.note(thisShift, duration-thisShift, v)
		end
	end
end

return {
	spec = spec_Tab,
	draw = draw_Tab,
	play = play_Tab
}
