-- Version 2.0a

--[[----------------------------------------------------------------
This plugin draw a guitar chord chart and optionally strums the chord when the song is played. 
A variety of notation is shown, including the chord name, open and excluded strings, barre 
positions, fret position and optional finger numbers.

When adding a new chord, the user can choose from 35 predefined chords, or can choose "(Custom)"
to create a chord chart from scratch. The chord chart can be positioned vertical by changing the object marker position.

When a chord is added to a staff, if there is another GuitarChord object earlier in the staff,
it will inherit the style and properties of that object.
@Name
The name of the chord. It is displayed using a font which displays 'b' and '#' as flat and sharp symbols.
@Style
This determines the font style to be used for the chord name and label text. The possible values
are Serif (MusikChordSerif, Times New Roman), Sans (MusikChordSans, Arial) and Swing (SwingChord, SwingText).
The default setting is Serif.
@Finger
The fingerings for each string, entered from low to high string, separate by spaces. Each 
position can be a number, indicating the fret position, or a 'o' or 'x' for open or unplayed 
strings, respectively. A fret position can be appended with ':' and a number, to indicate the 
finger number to be used for that string; the number will be placed inside the fingering dot.

When finger numbers are being used, the chart size will generally need to be 2 or larger for the
numbers to be readable.
@Barre
Optional sets of strings to be held down by a particular finger, displayed by an arc over the 
fingering dots. Each barre to be drawn is indicated by the starting and ending string numbers, 
separated by ':'. For example, 2:5 would add a bar between the second and fifth strings.

Note that the fingering positions for a barre need to be on the same fret for it to appear 
correctly.
@Size
The size of the chord chart, ranging from 1.0 to 5.0. The default is 1.
@Frets
The number of fret positions to show in the chart, ranging from 1 to 10. The default is 4.
@Capo
For playback, indicates that the pitch for each string should be transposed upward the 
specified number of steps. The default is 0.
@TopFret
The top fret number displayed in the chart. When the value is 1, the top border of the chart 
will be thicker. For larger values, '# fr.' will be displayed to the right of the chart. The 
default is 1.
@Span
For playback, the number of notes/rests that the chord should span. A value of 0 will disable 
playback. The default is 0.
@FretTextPosition
Specifies whether the fret text is displayed next to the top or bottom row of fingering dots, 
when Top Fret is greater than 1. The default is top.
@Strum
For playback, the direction in which the chord is strummed: down (low- to high-pitched strings) 
or up (high- to low-pitched strings). The default is down.
@TopBarreOffset
When a barre is present on the top fret and there are open (o) or excluded (x) strings within 
the barre, this setting can be used to move the barre upward a specified distance, to avoid 
collision with those labels. This will also move the Chord Name upward. The default value is 0.0.
@Anticipated
This specifies that the strum should anticipate (precede) the chord, so that the final 
played note occurs on the chord's beat position. When unchecked, the first played note of the 
strummed chord is at the chord's beat position. The default setting is on (checked).
--]]----------------------------------------------------------------

