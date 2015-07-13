-- Version 0.9

--[[----------------------------------------------------------------
GuitarChord.ms

This will draw and play guitar chords.
--]]----------------------------------------------------------------

local userObjTypeName = ...
local userObj = nwc.ntnidx
local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()
local strumStyles = { 'up', 'down' }
local fretTextPos = { 'top', 'bottom' }
local strings = 6

local spec_GuitarChord = {
	Size = { type='float', default=1, min=0.5, max=5, step=.5 },
	Frets = { type='int', default=4, min=1, max=10 },
	Name = { type='text', default='' },
	Finger = { type='text', default='' },
	Barre = { type='text', default='' },
	Capo = { type='int', default=0, min=0 },
	TopFret = { type='int', default=1, min=1 },
	Span = { type='int', default=0, min=0 },
	FretTextPosition = { type='enum', default='top', list=fretTextPos },
	TopBarreOffset = { type='int', default=0, min=0 },
	Strum = { type='enum', default='Up', list=strumStyles }
}

local commonChords = {
	['(Custom)'] = { '', '', 1 },
	['C'] = { 'x 3 2 o 1 o', '', 1 },
	['D'] = { 'x x o 2 3 2', '', 1 },
	['E'] = { 'o 2 2 1 o o', '', 1 },
	['F'] = { 'x x 3 2 1 1', '5:6', 1 },
	['G'] = { '3 2 o o o 3', '', 1 },
	['A'] = { 'x o 2 2 2 o', '', 1 },
	['B'] = { '2 2 4 4 4 2', '1:6', 1 },
	['Cm'] = { 'x x 5 5 4 3', '', 2 },
	['Dm'] = { 'x o o 2 3 1', '', 1 },
	['Em'] = { 'o 2 2 o o o', '', 1 },
	['Fm'] = { '1 3 3 1 1 1', '1:6', 1 },
	['Gm'] = { '3 5 5 3 3 3', '1:6', 2 },
	['Am'] = { 'x o 2 2 1 o', '', 1 },
	['Bm'] = { '2 2 4 4 3 2', '1:6', 1 },
	['C7'] = { 'x 3 2 3 1 o', '', 1 },
	['D7'] = { 'x o o 2 1 2', '', 1 },
	['E7'] = { 'o 2 o 1 o o', '', 1 },
	['F7'] = { 'x 3 3 5 4 5', '2:3', 2 },
	['G7'] = { '3 2 o o o 1', '', 1 },
	['A7'] = { 'x o 2 o 2 o', '', 1 },
	['B7'] = { 'x 2 1 2 o 2', '', 1 },
	['Cmaj7'] = { 'o 3 2 o o o', '', 1 },
	['Dmaj7'] = { 'x x o 2 2 2', '', 1 },
	['Emaj7'] = { 'o 2 1 1 o o', '', 1 },
	['Fmaj7'] = { 'x x 3 2 1 o', '', 1 },
	['Gmaj7'] = { '3 2 o o o 2', '', 1 },
	['Amaj7'] = { 'x o 2 1 2 o', '', 1 },
	['Bmaj7'] = { 'x 2 4 3 4 2', '2:6', 1 },
	['Cm7'] = { 'x 3 5 3 4 3', '2:6', 2 },
	['Dm7'] = { 'x x o 2 1 1', '5:6', 1 },
	['Em7'] = { 'o 2 2 o 3 o', '', 1 },
	['Fm7'] = { '1 3 3 1 4 1', '1:6', 1 },
	['Gm7'] = { '3 5 5 3 6 3', '1:6', 3 },
	['Am7'] = { 'x o 2 o 1 o', '', 1 },
	['Bm7'] = { 'x 2 4 2 3 2', '2:6', 1 }
}

