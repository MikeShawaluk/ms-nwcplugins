-- Version 0.2

--[[----------------------------------------------------------------
TremoloSingle.ms

This object will add tremolo markings to a single note of the proper duration. The object should be placed immediately
before each note to receive the tremolo. 

--]]----------------------------------------------------------------

local user = nwcdraw.user

local function draw_TremoloSingle(t)
	local offset = tonumber(t.Offset) or 0
	local bars = tonumber(t.Bars) or 3
	local yu = user:staffPos()
	
	local durations = {
	"Eighth",
	"Sixteenth",
	"Thirtysecond",
	"Sixtyfourth"
	}
	
	local stemWeight = 10
	local barHeight, barSpacing, barHalfWidth, barStemOffset, barSlope = .6, 1.6, 0.55, 1, 0.6
	nwcdraw.setPen("solid", stemWeight)
	
	if not user:find("next","note") then return end
	local stemDir = user:stemDir(1)
	local x, ys = user:xyStemTip(stemDir)
	local xa, ya = user:xyAlignAnchor(stemDir)
	local d = user:durationBase(1)
	
	local j
	
	for i,s in ipairs(durations) do
		if s == d then j = i end
	end

	if j then
		offset = offset + (user:isBeamed(1) and j*2 - .75 or j*1.5 + 3.75 + stemDir/4)
	end	

	x = x or xa + .65
	ys = ys and ys - offset*stemDir or ya - (offset+2)*stemDir

	for i=0,bars-1 do
		local y = ys-(i*barSpacing+barStemOffset)*stemDir
		nwcdraw.moveTo(x-barHalfWidth,y)
		nwcdraw.beginPath()
		nwcdraw.line(x+barHalfWidth,y+barSlope)
		nwcdraw.line(x+barHalfWidth,y+barSlope-barHeight)
		nwcdraw.line(x-barHalfWidth,y-barHeight)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end
end

local function spin_TremoloSingle(t,dir)
	local v = tonumber(t.Bars) or 3
	v = math.min(math.max(v + dir,1),5)
	t.Bars = v
end

local function audit_TremoloSingle(t)
	t.Offset = tonumber(t.Offset) or 0
	t.Bars = tonumber(t.Bars) or 3
end

local function create_TremoloSingle(t)
	t.Offset = 0
	t.Bars = nwcui.prompt('Number of bars','#[1,5]',3)
end

return {
	create = create_TremoloSingle,
	spin = spin_TremoloSingle,
	audit = audit_TremoloSingle,
	draw = draw_TremoloSingle
	}