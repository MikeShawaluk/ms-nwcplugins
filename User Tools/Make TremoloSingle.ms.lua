--[[-------------------------------------------------------------------------
Version 0.1

This NWC user tool can be used to convert one or more note/chords into
single-note tremolos, by inserting a TremoloSingle.ms object before each.

$NWCUT$CONFIG: ClipText $
--]]-------------------------------------------------------------------------

-- we want to work with basic text for most lines
nwcut.setlevel(1)
local addCount = 0
local beams = nwcut.prompt('Number of Beams:', '#[1-4]', 3)

local function plural(value)
	return value == 0 and 'No' or tostring(value), value == 1 and '' or 's'
end

for item in nwcut.items() do
	if item:IsFake() then
		-- don't process these
	elseif item:ContainsNotes() then
		local user = nwcItem.new('|User|TremoloSingle.ms')
		user:Provide("Beams", beams)
		user:Provide("Pos", 0)
		nwcut.writeline(user)
		addCount = addCount + 1
	end
	nwcut.writeline(item)
end

nwcut.warn(string.format('%s TremoloSingle.ms object%s added.\n', plural(addCount)))
