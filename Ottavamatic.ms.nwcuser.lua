-- Version 0.1

--[[----------------------------------------------------------------
Ottavamatic.ms

This will look for Instrument change commands with a Transpose setting and draw 8va/15ma (bassa) marks between them.

--]]----------------------------------------------------------------

local userObjTypeName = ...
local user = nwcdraw.user
local showInTargets = {edit=1, selector=1}
local transposeLookup = { [12] = 1, [-12] = -1, [24] = 2, [-24] = -2 }

local function doPrintName(showAs)
	nwcdraw.setFont('Arial', 3, 'b')
	local xyar = nwcdraw.getAspectRatio()
	local w,h = nwcdraw.calcTextSize(showAs)
	local w_adj, h_adj = h/xyar/2, (w*xyar+2)/2
	if not nwcdraw.isDrawing() then return w_adj*2 end
	nwcdraw.alignText('bottom','center')
	nwcdraw.moveTo(-w_adj,0)
	nwcdraw.beginPath()
	nwcdraw.roundRect(w_adj, h_adj, 0.15)
	nwcdraw.endPath('fill')
	nwcdraw.moveTo(0,0)
	nwcdraw.setWhiteout()
	nwcdraw.text(showAs,90)
	nwcdraw.setWhiteout(false)
	return 0
end

local obj_spec = {
	Class = { type='text', default='StaffSig' },
	UpOneText = { type='text', default='8va' },
	DownOneText = { type='text', default='8va bassa' },
	UpTwoText = { type='text', default='15ma' },
	DownTwoText = { type='text', default='15ma bassa' },
	Courtesy = { type='bool', default=true },
	IncludeRests = { type='bool', default=false },
	StaffTranspose = { type='int', default=0, min=-120, max=120 }
}

local function do_create(t)
	t.Class = t.Class
	t.UpOneText = t.UpOneText
	t.DownOneText = t.DownOneText
	t.UpTwoText = t.UpTwoText
	t.DownTwoText = t.DownTwoText
	t.Courtesy = t.Courtesy
	t.IncludeRests = t.IncludeRests
	t.StaffTranspose = t.StaffTranspose
end

local priorUser8va = nwc.ntnidx.new()
local nextUser8va = nwc.ntnidx.new()
local priorPatch = nwc.ntnidx.new()
local nextPatch = nwc.ntnidx.new()

local edgeNotePos = nwc.drawpos.new()
local endOfStaff = nwc.drawpos.new()
	
local function find8vaEdge(idx, dir, t)
	if not idx:find(dir,'objType','Instrument') then return false end
	local trans = (tonumber(idx:objProp('Trans')) or 0) - t.StaffTranspose
	return transposeLookup[trans] or 0
end
 
local function drawShift(drawpos1, drawpos2, extendingSection, endOfSection, shiftDir, y, t)
	local x1 = drawpos1:xyAnchor()
	local x2 = endOfSection and drawpos2:xyRight()+.5 or drawpos2:xyAnchor()
	local lt = { [-2]=t.DownTwoText, [-1]=t.DownOneText, [1]=t.UpOneText, [2]=t.UpTwoText }
	local tail = shiftDir > 0 and 2 or -2
	local label = lt[shiftDir]
	local addParens = extendingSection and t.Courtesy
	local labelPrefix = addParens and '(' or ''
	local labelSuffix = addParens and ')' or ''
	local labelFull = labelPrefix .. label .. labelSuffix
	local w,h,d = nwcdraw.calcTextSize(labelFull)
	local y2 = shiftDir > 0 and y-h+d or y-d
	x2 = math.max(x2, x1+w+1)
	nwcdraw.moveTo(x1, y2)
	if shiftDir > 0 then
		local part1 = labelPrefix .. label:match('(%d+)')
		local part2 = label:match('(%a+)')
		local part1Len = nwcdraw.calcTextSize(part1)
		local part2Len = nwcdraw.calcTextSize(part2)
		nwcdraw.text(part1)
		nwcdraw.moveTo(x1+part1Len, y2+d*.95)
		nwcdraw.text(part2)
		if labelSuffix ~= '' then
			nwcdraw.moveTo(x1+part1Len+part2Len, y2)
			nwcdraw.text(labelSuffix)
		end
	else
		nwcdraw.text(labelFull)
	end
	nwcdraw.line(x2, y, x1+w+.25, y)
	if endOfSection then nwcdraw.line(x2, y, x2, y-tail) end
end

local function do_draw(t)
	local drawpos = nwc.drawpos
 	local media = nwcdraw.getTarget()
	local w = 0
	
	local yOffset = user:staffPos()
	
	if showInTargets[media] and not nwcdraw.isAutoInsert() then
		w = doPrintName(userObjTypeName)
	end

	if not nwcdraw.isDrawing() then return w end
	
	if user:isHidden() then return end
	
	local what = t.IncludeRests and 'noteOrRest' or 'note'
	
	nwcdraw.setFontClass('StaffItalic')
	nwcdraw.setFontSize(5)
	nwcdraw.setPen('dash', 250)
	nwcdraw.alignText('bottom', 'left')

	if not priorUser8va:find('prior', 'user', userObjTypeName) then priorUser8va:find('first') end
	if not nextUser8va:find('next', 'user', userObjTypeName) then nextUser8va:find('last') end
 
	if not drawpos:find('next', what) then return end
	
	endOfStaff:find('last')
	priorPatch:find(drawpos)
	nextPatch:find(drawpos)
	local priorShift = find8vaEdge(priorPatch, 'prior', t)
	local yPos = priorPatch:staffPos()

	if priorPatch < priorUser8va then priorPatch:find(priorUser8va) end

	repeat
		local nextShift = find8vaEdge(nextPatch, 'next', t)
		local nextPatchYPos = nextPatch:staffPos()
		if not nextShift then nextPatch:find('last') end
		
		if nextPatch > nextUser8va then nextPatch:find(nextUser8va) end

		if priorShift and (priorShift ~= 0) then
			priorPatch:find('next', what)
			local extendingSection = priorPatch < drawpos
			local endOfSection = true
			priorPatch:find(nextPatch) 
			priorPatch:find('prior', what)
			if not edgeNotePos:find(priorPatch) then
				endOfSection = false
				edgeNotePos:find(endOfStaff)
			end
			drawShift(drawpos, edgeNotePos, extendingSection, endOfSection, priorShift, yPos-yOffset, t)
		end
		yPos = nextPatchYPos
		priorShift = nextShift
	until not (priorShift and (nextPatch < nextUser8va) and priorPatch:find(nextPatch) and drawpos:find(priorPatch) and drawpos:find('next', what))
end

local function do_transpose(t, semitones, notepos, updpatch)
	if updpatch then
		t.StaffTranspose = t.StaffTranspose - semitones
	end
end
 
return {
	spec = obj_spec,
	create = do_create,
	width = do_draw,
	draw = do_draw,
	transpose = do_transpose
	}
