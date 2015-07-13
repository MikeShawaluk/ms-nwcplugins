-- Version 0.9

--[[----------------------------------------------------------------
TremoloSingle.ms

This object will add tremolo markings to a single note of the proper duration, and optionally provide playback.
The object should be placed immediately before each note to receive the tremolo.

--]]----------------------------------------------------------------

local user = nwcdraw.user
local nextNotePlay = nwc.ntnidx.new()
local durations = { 'Eighth', 'Sixteenth', 'Thirtysecond', 'Sixtyfourth' }

local function draw_TremoloSingle(t)
	local offset = t.Offset
	local beams = t.Beams
	local yu = user:staffPos()
	local stemWeight = 10
	local beamHeight, beamSpacing, beamHalfWidth, beamStemOffset, beamSlope = .6, 1.6, 0.55, 1, 0.6
	nwcdraw.setPen('solid', stemWeight)
	if not user:find('next', 'note') then return end
	local stemDir = user:stemDir(1)
	local x, ys = user:xyStemTip(stemDir)
	local xa, ya = user:xyAlignAnchor(stemDir)
	local d = user:durationBase(1)
	local j
	for i,s in ipairs(durations) do
		if s == d then j = i end
	end
	if j then
		offset = offset + (user:isBeamed(1) and j*2-.75 or j*1.5+3.75+stemDir/4)
	end	
	x = x or xa + .65
	ys = ys and ys - offset*stemDir or ya - (offset+2)*stemDir
	for i = 0, beams-1 do
		local y = ys-(i*beamSpacing+beamStemOffset)*stemDir
		nwcdraw.moveTo(x-beamHalfWidth, y)
		nwcdraw.beginPath()
		nwcdraw.line(x+beamHalfWidth, y+beamSlope)
		nwcdraw.line(x+beamHalfWidth, y+beamSlope-beamHeight)
		nwcdraw.line(x-beamHalfWidth, y-beamHeight)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end
end

local function spin_TremoloSingle(t,dir)
	t.Beams = t.Beams + dir
	t.Beams = t.Beams
end

local spec_TremoloSingle = {
	Beams = { type='int', default=3, min=1, max=4 },
	Offset = { type='float', default=0, min=-5, max=5, step=.1 },
	Play = { type='bool', default=true },
	TripletPlayback = { type='bool', default=false }
}

local function create_TremoloSingle(t)

end

local function play_TremoloSingle(t)
	if not t.Play then return end
	if not nextNotePlay:find('next', 'note') then return end
	local beams = t.Beams
	local spp = nextNotePlay:sppOffset()
	local ncn = nextNotePlay:noteCount()
	nextNotePlay:find('next')
	local sppEnd = nextNotePlay:sppOffset()
	nextNotePlay:reset()
	nextNotePlay:find('next', 'note')
	local noteDur = nwcplay.PPQ / 2^beams
	if t.TripletPlayback then noteDur = noteDur * 2/3 end
	while spp < sppEnd do
		for i=1, ncn do
			nwcplay.note(spp, noteDur, nwcplay.getNoteNumber(nextNotePlay:notePitchPos(i)))
		end
		spp = spp + noteDur
	end
end

return {
	create = create_TremoloSingle,
	spin = spin_TremoloSingle,
	spec = spec_TremoloSingle,
	draw = draw_TremoloSingle,
	play = play_TremoloSingle
}