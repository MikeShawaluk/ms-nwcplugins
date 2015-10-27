--[[-------------------------------------------------------------------------
Version 0.2

This NWC user tool can be used to mark a section of notes for 8va marks, by
inserting instrument changes with transposition values. It will prompt the user
for the type of mark to use (e.g. 8va, 8va bassa, 15ma, etc.) If the Ottavamatic.ms
object is present, it will adjust instrument change transpose by that amount.

$NWCUT$CONFIG: ClipText $
--]]-------------------------------------------------------------------------

local function insertInstrChange(trans, pos)
	local instr = nwcItem.new('|Instrument')
	instr.Opts.Trans = trans
	instr.Opts.Pos = pos
	nwcut.writeline(instr)
end

local first = true
local markTrans = { ['15ma']=24, ['8va']=12, ['8va bassa']=-12, ['15ma bassa']=-24 }
local staffTrans = 0
local markType = nwcut.prompt('Type:', '|15ma|8va|8va bassa|15ma bassa', '8va')
local trans = markTrans[markType]
local pos = trans > 0 and 10 or -10
nwcut.setlevel(2)

for item in nwcut.items() do
	if item:IsFake() then
		if item.ObjType == 'User' then
			if item.UserType == 'Ottavamatic.ms' then
				staffTrans = item.Opts.StaffTranspose or 0
			end
		end
	elseif first then
		insertInstrChange(trans + staffTrans, pos)
		first = false
	end
	nwcut.writeline(item)
end

insertInstrChange(staffTrans, pos)
