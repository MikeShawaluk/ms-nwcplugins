--[[-------------------------------------------------------------------------
Version 0.1

This NWC user tool can be used to convert two notes into a tremolo, or to "clean up"
a rest chord so its note and rest durations are correct for tremolos.

It does the following:

1. Convert each non-split-voice note/chord to a rest chord, whose rest duration is 
   1/2 of the chord's duration. The rest will be hidden and the chord will be muted.
2. For each pair of converted chords, insert a Tremolo.ms object before the second one.
3. For any encountered rest chords, adjust the note duration so it is consistent with
   the rest duration for Tremolo usage.

$NWCUT$CONFIG: ClipText $
--]]-------------------------------------------------------------------------

-- we want to work with basic text for most lines
nwcut.setlevel(1)
local noteDurBase = nwc.txt.NoteDurBase --{'Whole', 'Half', '4th', '8th', '16th', '32nd', '64th'}
local noteDurBaseRev = {}

for i,s in ipairs(noteDurBase) do
	noteDurBaseRev[s] = i
end

local changeCount, addCount = 0, 0
local firstNote = true
local dur, pos, dur2, opts, stemDir

for item in nwcut.items() do
	if item:IsFake() then
		-- don't process these
	elseif item:ContainsNotes() then
		if item:Is('RestChord') then
			-- for existing RestChords, adjust the note duration to match the rest
			local newItem = nwcItem.new('|RestChord')
			dur = item:Get('Dur')
			pos = item:Get('Pos2')
			dur2 = item:Get('Dur2')
			opts = item:Get('Opts')

			if dur == 'Whole' then
				dur = 'Half'
			else
				dur2 = dur == '16th' and '4th' or noteDurBase[noteDurBaseRev[dur]-1]
			end

			newItem:Provide('Dur2', dur2)
			newItem:Provide('Dur', dur)
			newItem:Provide('Opts', opts)
			newItem:Provide('Pos2', pos)
			changeCount = changeCount + 1
			item = newItem
		else
			-- for regular notes/chords, convert them to a muted RestChord with hidden rest
			local newItem = nwcItem.new('|RestChord')
			dur = item:Get('Dur')
			pos = item:Get('Pos')
			dur2 = item:Get('Dur2')
			stemDir = 'Down'

			if not dur2 then -- don't convert split voice chords
				local newDur = noteDurBase[noteDurBaseRev[dur]+1]
				if dur == '8th' then dur = '4th' end
				newItem:Provide('Dur2', dur)
				newItem:Provide('Dur', newDur)
				newItem:Provide('Opts', string.format('Stem=%s,HideRest,Muted', stemDir))
				newItem:Provide('Pos2', pos)
				item = newItem
				changeCount = changeCount + 1
				firstNote = not firstNote
				if firstNote then
					nwcut.writeline(nwcItem.new('|User|Tremolo.ms|Pos:0'))
					addCount = addCount + 1
				end
			end
		end
	end

	nwcut.writeline(item)
end

if changeCount + addCount == 0 then
	nwcut.warn('No objects were added or updated\n')
else
	nwcut.warn(string.format('%d chords modified, %d Tremolo.ms objects added.\n', changeCount, addCount) )
end
