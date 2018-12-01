-- Version 0.1

--[[----------------------------------------------------------------
This plugin draw a banjo chord chart.
A variety of notation is shown, including the chord name, open and excluded strings, barre 
positions, fret position and optional finger numbers.

When adding a new chord, the user can choose from predefined chords, or can choose "(Custom)"
to create a chord chart from scratch. The chord chart can be positioned vertical by changing the object marker position.

When a chord is added to a staff, if there is another object earlier in the staff,
it will inherit the style and properties of that object.
@Name
The name of the chord. It is displayed using a font which displays 'b' and '#' as flat and sharp symbols.
@Style
This determines the font style to be used for the chord name and label text. The possible values
are Serif (MusikChordSerif, Times New Roman), Sans (MusikChordSans, Arial) and Swing (SwingChord, SwingText).
The default setting is Serif.
@Finger
The fingerings for each string, entered from low to high pitch, separate by spaces. Each 
position can be a number, indicating the fret position, or a 'o' or 'x' for open or unplayed 
strings, respectively.

Each numeric fret position can be appended with ':' and a number, to indicate the 
finger number to be used for that string; the number will be drawn inside the fingering dot.
When finger numbers are being used, the chart size will generally need to be 2 or larger for the
numbers to be readable.
@Barre
Optional groups of strings to be held down by a particular finger, displayed by an arc over the 
fingering dots. Each barre to be drawn is indicated by the starting and ending string numbers, 
separated by ':'. For example, 2:3 would add a barre between the second and third strings.

Note that the fingering positions for each end of a barre should be the same for the
barre to be drawn correctly. 
@Size
The size of the chord chart, ranging from 1.0 to 5.0. Pressing the + and - keys will adjust this
parameter. The default is 1.
@Frets
The number of fret positions to show in the chart, ranging from 1 to 10. The default is 4.
@TopFret
The top fret number displayed in the chart. When the value is 1, the top border of the chart 
will be thicker. For larger values, '# fr.' will be displayed to the right of the chart. The 
default is 1.
@FretTextPosition
Specifies whether the fret text is displayed next to the top or bottom row of fingering dots, 
when Top Fret is greater than 1. The default is top.
@TopBarreOffset
When a barre is present on the top fret and there are open (o) or excluded (x) strings within 
the barre, this setting can be used to move the barre upward a specified distance, to avoid 
collision with those labels. This will also move the Chord Name upward. The default value is 0.0.
--]]----------------------------------------------------------------

