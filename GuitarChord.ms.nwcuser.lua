-- Version 0.2

--[[----------------------------------------------------------------
GuitarChord.ms

This will draw and play guitar chords.
--]]----------------------------------------------------------------

local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()

local obj_spec = {
	Size = { type='float', default=1 },
	Frets = { type='int', default=5, min=1 },
	Name = { type='text', default='' },
	Finger = { type='text', default='' },
	Barre = { type='text', default='' },
	Capo = { type='int', default=0, min=0 },
	TopFret = { type='int', default=1, min=1 },
	Span = { type='int', default=1, min=0 },
	FretTextPosition = { type='enum', default='top', list={'top','bottom'} },
	TopBarreOffset = { type='int', default=0, min=0 }
}

local function create_GuitarChord(t)
	for k in pairs(obj_spec) do t[k]=t[k] end
end

local function spin_GuitarChord(t, dir)
	t.Span = t.Span + dir
	t.Span = t.Span
end

local function draw_GuitarChord(t)
	local xyar = nwcdraw.getAspectRatio()
	local size = t.Size
	local frets = t.Frets
	local topFret = t.TopFret
	local topBarreOffset = t.TopBarreOffset
	local span = t.Span
	local penStyle = 'solid'
	local lineThickness = 100 * size
	local barreThickness = 80 * size
	local xspace, yspace = size / xyar, size
	local height = yspace * frets
	local height2 = (topFret == 1) and height + .5 * yspace or height
	local strings = 6
	local width = xspace * (strings - 1)
	local tbo = topBarreOffset * size
	
	user:find('next', 'duration')
	local offset = user:xyRight()
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

	nwcdraw.moveTo(offset / 2, height + 2 * yspace + tbo)
	nwcdraw.setFont(chordFontFace, chordFontSize)
	nwcdraw.alignText('baseline', 'center')
	nwcdraw.text(t.Name)
	
	local stringNum = 1
	local x = xoffset
	local lowFret = 99
	local highFret = 0
	for f in t.Finger:gmatch('%S+') do
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
					if b1 and b2 and tonumber(b1) == stringNum then
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

local function play_GuitarChord(t)
	local span = t.Span
	local capo = t.Capo
	local stringNotes = {40, 45, 50, 55, 59, 64}
	local k = {}
	local stringNum = 1
	for f in t.Finger:gmatch('%S+') do
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
	if k then
		local arpeggioShift = duration >= nwcplay.PPQ and nwcplay.PPQ / 16 or 0
		local thisShift = 0
		for i, v in ipairs(k) do
			nwcplay.note(thisShift, duration-thisShift, v + capo)
			thisShift = thisShift + arpeggioShift
		end
	end
end

return {
	spec = obj_spec,
	create = create_GuitarChord,
	spin = spin_GuitarChord,
	draw = draw_GuitarChord,
	play = play_GuitarChord
	}
