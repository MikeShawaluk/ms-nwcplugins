-- Version 0.95x

--[[----------------------------------------------------------------
This plugin draws 8va/15ma (bassa) markings in a score by looking for Instrument Change commands with a Transpose settings corresponding to one or two octaves upward/downward. The markings include a starting label and 
dashed line that spans systems when required. A number of settings are available to customize the style and appearance of the markings.

To use the object, insert a copy at the start of each staff which will use the markings. Then insert Instrument Change commands at the start and end of each section that you wish to mark, with the starting instrument 
change having an effective transpose of 12, -12, 24 or -24, and the ending instrument change having an effective transpose of 0.  If you want to discontinue 8va markings in your score, insert another copy of the object 
and set its visibility to Never. To re-enable the markings, add another visible one later in the score.
@UpOneText
Label text to use for transposing up one octave. The default setting is "8va".
@DownOneText
Label text to use for transposing down one octave. The default setting is "8va bassa".
@UpTwoText
Label text to use for transposing up two octaves. The default setting is "15ma".
@DownTwoText
Label text to use for transposing down two octaves. The default setting is "15ma bassa".
@Courtesy
Determines whether "( )" should be added around the label when a region extends from the previous system. The default setting is enabled (checked).
@IncludeRests
This will allow an 8va region to include beginning or trailing rests. Normally, the markings will be automatically positioned at the first and last notes between the instrument changes (which is standard engraving practice). 
When this setting is enabled, leading or trailing rests in this section will also be included. The default setting is disabled (unchecked).
@StaffTranspose
Staff transposition value, to allow for non-C instrument parts. This should be set to the transpose value for the staff's default instrument. The default setting is 0.

When using 8va markings on transposed staves, this value should be taken into account for the Instrument Change commands that start and end each marked section. For example, a Bb clarinet staff would generally have a 
staff instrument transpose of -2. Therefore, an 8va region for this instrument would have starting and ending transpose values of 10 and -2.
--]]----------------------------------------------------------------

local userObjTypeName = ...
local user = nwcdraw.user
local showInTargets = {edit=1, selector=1}
local transposeLookup = { [12] = 1, [-12] = -1, [24] = 2, [-24] = -2 }
local priorUser8va = nwc.ntnidx.new()
local nextUser8va = nwc.ntnidx.new()
local priorPatch = nwc.ntnidx.new()
local nextPatch = nwc.ntnidx.new()
local edgeNotePos = nwc.drawpos.new()
local endOfStaff = nwc.drawpos.new()

local dtt = { int='#[%s,%s]', float='#.#[%s,%s]' }

local menu_Ottavamatic = {}

local spec_Ottavamatic = {
	{ id='UpOneText', label='+1 &Octave Text', type='text', default='8va' },
	{ id='DownOneText', label='-1 &Octave Text', type='text', default='8va bassa' },
	{ id='UpTwoText', label='+2 &Octave Text', type='text', default='15ma' },
	{ id='DownTwoText', label='-2 &Octave Text', type='text', default='15ma bassa' },
	{ id='Courtesy', label='Add Courtesy Marks', type='bool', default=true },
	{ id='IncludeRests', label='Include Rests', type='bool', default=false },
	{ id='StaffTranspose', label='Staff Transpose', type='int', default=0, min=-120, max=120 }
}

for k, s in ipairs(spec_Ottavamatic) do
	local a = {	name=s.label, disable=false, data=k }
	if s.type == 'bool' then
		a.type = 'command'
	else
		a.type = 'choice'
		a.list = s.type == 'enum' and s.list or { '', 'Change...' }
	end
	menu_Ottavamatic[#menu_Ottavamatic+1] = a
end

local function menuInit_Ottavamatic(t)
	for _, m in ipairs(menu_Ottavamatic) do
		local s = spec_Ottavamatic[m.data]
		local v = t[s.id]
		if m.type == 'command' then
			m.checkmark = v
		else
			if s.type ~= 'enum' then
				m.list[1] = v
			end
			m.default = v
		end
	end
end

local function menuClick_Ottavamatic(t, menu, choice)
	local m = menu_Ottavamatic[menu]
	local s = spec_Ottavamatic[m.data]
	local v = t[s.id]
	if m.type == 'command' then
		t[s.id] = not v
	else
		if s.type == 'enum' then
			t[s.id] = m.list[choice]
		elseif choice ~= 1 then
			local dt = s.type == 'text' and '*' or string.format(dtt[s.type], s.min or -100, s.max or 100)
			t[s.id] = nwcui.prompt(string.format('Enter %s:', string.gsub(s.label, '&', '')), dt, v)
		end
	end
end

local function doPrintName(showAs)
	nwcdraw.setFont('Tahoma', 3, 'r')

	local xyar = nwcdraw.getAspectRatio()
	local w, h = nwcdraw.calcTextSize(showAs)
	local w_adj, h_adj = (h/xyar), (w*xyar)+3
	if not nwcdraw.isDrawing() then return w_adj+.2 end

	for i=1, 2 do
		nwcdraw.moveTo(-w_adj/2, 0)
		if i == 1 then
			nwcdraw.setWhiteout()
			nwcdraw.beginPath()
		else
			nwcdraw.endPath('fill')
			nwcdraw.setWhiteout(false)
			nwcdraw.setPen('solid', 150)
		end
		nwcdraw.roundRect(w_adj/2, h_adj/2, w_adj/2, 1)
	end

	nwcdraw.alignText('bottom', 'center')
	nwcdraw.moveTo(0, 0)
	nwcdraw.text(showAs, 90)
	return 0
end
	
local function find8vaEdge(idx, dir, t)
	if not idx:find(dir,'objType', 'Instrument') then return false end
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
	if shiftDir > 0 and label:match('%d+') then
		local part1 = labelPrefix .. (label:match('(%d+)') or '')
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

local function create_Ottavamatic(t)
	t.Class = 'StaffSig'
    t.Pos = 0
end

local function draw_Ottavamatic(t)
	local _, my = nwcdraw.getMicrons()
	local penWidth = my*.315
	local drawpos = nwc.drawpos
 	local media = nwcdraw.getTarget()
	local w = 0
	local yOffset = user:staffPos()
	if showInTargets[media] and not nwcdraw.isAutoInsert() then
		w = doPrintName('Ottavamatic')
	end
	if not nwcdraw.isDrawing() then return w end
	if user:isHidden() then return end
	local what = t.IncludeRests and 'noteOrRest' or 'note'
	nwcdraw.setFontClass('StaffItalic')
	nwcdraw.setFontSize(5)
	nwcdraw.setPen('dash', penWidth)
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

local function transpose_Ottavamatic(t, semitones, notepos, updpatch)
	if updpatch then
		t.StaffTranspose = t.StaffTranspose - semitones
	end
end
 
return {
	spec = spec_Ottavamatic,
	create = create_Ottavamatic,
	width = draw_Ottavamatic,
	draw = draw_Ottavamatic,
	transpose = transpose_Ottavamatic,
	menu = menu_Ottavamatic,
	menuInit = menuInit_Ottavamatic,
	menuClick = menuClick_Ottavamatic,
}
