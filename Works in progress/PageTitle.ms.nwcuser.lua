-- Version 0.01

--[[-----------------------------------------------------------------------------------------
PageTitle.ms

Add title text to first page, at specified alignment

--]]-----------------------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...

local showInTargets = {edit=1,selector=1}

local function doPrintName(showAs)
	nwcdraw.setFont('Arial',3,"b")

	local xyar = nwcdraw.getAspectRatio()
	local w,h = nwcdraw.calcTextSize(showAs)
	local w_adj,h_adj = h/xyar,(w*xyar)+2
	if not nwcdraw.isDrawing() then return w_adj end

	nwcdraw.alignText("bottom","left")
		
	nwcdraw.moveTo(0,0)
	nwcdraw.beginPath()
	nwcdraw.rectangle(-w_adj,-h_adj)
	nwcdraw.endPath("fill")

	nwcdraw.moveTo(0,0.5)
	nwcdraw.setWhiteout()
	nwcdraw.text(showAs,90)
	nwcdraw.setWhiteout(false)
	return 0
end

local spec_PageTitle = {
	Class = { type='text', default='StaffSig' },
	Title = { type='text', default='' },
	Align = { type='enum', default='center', list=nwc.txt.DrawTextAlign },
	Font = { type='enum', default='PageTitleText', list=nwc.txt.TextExpressionFonts },
	Scale = { type='float', default=1, min=0, max=10 },
	Offset = { type='float', default=0 }
}

local function create_PageTitle(t)
	t.Class = t.Class
	t.Title = t.Title
	t.Align = t.Align
	t.Font = t.Font
	t.Scale = t.Scale
	t.Offset = t.Offset
end

local function draw_PageTitle(t)
	local w = 0
	local drawpos = nwc.drawpos
	local media = nwcdraw.getTarget()
		
	if showInTargets[media] and not nwcdraw.isAutoInsert() then
		w = doPrintName(userObjTypeName)
	end

	if not nwcdraw.isDrawing() then return w end
	
	local align = t.Align
	local offset = t.Offset
	local page = nwcdraw.getPageCounter()
	local system = nwcdraw.getSystemCounter()
	
	if system == 1 and page == 1 then --For now, just draw at the top of the first page
		local xMin, yMin, xMax, yMax = nwcdraw.getPageRect()
		-- nwcdraw.moveTo(xMin,yMin)
		-- nwcdraw.rectangle(xMax-xMin,yMin-yMax)
		nwcdraw.setFontClass(t.Font)
		nwcdraw.alignText('bottom', align)
		local x = xMax -- right align case
		if align == 'left' then
			x = xMin
		elseif align == 'center' then
			x = (x + xMin)/2
		end
		nwcdraw.moveTo(x, yMin+offset)

		nwcdraw.text(t.Title)
	end
end

return {
	spec		= spec_PageTitle,
	create		= create_PageTitle,
	width		= draw_PageTitle,
	draw		= draw_PageTitle
	}