local commonChords = {
	['(Custom)'] = { '', '', 1 },
	
	['A'] = { 'x o 2 2 2 o', '', 1 },
	['Am'] = { 'x o 2 2 1 o', '', 1 },
	['A6'] = { 'x o 2 2 2 2', '', 1 },
	['A7'] = { 'x o 2 2 2 3', '', 1 },
	['A9'] = { 'x o 2 4 2 3', '', 1 },
	['Am6'] = { 'x o 2 2 1 2', '', 1 },
	['Am7'] = { 'x o 2 2 1 3', '', 1 },
	['Amaj7'] = { 'x o 2 1 2 o', '', 1 },
	['Adim'] = { 'x x 1 2 1 2', '', 1 },
	['A+'] = { 'x o 3 2 2 1', '', 1 },
	['Asus'] = { 'x o 2 2 3 o', '', 1 },
	
	['A#'] = { 'x 1 3 3 3 1', '', 1 },
	['A#m'] = { 'x 1 3 3 2 1', '', 1 },
	['A#6'] = { '1 1 3 3 3 3', '', 1 },
	['A#7'] = { 'x x 3 3 3 4', '', 3 },
	['A#9'] = { '3 3 5 3 3 3', '', 3 },
	['A#m6'] = { 'x x 3 3 2 3', '', 1 },
	['A#m7'] = { 'x x 3 3 2 4', '', 1 },
	['A#maj7'] = { 'x 1 3 2 3 x', '', 1 },
	['A#dim'] = { 'x x 2 3 2 3', '', 1 },
	['A#+'] = { 'x x o 3 3 2', '', 1 },
	['A#sus'] = { 'x x 3 3 4 1', '', 1 },
	
	['B'] = { 'x 2 4 4 4 2', '', 1 },
	['Bm'] = { 'x 2 4 4 3 2', '', 1 },
	['B6'] = { '2 2 4 4 4 4', '', 1 },
	['B7'] = { 'x 2 1 2 o 2', '', 1 },
	['B9'] = { 'x 2 1 2 2 2', '', 1 },
	['Bm6'] = { 'x x 4 4 3 4', '', 1 },
	['Bm7'] = { 'x 2 4 2 3 2', '', 2 },
	['Bmaj7'] = { 'x 2 4 3 4 x', '', 1 },
	['Bdim'] = { 'x x o 1 o 1', '', 1 },
	['B+'] = { 'x x 5 4 4 3', '', 3 },
	['Bsus'] = { 'x x 4 4 5 2', '', 2 },
	
	['C'] = { '3 3 2 o 1 o', '', 1 },
	['Cm'] = { 'x 3 5 5 4 3', '', 3 },
	['C6'] = { 'x x 2 2 1 3', '', 1 },
	['C7'] = { 'x 3 2 3 1 o', '', 1 },
	['C9'] = { 'x 3 2 3 3 3', '', 1 },
	['Cm6'] = { 'x x 1 2 1 3', '', 1 },
	['Cm7'] = { 'x x 1 3 1 3', '', 1 },
	['Cmaj7'] = { 'x 3 2 o o o', '', 1 },
	['Cdim'] = { 'x x 1 2 1 2', '', 1 },
	['C+'] = { 'x x 2 1 1 o', '', 1 },
	['Csus'] = { 'x x 3 o 1 3', '', 1 },
	
	['C#'] = { 'x x 3 1 2 1', '', 1 },
	['C#m'] = { 'x x 2 1 2 o', '', 1 },
	['C#6'] = { 'x x 3 3 2 4', '', 1 },
	['C#7'] = { 'x x 3 4 2 4', '', 1 },
	['C#9'] = { 'x 4 3 4 4 4', '', 1 },
	['C#m6'] = { 'x x 2 3 2 4', '', 1 },
	['C#m7'] = { 'x x 2 4 2 4', '', 1 },
	['C#maj7'] = { 'x 4 3 1 1 1', '', 1 },
	['C#dim'] = { 'x x 2 3 2 3', '', 1 },
	['C#+'] = { 'x x 3 2 2 1', '', 1 },
	['C#sus'] = { 'x x 3 3 4 1', '', 1 },
	
	['D'] = { 'x x o 2 3 2', '', 1 },
	['Dm'] = { 'x x o 2 3 1', '', 1 },
	['D6'] = { 'x o o 2 o 2', '', 1 },
	['D7'] = { 'x x o 2 1 2', '', 1 },
	['D9'] = { '2 o o 2 1 o', '', 1 },
	['Dm6'] = { 'x x o 2 o 1', '', 1 },
	['Dm7'] = { 'x x o 2 1 1', '', 1 },
	['Dmaj7'] = { 'x x o 2 2 2', '', 1 },
	['Ddim'] = { 'x x o 1 o 1', '', 1 },
	['D+'] = { 'x x o 3 3 2', '', 1 },
	['Dsus'] = { 'x x o 2 3 3', '', 1 },
	
	['D#'] = { 'x x 5 3 4 3', '', 3 },
	['D#m'] = { 'x x 4 3 4 2', '', 1 },
	['D#6'] = { 'x x 1 3 1 3', '', 1 },
	['D#7'] = { 'x x 1 3 2 3', '', 1 },
	['D#9'] = { '1 1 1 3 2 1', '', 1 },
	['D#m6'] = { 'x x 1 3 1 2', '', 1 },
	['D#m7'] = { 'x x 1 3 2 2', '', 1 },
	['D#maj7'] = { 'x x 1 3 3 3', '', 1 },
	['D#dim'] = { 'x x 1 2 1 2', '', 1 },
	['D#+'] = { 'x x 1 o o 3', '', 1 },
	['D#sus'] = { 'x x 1 3 4 4', '', 1 },

	['E'] = { 'o 2 2 1 o o', '', 1 },
	['Em'] = { 'o 2 2 o o o', '', 1 },
	['E6'] = { 'o 2 2 1 2 o', '', 1 },
	['E7'] = { 'o 2 2 1 3 o', '', 1 },
	['E9'] = { 'o 2 o 1 o 2', '', 1 },
	['Em6'] = { 'o 2 2 o 2 o', '', 1 },
	['Em7'] = { 'o 2 o o o o', '', 1 },
	['Emaj7'] = { 'o 2 1 1 o o', '', 1 },
	['Edim'] = { 'x x 2 3 2 3', '', 1 },
	['E+'] = { 'x x 2 1 1 o', '', 1 },
	['Esus'] = { 'o 2 2 2 o o', '', 1 },
	
	['F'] = { '1 3 3 2 1 1', '', 1 },
	['Fm'] = { '1 3 3 1 1 1', '', 1 },
	['F6'] = { 'x x o 2 1 1', '', 1 },
	['F7'] = { '1 3 1 2 1 1', '', 1 },
	['F9'] = { 'x x 3 2 4 3', '', 1 },
	['Fm6'] = { 'x x o 1 1 1', '', 1 },
	['Fm7'] = { '1 3 1 1 1 1', '', 1 },
	['Fmaj7'] = { 'x x 3 2 1 o', '', 1 },
	['Fdim'] = { 'x x o 1 o 1', '', 1 },
	['F+'] = { 'x x 3 2 2 1', '', 1 },
	['Fsus'] = { 'x x 3 3 1 1', '', 1 },
	
	['F#'] = { '2 4 4 3 2 2', '', 1 },
	['F#m'] = { '2 4 4 2 2 2', '', 1 },
	['F#6'] = { 'x 4 4 3 4 x', '', 1 },
	['F#7'] = { 'x x 4 3 2 o', '', 1 },
	['F#9'] = { 'x x 4 3 5 4', '', 3 },
	['F#m6'] = { 'x x 1 2 2 2', '', 1 },
	['F#m7'] = { 'x x 2 2 2 2', '', 1 },
	['F#maj7'] = { 'x x 4 3 2 1', '', 1 },
	['F#dim'] = { 'x x 1 2 1 2', '', 1 },
	['F#+'] = { 'x x 4 3 3 2', '', 1 },
	['F#sus'] = { 'x x 4 4 2 2', '', 1 },
	
	['G'] = { '3 2 o o o 3', '', 1 },
	['Gm'] = { '3 5 5 3 3 3', '', 3},
	['G6'] = { '3 2 o o o o', '', 1 },
	['G7'] = { '3 2 o o o 1', '', 1 },
	['G9'] = { '3 o o 2 o 1', '', 1 },
	['Gm6'] = { 'x x 2 3 3 3', '', 1 },
	['Gm7'] = { '3 5 3 3 3 3', '', 3 },
	['Gmaj7'] = { 'x x 5 4 3 2', '', 2 },
	['Gdim'] = { 'x x 2 3 2 3', '', 1 },
	['G+'] = { 'x x 1 o o 3', '', 1 },
	['Gsus'] = { 'x x o o 1 3', '', 1 },
	
	['G#'] = { '4 6 6 5 4 4', '', 4 },
	['G#m'] = { '4 6 6 4 4 4', '', 4 },
	['G#6'] = { '4 3 1 1 1 1', '', 1 },
	['G#7'] = { 'x x 1 1 1 2', '', 1 },
	['G#9'] = { 'x x 1 3 1 2', '', 1 },
	['G#m6'] = { 'x x x 4 4 4', '', 1 },
	['G#m7'] = { 'x x 1 1 o 2', '', 1 },
	['G#maj7'] = { 'x x 1 1 1 3', '', 1 },
	['G#dim'] = { 'x x o 1 o 1', '', 1 },
	['G#+'] = { 'x x 2 1 1 o', '', 1 },
	['G#sus'] = { 'x x 1 1 2 4', '', 1 },
}
	local allTonics = { 'Ab', 'A', 'A#', 'Bb', 'B', 'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G' }
	local allChords = { '', 'm', '6', '7', '9', 'm6', 'm7', 'maj7', 'dim', '+', 'sus' }
	local fsMap = {
		['Ab'] = 'G#', 
		['Bb'] = 'A#', 
		['Db'] = 'C#', 
		['Eb'] = 'D#', 
		['Gb'] = 'F#',
		['F#'] = 'Gb',
		['D#'] = 'Eb', 
		['C#'] = 'Db',
		['A#'] = 'Bb',
		['G#'] = 'Ab',
	}
