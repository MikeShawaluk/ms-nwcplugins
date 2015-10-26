--[[-------------------------------------------------------------------------
Version 0.2

This NWC user tool can be used to convert two notes into a tremolo, or to "clean up"
a rest chord so its note and rest durations are correct for tremolos.

It does the following:

1. Convert each non-split-voice note/chord to a rest chord, whose rest duration is 
   1/2 of the chord's duration. The rest will be hidden and the chord will be muted.
   Any dot on the source chord will be preserved in the rest chord.
2. For each pair of converted chords, insert a Tremolo.ms object before the second one.

$NWCUT$CONFIG: ClipText $
--]]-------------------------------------------------------------------------

nwcut.setlevel(2)
local noteDurBase = nwc.txt.NoteDurBase --{'Whole', 'Half', '4th', '8th', '16th', '32nd', '64th'}
local noteDurBaseRev = {}

for i,s in ipairs(noteDurBase) do
	noteDurBaseRev[s] = i
end

local changeCount, addCount = 0, 0
local firstNote = true
local dur, pos, dur2, opts, stemDir, dot, duration

local function warnline(string, value)
	local s1, s2 = value == 0 and 'No' or tostring(value), value == 1 and '' or 's'
	nwcut.warn(string.format(string .. '\n', s1, s2))
end

local function parseDur(durTable)
	local dur, dot
	for v in pairs(durTable) do
		dot = dot or (v == 'Dotted' or v == 'DblDotted') and v
		dur = dur or noteDurBaseRev[v] and v
	end
	return dur, dot
end

for item in nwcut.items() do
	if item:IsFake() then
		-- don't process these
	elseif item:ContainsNotes() then
		if item:Is('RestChord') then
			-- skip rest chords
		else
			-- for regular notes/chords, convert them to a muted RestChord with hidden rest
			local newItem = nwcItem.new('|RestChord')
			dur = item:Get('Dur')
			pos = item:Get('Pos')
			dur2 = item:Get('Dur2')
			opts = item:Get('Opts')
			stemDir = item:Get('Opts', 'Stem') or 'Up'
			stemDir = stemDir == 'Up' and 'Down' or 'Up'

			if not dur2 then -- don't convert split voice chords
				duration, dot = parseDur(dur)
				local newDur = noteDurBase[noteDurBaseRev[duration]+1] or '64th'
				if duration == '8th' then duration = '4th' end
				newItem:Provide('Dur2', duration)
				if dot then newItem:Provide('Dur2')[dot] = '' end
				newItem:Provide('Dur', newDur)
				newItem:Provide('Opts', opts)
				newItem:Provide('Opts').Stem = stemDir
				newItem:Provide('Opts').HideRest = ''
				newItem:Provide('Opts').Muted = ''
				newItem:Provide('Pos2', pos)
				item = newItem
				changeCount = changeCount + 1
				firstNote = not firstNote
				if firstNote then
					nwcut.writeline(nwcItem.new('|User|Tremolo.ms|Pos:0' .. (dot and '|TripletPlayback:Y' or '')))
					addCount = addCount + 1
				end
			end
		end
	end

	nwcut.writeline(item)
end

warnline('%s chord%s will be converted.', changeCount)
warnline('%s Tremolo.ms object%s will be added.', addCount)