-- Version 0.1

--[[----------------------------------------------------------------
This plugin draw a ukulele chord chart. Future versions will strum the 
chord when the song is played. A variety of notation is shown, including 
the chord name, open strings, fret position and optional finger numbers. 

When adding a new chord, the user can choose from 35 predefined chords, 
or can choose "(Custom)" to create a chord chart from scratch. The chord 
chart can be positioned vertical by changing the object marker position. 

When a chord is added to a staff, if there is another Ukulele object 
earlier in the staff, it will inherit the style and properties of that 
object. 
@Name
The name of the chord. It is displayed using a font which displays 'b' 
and '#' as flat and sharp symbols. 
@Style
This determines the font style to be used for the chord name and label 
text. The possible values are Serif (MusikChordSerif, Times New Roman), 
Sans (MusikChordSans, Arial) and Swing (SwingChord, SwingText). The 
default setting is Serif. 
@Finger
The fingerings for each string, entered from low to high string, 
separate by spaces. Each position can be a number, indicating the fret 
position, or a 'o' or 'x' for open or unplayed strings, respectively. 
@Size
The size of the chord chart, ranging from 1.0 to 5.0. The default is 1.
@Frets
The number of fret positions to show in the chart, ranging from 1 to 10. 
The default is 4. 
@TopFret
The top fret number displayed in the chart. When the value is 1, the top 
border of the chart will be thicker. For larger values, the number of 
the first fingered fret will be displayed to the left of the chart. The 
default is 1. 
@Span
For playback, the number of notes/rests that the chord should span. A 
value of 0 will disable playback. The default is 0. 
@LabelOpen
Determines whether open strings will be labeled at the top of the chart. 
The default is true. 
--]]----------------------------------------------------------------

local userObjTypeName = ...
local idx = nwc.ntnidx
local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()

local styleListFull = {
    Serif = { 'MusikChordSerif', 1, 'Times New Roman', 1 },
    Sans = { 'MusikChordSans', 1, 'Arial', 1 },
    Swing = { 'SwingChord', 1.25, 'SwingText', 1.25 },
}
local styleList = { 'Serif', 'Sans', 'Swing' }
local strings = 4

local _spec = {
	{ id='Name', label='Chord Name', type='text', default='' },
    { id='Style', label='Font Style', type='enum', default=styleList[1], list=styleList },
	{ id='Finger', label='Fingerings', type='text', default='' },
	{ id='Size', label='Chart Size', type='float', default=1, min=0.5, max=5, step=.5 },
	{ id='Frets', label='Frets to Show', type='int', default=4, min=3, max=10 },
	{ id='TopFret', label='Top Fret', type='int', default=1, min=1 },
	{ id='Span', label='Note Span', type='int', default=0, min=0 },
	{ id='LabelOpen', label='Label Open Strings', type='bool', default=true },
}

local commonChords = {
	['(Custom)'] = { '', 1 },
	['C'] = { 'o o o 3', 1 },
	['D'] = { '2 2 2 o', 1 },
	['E'] = { '4 4 4 2', 1 },
	['F'] = { '2 o 1 o', 1 },
	['G'] = { 'o 2 3 2', 1 },
	['A'] = { '2 1 o o', 1 },
	['B'] = { '4 3 2 2', 1 },
	['Cm'] = { 'o 3 3 3', 1 },
	['Dm'] = { '2 2 1 o', 1 },
	['Em'] = { 'o 4 3 2', 1 },
	['Fm'] = { '1 o 1 3', 1 },
	['Gm'] = { 'o 2 3 1', 1 },
	['Am'] = { '2 o o o', 1 },
	['Bm'] = { '4 2 2 2', 1 },
	['C7'] = { 'o o o 1', 1 },
	['D7'] = { '2 2 2 3', 1 },
	['E7'] = { '1 2 o 2', 1 },
	['F7'] = { '2 3 1 3', 1 },
	['G7'] = { 'o 2 1 2', 1 },
	['A7'] = { 'o 1 o o', 1 },
	['B7'] = { '2 3 2 2', 1 },
	['Cmaj7'] = { 'o o o 2', 1 },
	['Dmaj7'] = { '2 2 2 4', 1 },
	['Emaj7'] = { '1 3 o 2', 1 },
	['Fmaj7'] = { '2 4 1 3', 1 },
	['Gmaj7'] = { 'o 2 2 2', 1 },
	['Amaj7'] = { '1 1 o o', 1 },
	['Bmaj7'] = { '4 3 2 1', 1 },
	['Cm7'] = { '3 3 3 3', 1 },
	['Dm7'] = { '2 2 1 3', 1 },
	['Em7'] = { 'o 2 o 2', 1 },
	['Fm7'] = { '1 3 1 3', 1 },
	['Gm7'] = { 'o 2 1 1', 1 },
	['Am7'] = { 'o o o o', 1 },
	['Bm7'] = { '2 2 2 2', 1 },
}