--if nwcut then
--	local userObjTypeName = arg[1]
--	local score = nwcut.loadFile()
--	local staff, i1, i2 = score:getSelection()
--	local chord, chordName, o
	
--	for k1, v1 in ipairs({ 'Ab', 'A', 'Bb', 'B', 'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G' }) do
--		for k2, v2 in ipairs(allChords) do
--			chordName = v1 .. v2
--			chord = commonChords[chordName] and chordName or string.gsub(chordName, v1, fsMap[v1] or v1)
--			if commonChords[chord] then
--				o = nwcItem.new('User|' .. userObjTypeName)
--				o.Opts.Name = chordName
--				o.Opts.Finger = commonChords[chord][1]
--				o.Opts.Barre = commonChords[chord][2]
--				o.Opts.TopFret = commonChords[chord][3]
--				o.Opts.Span = 1
--				o.Opts.Pos = 5
--				o.Opts.Size = 3
--				o.Opts.Anticipated = false
--				staff:add(o)
--				staff:add(nwcItem.new('|Rest|Dur:Half|Visibility:Never'))
--				staff:add(nwcItem.new(v2 == 'sus' and '|Bar|SysBreak:Y' or '|Bar'))
--			end
--		end
--	end
	
--	score:setSelection(staff)
--	score:save()
--	return		
--end