local function create_GuitarChord(t)
	local chordNames = {}
	for k, _ in pairs(commonChords) do
		table.insert(chordNames, k)
	end
	table.sort(chordNames)
	local chord = nwcui.prompt('Select a Chord','|' .. table.concat(chordNames,'|'))
	if not chord then return end
	t.Name = chord
	t.Finger = commonChords[chord][1]
	t.Barre = commonChords[chord][2]
	t.TopFret = commonChords[chord][3]
	local promptTxt = nwcui.prompt('Strum Style','|Unchanged|'..table.concat(strumStyles,'|'))
	if promptTxt ~= 'Unchanged' then
		t.Strum = promptTxt
	end
	if (not searchObj:find('first','user',userObjTypeName)) or (searchObj >= userObj) then
		t.Size = t.Size
		t.Frets = t.Frets
	end
	t.Capo = t.Capo
	t.Span = t.Span
end

local function spin_GuitarChord(t, dir)
	t.Span = t.Span + dir
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

local function getDrawSettings(t)
	local useSize, useFrets
	if searchObj:find('first','user',userObjTypeName) and (searchObj < userObj) then
		if not nwc.isset(t,'Size') then
			useSize = tonumber(searchObj:userProp('Size'))
		end
		if not nwc.isset(t,'Frets') then
			useFrets = tonumber(searchObj:userProp('Frets'))
		end
	end
	if not useSize then useSize = t.Size end
	if not useFrets then useFrets = t.Frets end
	return useSize, useFrets
end	

local function width_GuitarChord(t)
	local size = getDrawSettings(t)
	return hasTargetDuration() and 0 or strings * size / nwcdraw.getAspectRatio()
end

local function draw_GuitarChord(t)
	local xyar = nwcdraw.getAspectRatio()
	local size, frets = getDrawSettings(t)
	local topFret = t.TopFret
	local topBarreOffset = t.TopBarreOffset
	local span = t.Span
	local penStyle = 'solid'
	local lineThickness = 100 * size
	local barreThickness = 80 * size
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
	local chordFontFace = nwc.hasTypeface('MusikChordSerif') and 'MusikChordSerif' or 'Arial'
	local chordFontSize = (chordFontFace == 'MusikChordSerif' and 5 or 2.5) * size
	local fingeringFontFace = 'Arial'
	local fingeringFontSize = 1.5 * size
	local dotFontFace = 'Arial'
	local dotFontSize = .8 * size
	local dotYOffset, dotXSize = -.25 * yspace, .375 * xspace
	nwcdraw.setPen(penStyle, lineThickness)
	for i = 0, strings - 1 do
		nwcdraw.line(i * xspace + xoffset, 0, i * xspace + xoffset, height)
	end
	for i = 0, frets do
		nwcdraw.line(xoffset, i * yspace, xoffset + width, i * yspace)
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
						local y1 = (fretPos == 1) and height2 + .25 * yspace + tbo or y + .5 * yspace
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
	else
		nwcdraw.moveTo(xoffset, height2)
		nwcdraw.beginPath()
		nwcdraw.rectangle(width, .5 * yspace)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
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

local function getPerformanceProperty(t, propName)
	if not nwc.isset(t, propName) then
		searchObj:reset()
		if searchObj:find('prior', 'user', userObjTypeName, propName) then
			return searchObj:userProp(propName)
		end
	end
	return t[propName]
end

local function play_GuitarChord(t)
	if not hasTargetDuration() then return end
	local span = t.Span
	local capo = t.Capo
	local strum = getPerformanceProperty(t, 'Strum')
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
	if k then
		local arpeggioShift = math.min(duration, nwcplay.PPQ)/12
		local thisShift = 0
		for i, v in ipairs(k) do
			local thisShift = arpeggioShift * ((strum == 'down') and (noteCount-i) or i)
			nwcplay.note(thisShift, duration-thisShift, v + capo)
		end
	end
end

return {
	spec = spec_GuitarChord,
	create = create_GuitarChord,
	width = width_GuitarChord,
	spin = spin_GuitarChord,
	draw = draw_GuitarChord,
	play = play_GuitarChord
}
