--[[-------------------------------------------------------------------------
Version 0.2

This NWC user tool can be used to convert one or more note/chords into
single-note tremolos, by inserting a TremoloSingle.ms object before each.

$NWCUT$CONFIG: ClipText $
--]]-------------------------------------------------------------------------

-- we want to work with basic text for most lines
nwcut.setlevel(2)
local addCount = 0
local beams = nwcut.prompt('Number of Beams:', '#[1-4]', 3)

local function warnline(string, value)
	local s1, s2 = value == 0 and 'No' or tostring(value), value == 1 and '' or 's'
	nwcut.warn(string.format(string .. '\n', s1, s2))
end

for item in nwcut.items() do
	if item:IsFake() then
		-- don't process these
	elseif item:ContainsNotes() then
		local user = nwcItem.new('|User|TremoloSingle.ms')
		user.Opts.Pos = 0
		user.Opts.Beams = beams
		nwcut.writeline(user)
		addCount = addCount + 1
	end
	nwcut.writeline(item)
end

warnline('%s TremoloSingle.ms object%s will be added.', addCount)