local userObjTypeName = ...
local idx = nwc.ntnidx
local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()
local strumStyles = { 'up', 'down' }
local fretTextPos = { 'top', 'bottom' }
local styleListFull = {
    Serif = { 'MusikChordSerif', 1, 'Times New Roman', 1 },
    Sans = { 'MusikChordSans', 1, 'Arial', 1 },
    Swing = { 'SwingChord', 1.25, 'SwingText', 1.25 }
}
local styleList = { 'Serif', 'Sans', 'Swing' }

local stringNames = { '1 (E)', '2 (A)', '3 (D)', '4 (G)', '5 (B)', '6 (e)' }

local strings = #stringNames

local _spec = {
	{ id='Name', label='Chord Name', type='text', default='' },
    { id='Style', label='Font Style', type='enum', default=styleList[1], list=styleList },
	{ id='Finger', label='Fingerings', type='text', default='' },
	{ id='Barre', label='Barres', type='text', default='' },
	{ id='Size', label='Chart Size', type='float', default=1, min=0.5, max=5, step=.5 },
	{ id='Frets', label='Frets to Show', type='int', default=4, min=3, max=10 },
	{ id='Capo', label='Capo Position', type='int', default=0, min=0 },
	{ id='TopFret', label='Top Fret', type='int', default=1, min=1 },
	{ id='Span', label='Note Span', type='int', default=0, min=0 },
	{ id='FretTextPosition', label='Fret Text Location', type='enum', default='top', list=fretTextPos },
	{ id='Strum', label='Strum Direction', type='enum', default='down', list=strumStyles },
	{ id='TopBarreOffset', label='Top Barre Offset', type='float', default=0, min=0, step=.25 },
	{ id='Anticipated', label='Anticipated Playback', type='bool', default=true },
}