local chordNames = {}
for k, _ in pairs(commonChords) do
	table.insert(chordNames, k)
end
table.sort(chordNames)

local priorParams = { 'Style', 'Size', 'Frets', 'Span', 'LabelOpen', 'Pos' }
local function _create(t)
	local chord = nwcui.prompt('Select a Chord','|' .. table.concat(chordNames,'|'))
	if not chord then return end
	if idx:find('prior', 'user', userObjTypeName) then
		for k, s in ipairs(priorParams) do
			t[s] = idx:userProp(s)
		end
	end
	local strings = t.Strings
	t.Name = (chord == '(Custom)') and '' or chord
	t.Finger = commonChords[chord][1]
	t.TopFret = commonChords[chord][3]
end

local function _spin(t, d)
	t.Span = t.Span + d
	t.Span = t.Span
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
	local size, frets, topFret, span, labelOpen = t.Size, t.Frets, t.TopFret, t.Span, t.LabelOpen
	local penStyle = 'solid'
	local lineThickness = my * 0.125 * size
	local xspace, yspace = size / xyar, size
	local height = yspace * frets

	local userwidth = user:width()
	local hasTarget = hasTargetDuration()
	local width = xspace * (strings - 1)
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
	local dotXSize = 0.375 * xspace
	nwcdraw.setPen(penStyle, lineThickness)
	for i = 0, strings - 1 do
		nwcdraw.line(i * xspace + xoffset, 0, i * xspace + xoffset, height)
	end
	for i = 0, frets do
		nwcdraw.line(xoffset, i * yspace, xoffset + width, i * yspace)
	end
	nwcdraw.moveTo(offset/2, height + 1.75 * yspace)
	nwcdraw.setFont(chordFontFace, chordFontSize)
	nwcdraw.alignText('baseline', 'center')
	nwcdraw.text(t.Name)
	local stringNum = 1
	local x = xoffset
	local lowFret = 99
	local highFret = 0
	for f in t.Finger:gmatch('%S+') do
		if stringNum > strings then break end
		if tonumber(f) then
			lowFret = math.min(f, lowFret)
			highFret = math.max(f, highFret)
		end
	end
	if topFret == 1 and highFret > frets then
		topFret = math.max(highFret - frets + 1, 1)
	end
	local height2 = (topFret == 1) and height + .5 * yspace or height
	if topFret == 1 then
		nwcdraw.moveTo(xoffset, height)
		nwcdraw.beginPath()
		nwcdraw.line(xoffset, height2)
		nwcdraw.line(xoffset+width, height2)
		nwcdraw.line(xoffset+width, height)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end	
	for f in t.Finger:gmatch('%S+') do
		if stringNum > strings then break end
		if tonumber(f) then
			local y = yspace * (frets - f + topFret - .5)
			if y > 0 and y < height then
				nwcdraw.moveTo(x, y)
				nwcdraw.beginPath()
				nwcdraw.ellipse(dotXSize)
				nwcdraw.endPath()
			end
		else
			if labelOpen or f == 'x' then
				nwcdraw.moveTo(x, height2 + yspace * .25)
				nwcdraw.setFont(fingeringFontFace, fingeringFontSize)
				nwcdraw.text(f)
			end
		end
		stringNum = stringNum + 1
		x = x + xspace
	end
	if topFret > 1 then
		if topFret <= lowFret then
			nwcdraw.setFont(fingeringFontFace, fingeringFontSize)
			nwcdraw.alignText('baseline', 'right')
			nwcdraw.moveTo(xoffset - .75 * xspace, height - (lowFret - topFret + 1) * yspace)
			nwcdraw.text(lowFret)
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

return {
	spec = _spec,
	create = _create,
	width = _width,
	spin = _spin,
	draw = _draw,
}
