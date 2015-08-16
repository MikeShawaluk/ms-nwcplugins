-- Version 0.1

--[[--------------------------------------------------------------------------
This plugin is used to create a tablature "clef". It is designed to be used in 
conjunction with the Tab.ms object. The letters "TAB" will be drawn vertically using
the Page Text font.

Insert the object at the beginning of a 6-line staff which will contain tablature. To
suppress subsequent appearance of the clef, insert another instance whose Visibility 
is set to Never.
@Width
Specifies optional additional width to preserve for the clef, to add spacing before the 
first note in each system. The range of values is 0.0 to 10.0 notehead widths, and the
default setting is 2.
--]]--------------------------------------------------------------------------

-- our object type is passed into the script
local userObjTypeName = ...
local user = nwcdraw.user

local spec_TabClef = {
	{ id = 'Width', label='Width', type='float', default=2, min=0, max=10 }
}

local function create_TabClef(t)
	t.Class = 'StaffSig'
end

local function draw_TabClef(t)
	if user:isHidden() then return end
	nwcdraw.setFontClass('PageText')
	nwcdraw.alignText('middle', 'center')
	local sp = -user:staffPos()-1
	local w = nwcdraw.width()
	nwcdraw.moveTo(-w, sp+3.3)
	nwcdraw.text('T')
	nwcdraw.moveTo(-w, sp)
	nwcdraw.text('A')
	nwcdraw.moveTo(-w, sp-3.3)
	nwcdraw.text('B')
end

local function width_TabClef(t)
	if user:isHidden() then return 0 end
	nwcdraw.setFontClass('PageText')
	local aw = nwcdraw.calcTextSize('A')
	return t.Width + aw/2
end

return {
	create = create_TabClef,
	spec = spec_TabClef,
	draw = draw_TabClef,
	width = width_TabClef,
}