local spinnable = { int=true, float=true }
local boolOrEnum = { bool='command', enum='choice' }

local _menu = {
	{ type='command', name='Choose Spin Target:', disable=true },
}
local sep = true
for k, s in ipairs(stringNames) do
	_menu[#_menu+1] = {	type='command', name=s, disable=false, separator=sep, data=-k }
	sep = false
end
for k, s in ipairs(_spec) do
	if spinnable[s.type] and s.id ~= 'Capo' then
		_menu[#_menu+1] = {	type='command', name=s.label, disable=false, data=k }
	end
end
local sep = true
for k, s in ipairs(_spec) do
	local t = boolOrEnum[s.type]
	if t then
		local a = {	type=t, list=s.list, name=s.label, disable=false, separator=sep, data=k }
		sep = false
		_menu[#_menu+1] = a
	end
end

local function parseStrings(str)
	local tbl = {}
	for s in str:gmatch('%S+') do 
		tbl[#tbl+1] = s
	end
	while #tbl < 6 do
		tbl[#tbl+1] = ''
	end
	return tbl
end

local function _menuInit(t)
	local f = parseStrings(t.Finger)
	local ap = tonumber(t.ap)
	for k, m in ipairs(_menu) do
		local w = m.data or 0
		if w < 0 then
			m.name = string.format('%s\t%s', stringNames[-w], f[-w] or '')
			m.checkmark = (k == ap)
		else
			local s = _spec[w]
			if s then
				local v = t[s.id]
				if s.type == 'bool' then
					m.checkmark = v
				elseif s.type == 'enum' then
					m.default = v
				else
					m.name = string.format('%s\t%s', s.label, v)
					m.checkmark = (k == ap)
				end
			end
		end
	end
end

local function _menuClick(t, menu, choice)
	local m = _menu[menu]
	local w = m.data or 0
	if w > 0 then
		local s = _spec[w]
		local v = t[s.id]
		if s.type == 'bool' then
			t[s.id] = not v
		elseif s.type == 'enum' then
			t[s.id] = m.list[choice]
		elseif s.type == 'text' then
			t[s.id] = nwcui.prompt(string.format('Enter %s:', string.gsub(s.label, '&', '')), '*', v)
		else
			t.ap = menu
		end
	else
		t.ap = menu
	end
end

local tonics = {}
for k, v in pairs(commonChords) do
	local t, c
	if k ~= '(Custom)' then
		t, c = k:match('([A-G][b#]?)(.*)')
		if not tonics[t] then tonics[t] = true end
	end
end
for k, v in pairs(fsMap) do
	if not tonics[k] and tonics[v] then
		tonics[k] = true
	end
end
local tonicsList = '|(Custom)'
for k, v in ipairs(allTonics) do
	if tonics[v] then
		tonicsList = tonicsList .. '|' .. v
	end
end

local function _create(t)
	local chord
	local tonic = nwcui.prompt('Select Tonic', tonicsList)
	if tonic ~= '(Custom)' then
		local chordsList = ''
		for k, v in ipairs(allChords) do
			local ch = tonic .. v
			if commonChords[ch] or commonChords[(fsMap[tonic] or '') .. v] then
				chordsList = chordsList .. '|' .. ch
			end
		end
		chord = nwcui.prompt('Select Chord', chordsList)
	else
		chord = tonic
	end
	t.Name = (chord == '(Custom)') and '' or chord
	if not commonChords[chord] then
		chord = string.gsub(chord, tonic, fsMap[tonic])
	end
	t.Finger = commonChords[chord][1]
	t.Barre = commonChords[chord][2]
	t.TopFret = commonChords[chord][3]
	if idx:find('prior', 'user', userObjTypeName) then
		t.Style = idx:userProp('Style')
		t.Size = idx:userProp('Size')
		t.Frets = idx:userProp('Frets')
		t.Capo = idx:userProp('Capo')
		t.FretTextPosition = idx:userProp('FretTextPosition')
		t.Strum = idx:userProp('Strum')
		t.Anticipated = idx:userProp('Anticipated')
		t.Span = idx:userProp('Span')
		t.Pos = idx:userProp('Pos')
	end	
end

local lu = { [-1]='x', [0]='o' }

local function _spin(t, d)
	t.ap = t.ap or 12 -- default to Span
	local y = _menu[tonumber(t.ap)].data
	if type(y) == 'table' then
		for _, y1 in ipairs(y) do
			local x = _spec[y1].id
			t[x] = t[x] + d*_spec[y1].step
			t[x] = t[x]
		end
	else
		if y > 0 then
			local x = _spec[y].id
			t[x] = t[x] + d*(_spec[y].step or 1)
			t[x] = t[x]
		else
			local f = parseStrings(t.Finger)
			local s = f[-y]
			local s1 = s:match('(%S)')
			local s2 = s:match(':(%S)')
			if s1 then
				local n = tonumber(s1) or s1=='x' and -1 or 0
				n = math.max(-1, n + d)
				f[-y] = n > 0 and tostring(n) .. (s2 and ':' .. s2 or '') or lu[n]
				t.Finger = table.concat(f, ' ')
			end
		end
	end
end

local function hasTargetDuration()
	searchObj:reset()
	while searchObj:find('next') do
		if searchObj:userType() == userObjTypeName then return false end
		if searchObj:durationBase() then return true end
	end
	return false
end

local function _width(t)
	return hasTargetDuration() and 0 or strings * t.Size / nwcdraw.getAspectRatio()
end

local function _draw(t)
	local _, my = nwcdraw.getMicrons()
	local xyar = nwcdraw.getAspectRatio()
	local size, frets, topFret, topBarreOffset, span = t.Size, t.Frets, t.TopFret, t.TopBarreOffset, t.Span
	local ap = tonumber(t.ap or 0)
	local penStyle = 'solid'
	local lineThickness = my*0.125*size
	local barreThickness = my*0.05*size
	local xspace, yspace = size / xyar, size
	local height = yspace * frets
	local height2 = (topFret == 1) and height + .5 * yspace or height
	local userwidth = user:width()
	local hasTarget = hasTargetDuration()
	local width = xspace * (strings - 1)
	local tbo = topBarreOffset * size
	user:find('next', 'duration')
	local offset = hasTarget and user:xyRight() or -userwidth
	local xoffset = (offset - width) / 2
    local slf = styleListFull[t.Style]
    nwc.hasTypeface(slf[1])
    nwc.hasTypeface(slf[3])
	local chordFontFace = slf[1]
	local chordFontSize = 5 * size * slf[2]
	local fingeringFontFace = slf[3]
	local fingeringFontSize = slf[4] * 1.5 * size
	local dotFontFace = slf[3]
	local dotFontSize = slf[4] * .8 * size
	local dotYOffset, dotXSize = -.25 * yspace, .375 * xspace
	nwcdraw.setPen(penStyle, lineThickness)
	for i = 0, strings - 1 do
		local func = i == ap-2 and nwcdraw.hintline or nwcdraw.line
		func(i * xspace + xoffset, 0, i * xspace + xoffset, height)
	end
	for i = 0, frets do
		nwcdraw.line(xoffset, i * yspace, xoffset + width, i * yspace)
	end
	if topFret == 1 then
		nwcdraw.moveTo(xoffset, height)
		nwcdraw.beginPath()
		nwcdraw.line(xoffset, height2)
		nwcdraw.line(xoffset+width, height2)
		nwcdraw.line(xoffset+width, height)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end
	nwcdraw.moveTo(offset/2, height + 2 * yspace + tbo)
	nwcdraw.setFont(chordFontFace, chordFontSize)
	nwcdraw.alignText('baseline', 'center')
	nwcdraw.text(t.Name)
	local stringNum = 1
	local x = xoffset
	local lowFret = 99
	local highFret = 0
	for f in t.Finger:gmatch('%S+') do
		if stringNum > strings then break end
		local f1 = f:match('(%d+)')
		local f2 = f:match(':(%S)')
		local fretPos = tonumber(f1)
		if fretPos then
			lowFret = math.min(fretPos, lowFret)
			highFret = math.max(fretPos, highFret)
			local y = yspace * (frets - fretPos + topFret - .5)
			if y > 0 and y < height then
				nwcdraw.setPen(penStyle, lineThickness)
				nwcdraw.moveTo(x, y)
				nwcdraw.beginPath()
				nwcdraw.ellipse(dotXSize)
				nwcdraw.endPath()
				if f2 then
					nwcdraw.setWhiteout(true)
					nwcdraw.moveTo(x, y + dotYOffset)
					nwcdraw.setFont(dotFontFace, dotFontSize, 'b')
					nwcdraw.text(f2)
					nwcdraw.setWhiteout(false)
				end
				for b in t.Barre:gmatch('%S+') do
					local b1, b2 = b:match('(%d):(%d)')
					b1, b2 = tonumber(b1), tonumber(b2)
					if b1 and b2 and b1 == stringNum and b1 < b2 and b2 <= strings then
						local y1 = (fretPos == topFret) and height2 + .25 * yspace + tbo or y + .5 * yspace
						local x2 = x + (b2 - b1) * xspace
						nwcdraw.setPen(penStyle, barreThickness)
						nwcdraw.moveTo(x, y1)
						nwcdraw.beginPath()
						nwcdraw.bezier((x2 + x) / 2, y1 + yspace, x2, y1)
						nwcdraw.bezier((x2 + x) / 2, y1 + yspace * .75, x, y1)
						nwcdraw.endPath()
					end
				end
			end
		else
			nwcdraw.moveTo(x, height2 + yspace * .25)
			nwcdraw.setFont(fingeringFontFace, fingeringFontSize)
			nwcdraw.text(f)
		end
		stringNum = stringNum + 1
		x = x+xspace
	end
	if topFret > 1 then
		if topFret <= lowFret and topFret <= highFret then
			nwcdraw.setFont(fingeringFontFace, fingeringFontSize)
			nwcdraw.alignText('baseline', 'left')
			local whichFret = t.FretTextPosition == 'top' and lowFret or highFret
			nwcdraw.moveTo(xoffset + width + .5 * xspace, height - (whichFret - topFret + 1) * yspace)
			nwcdraw.text(tostring(whichFret) .. ' fr.')
		end
	end
	if hasTarget then
		user:reset()
		local spanned = 0
		while (spanned < span) and user:find('next', 'duration') do
			spanned = spanned + 1
		end
		if spanned > 0 then
			local w = user:xyRight()
			nwcdraw.moveTo(0)
			nwcdraw.hintline(w)
		end
	end
end

local function _play(t)
	if not hasTargetDuration() then return end
	local span, capo, strum = t.Span, t.Capo, t.Strum
	local stringNotes = {40, 45, 50, 55, 59, 64}
	local k = {}
	local stringNum = 1
	for f in t.Finger:gmatch('%S+') do
		if stringNum > #stringNotes then break end
		local f1 = f:match('(%d)')
		local fretPos = tonumber(f1) 
		if f == 'o' then fretPos = 0 end
		if fretPos then table.insert(k, fretPos + stringNotes[stringNum]) end
		stringNum = stringNum + 1
	end
	searchObj:reset()
	local spanned = 0
	while (spanned < span) and searchObj:find('next', 'duration') do
		spanned = spanned + 1
	end
	searchObj:find('next')
	local duration = searchObj:sppOffset()
	if duration < 1 then return end
	local noteCount = #k
	searchObj:find('first')
 	local arpeggioShift = math.min(duration, nwcplay.PPQ)/12
    local startOffset = t.Anticipated and math.max(-arpeggioShift * (noteCount-1), searchObj:sppOffset()) or 0
	if k then
		for i, v in ipairs(k) do
			local thisShift = arpeggioShift * ((strum == 'down') and i-1 or noteCount-i) + startOffset
			nwcplay.note(thisShift, duration-thisShift, v + capo)
		end
	end
end

local function _audit(t)
	t.ap = nil
end

return {
--	nwcut = { ['Test'] = 'ClipText' },
	spec = _spec,
	create = _create,
	width = _width,
	spin = _spin,
	draw = _draw,
	play = _play,
	audit = _audit,
	menu = _menu,
	menuInit = _menuInit,
	menuClick = _menuClick,
}
