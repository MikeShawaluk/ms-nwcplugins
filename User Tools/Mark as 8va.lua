--[[-------------------------------------------------------------------------
Version 0.1

This NWC user tool can be used to mark a section of notes for 8va marks, by
inserting instrument changes with transposition values. It will prompt the user
for the type of mark to use (e.g. 8va, 8va bassa, 15ma, etc.)

It wants to check for the existance of an Ottavamatic.ms object on the staff,
but it does not know how.

$NWCUT$CONFIG: ClipText $
--]]-------------------------------------------------------------------------

-- we want to work with basic text for most lines
nwcut.setlevel(1)

local first = true
local markTrans = { ['15ma']=24, ['8va']=12, ['8va bassa']=-12, ['15ma bassa']=-24 }
local staffTrans = nwcut.prompt('Staff Transpose:', '#[-120,120]', 0)
local markType = nwcut.prompt('Type:', '|15ma|8va|8va bassa|15ma bassa', '8va')
local trans = markTrans[markType]
local pos = trans > 0 and 10 or -10

local function insertInstrChange(trans)
	local instr = nwcItem.new('|Instrument|Name:" "')
	instr:Provide("Trans", trans)
	instr:Provide("Pos", pos)
	nwcut.writeline(instr)
end

for item in nwcut.items() do
	if item:IsFake() then 
		-- Skip all fake items
	elseif first then
		insertInstrChange(trans+staffTrans)
		first = false
	end
	nwcut.writeline(item)
end

insertInstrChange(staffTrans)