local commonChords = {
	['(Custom)'] = { '', '', 1 },
	
	['C'] = { '2 o 1 2', '', 1 },
	['Cm'] = { '1 o 1 1', '', 1 },
	['C+'] = { '2 1 1 2', '2:3', 1 },
	['Cdim'] = { '4 5 4 4', '1:4', 4 },
	['C6'] = { '10 9 8 7', '', 7 },
	['C7'] = { '10 9 8 8', '3:4', 8 },
	['Cmaj7'] = {'10 9 8 9', '', 8 },
	['Cm7'] = {'10 8 8 8', '2:4', 8 },

	['G'] = { 'o o o o', '', 1 },
	['Gm'] = { '5 3 3 5', '2:3', 3 },
	['G+'] = { '1 o o 1', '', 1 },
	['Gdim'] = { '5 3 2 5', '', 2 },
	['G6'] = { '5 4 3 2', '', 2 },
	['G7'] = { 'o o o 3', '', 1 },
	['Gmaj7'] = {'5 4 3 4', '', 3 },
	['Gm7'] = {'5 3 3 3', '2:4', 3 },

	['D'] = { 'o 2 3 4', '', 1 },
	['Dm'] = { 'o 2 3 3', '', 1 },
	['D+'] = { '4 3 3 4', '2:3', 3 },
	['Ddim'] = { 'o 1 3 3', '', 1 },
	['D6'] = { 'o 2 o 4', '', 2 },
	['D7'] = { 'o 2 1 4', '', 1 },
	['Dmaj7'] = {'o 2 2 4', '2:3', 2 },
	['Dm7'] = {'o 2 1 3', '', 1 },

	['A'] = { '2 2 2 2', '1:4', 1 },
	['Am'] = { '2 2 1 2', '', 1 },
	['A+'] = { '3 2 2 3', '2:3', 2 },
	['Adim'] = { '1 2 1 1', '1:4', 1 },
	['A6'] = { '7 6 5 4', '', 4 },
	['A7'] = { '7 6 5 5', '3:4', 5 },
	['Amaj7'] = {'7 6 5 6', '', 5 },
	['Am7'] = {'7 5 5 5', '2:4', 5 },

	['E'] = { '2 1 o 2', '', 1 },
	['Em'] = { '2 o o 2', '', 1 },
	['E+'] = { '2 1 1 2', '2:3', 1 },
	['Edim'] = { '8 9 8 8', '1:4', 8 },
	['E6'] = { '2 4 2 6', '1:3', 2, 5 },
	['E7'] = { '2 1 o o', '', 1 },
	['Emaj7'] = {'2 1 o 1', '', 1 },
	['Em7'] = {'2 o o o', '', 1 },

	['B'] = { '4 4 4 4', '1:4', 4 },
	['Bm'] = { '4 4 3 4', '', 3 },
	['B+'] = { '5 4 4 5', '2:3', 4 },
	['Bdim'] = { '3 4 3 3', '1:4', 3 },
	['B6'] = { '9 8 7 6', '', 6 },
	['B7'] = { '1 2 o 1', '', 1 },
	['Bmaj7'] = {'9 8 7 8', '', 7 },
	['Bm7'] = {'9 7 7 7', '2:4', 7 },

	['F#'] = { '4 3 2 4', '', 2 },
	['F#m'] = { '4 2 2 4', '2:3', 2 },
	['F#+'] = { '4 3 3 4', '2:3', 3 },
	['F#dim'] = { '4 2 1 4', '', 1 },
	['F#6'] = { '4 3 2 1', '', 1 },
	['F#7'] = { '4 3 2 2', '3:4', 2 },
	['F#maj7'] = {'4 3 2 3', '', 2 },
	['F#m7'] = {'4 2 2 2', '2:4', 2 },

	['C#'] = { '11 10 9 11', '', 9 },
	['C#m'] = { '11 9 9 11', '2:3', 9 },
	['C#+'] = { '3 2 2 3', '2:3', 2 },
	['C#dim'] = { '2 o 2 2', '', 1 },
	['C#6'] = { '11 10 9 8', '', 8 },
	['C#7'] = { '11 10 9 9', '3:4', 9 },
	['C#maj7'] = {'11 10 9 10', '', 9 },
	['C#m7'] = {'11 9 9 9', '2:4', 9 },

	['Ab'] = { '1 1 1 1', '1:4', 1 },
	['Abm'] = { '1 1 o 1', '', 1 },
	['Ab+'] = { '2 1 1 2', '2:3', 1 },
	['Abdim'] = { '6 4 3 6', '', 3 },
	['Ab6'] = { '6 5 4 3', '', 3 },
	['Ab7'] = { '6 5 4 4', '3:4', 4 },
	['Abmaj7'] = {'6 5 4 5', '', 4 },
	['Abm7'] = {'6 4 4 4', '2:4', 4 },

	['Eb'] = { '5 3 4 5', '', 3 },
	['Ebm'] = { '4 3 4 4', '', 3 },
	['Eb+'] = { '1 o o 1', '', 1 },
	['Ebdim'] = { '4 2 4 4', '', 2 },
	['Eb6'] = { '10 8 8 8', '2:4', 8 },
	['Eb7'] = { '1 3 2 5', '', 1, 5 },
	['Ebmaj7'] = {'8 8 8 12', '1:3', 8, 5 },
	['Ebm7'] = {'1 3 2 4', '', 1 },

	['Bb'] = { '8 7 6 8', '', 6 },
	['Bbm'] = { '8 6 6 8', '2:3', 6 },
	['Bb+'] = { '4 3 3 4', '2:3', 3 },
	['Bbdim'] = { '2 3 2 2', '1:4', 2 },
	['Bb6'] = { '8 7 6 5', '', 5 },
	['Bb7'] = { '8 7 6 6', '3:4', 6 },
	['Bbmaj7'] = {'8 7 6 7', '', 6 },
	['Bbm7'] = {'8 6 6 6 ', '2:4', 6 },

	['F'] = { '3 2 1 3', '', 1 },
	['Fm'] = { '3 1 1 3', '2:3', 1 },
	['F+'] = { '3 2 2 3', '2:3', 2 },
	['Fdim'] = { '3 1 o 3', '', 1 },
	['F6'] = { '3 2 1 o', '', 1 },
	['F7'] = { '3 2 1 1', '3:4', 1 },
	['Fmaj7'] = {'3 2 1 2', '', 1 },
	['Fm7'] = {'3 1 1 1', '2:4', 1 },
}
local allTonics = { 'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'Ab', 'A', 'A#', 'Bb', 'B' }
local allChords = { '', 'm', '+', 'dim', '6', '7', 'maj7', 'm7' }
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

-- if nwcut then
	-- local userObjTypeName = arg[1]
	-- local score = nwcut.loadFile()
	-- local staff, i1, i2 = score:getSelection()
	-- local chord, chordName, o

	-- for k1, v1 in ipairs({ 'C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#', 'Ab', 'Eb', 'Bb', 'F' }) do
		-- for k2, v2 in ipairs(allChords) do
			-- chordName = v1 .. v2
			-- chord = commonChords[chordName] and chordName or string.gsub(chordName, v1, fsMap[v1] or v1)
			-- if commonChords[chord] then
				-- o = nwcItem.new('User|' .. userObjTypeName)
				-- o.Opts.Name = chordName
				-- o.Opts.Finger = commonChords[chord][1]
				-- o.Opts.Barre = commonChords[chord][2]
				-- o.Opts.TopFret = commonChords[chord][3]
				-- o.Opts.Frets = commonChords[chord][4] or 4
				-- o.Opts.Pos = 5
				-- o.Opts.Size = 3
				-- staff:add(o)
				-- staff:add(nwcItem.new('|Rest|Dur:Half|Visibility:Never'))
				-- staff:add(nwcItem.new(v2 == 'm7' and '|Bar|SysBreak:Y' or '|Bar'))
			-- end
		-- end
	-- end
	-- staff:add(nwcItem.new('|Boundary|Style:NewSystem|NewPage:Y'))

	-- score:setSelection(staff)
	-- score:save()
	-- return		
-- end

local userObjTypeName = ...
local idx = nwc.ntnidx
local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()
local fretTextPos = { 'top', 'bottom' }
local styleListFull = {
    Serif = { 'MusikChordSerif', 1, 'Times New Roman', 1 },
    Sans = { 'MusikChordSans', 1, 'Arial', 1 },
    Swing = { 'SwingChord', 1.25, 'SwingText', 1.25 }
}
local styleList = { 'Serif', 'Sans', 'Swing' }

local strings = 4

local _spec = {
	{ id='Name', label='Chord Name', type='text', default='', width=11 },
    { id='Style', label='Style', type='enum', default=styleList[1], list=styleList, separator=' ' },
	{ id='Finger', label='Fingerings', type='text', width=11, default='' },
	{ id='Barre', label='Barres', type='text', width=11, default='', separator=' ' },
	{ id='Size', label='Chart Size', type='float', default=1, min=0.5, max=5, step=.5 },
	{ id='Frets', label='Frets', type='int', default=4, min=3, max=10, separator=' ' },
	{ id='TopFret', label='Top Fret', type='int', default=1, min=1 },
	{ id='FretTextPosition', label='Fret Text Location', type='enum', default='top', list=fretTextPos },
	{ id='TopBarreOffset', label='Top Barre Offset', type='float', default=0, min=0, step=.25 },
}

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
local tonicsList = ''
for k, v in ipairs(allTonics) do
	if tonics[v] then
		tonicsList = string.format('%s|%s', tonicsList, v)
	end
end
tonicsList = tonicsList .. '|(Custom)'

local function _create(t)
	local chord
	local tonic = nwcui.prompt('Select Tonic', tonicsList)
	if not tonic then return end
	if tonic ~= '(Custom)' then
		local chordsList = ''
		for k, v in ipairs(allChords) do
			local ch = tonic .. v
			if commonChords[ch] or commonChords[(fsMap[tonic] or '') .. v] then
				chordsList = chordsList .. '|' .. ch
			end
		end
		chord = nwcui.prompt('Select Chord', chordsList)
		if not chord then return end
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
	t.Frets = commonChords[chord][4] or 4
	
	if idx:find('prior', 'user', userObjTypeName) then
		t.Style = idx:userProp('Style')
		t.Size = idx:userProp('Size')
		t.FretTextPosition = idx:userProp('FretTextPosition')
		t.Pos = idx:userProp('Pos')
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
	local size, frets, topFret, topBarreOffset, span = t.Size, t.Frets, t.TopFret, t.TopBarreOffset, 0
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
		nwcdraw.line(i * xspace + xoffset, 0, i * xspace + xoffset, height)
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

local function _spin(t, d)
	t.Size = t.Size + d*.5
	t.Size = t.Size
end

return {
	-- nwcut = { ['Test'] = 'ClipText' },
	spec = _spec,
	create = _create,
	width = _width,
	draw = _draw,
	spin = _spin,
}
