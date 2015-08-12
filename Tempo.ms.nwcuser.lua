-- Version 0.9

--[[-----------------------------------------------------------------------------------------
This plugin creates a visual tempo marking with several enhancements:

 - The tempo value can be general text, rather than just numbers
 - The text font can be specified
 - Both leading and trailing text can be included
 - A text scale factor can be applied

Note that this tempo marking is visual only, and does not change the tempo of the score. A regular
tempo marking with Visibility set to Never may be used in conjunction with this object.
@Base
The base note duration. It has the same values as regular Noteworthy tempos, from Eighth through Half Dotted. The default setting is Quarter.

The note durations may be cycled by selecting the object and pressing the + or - keys.
@Tempo
The tempo value to be displayed to the right of the "=". This can be numeric or text; examples are "ca. 60", "60-70", "ludicrous".
@PreText
Leading text for the tempo. If this is non-blank, the tempo base note and value will be surrounded by " (" and ") ". The default value is an empty string.
@PostText
Trailing text for the tempo. The default value is an empty string.
@Font
Font to be used for the leading and trailing text. It can be any of the Noteworthy system fonts.
@Scale
The scale factor for the tempo text and symbols. This is a value from 5% to 400%, and the default setting is 100%.
--]]-----------------------------------------------------------------------------------------

local symbols = { Half = 'F', Quarter = 'G', Eighth = 'H' }
local dot = 'z'
local tempoBase = nwc.txt.TempoBase
local tbRev = {}

for i,s in ipairs(tempoBase) do
	tbRev[s] = i
end


local function drawTextIf(str, str2)
	if str ~= '' then nwcdraw.text(str2 or str) end
end

local spec_Tempo = {
	{ id='Base', label='Base', type='enum', default='Quarter', list=tempoBase },
	{ id='Tempo', label='Tempo', type='text', default='ca. 60' },
	{ id='PreText', label='Leading Text', type='text', default='' },
	{ id='PostText', label='Trailing Text', type='text', default='' },
	{ id='Font', label='Font', type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
    { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=100 },
}

local function spin_Tempo(t,dir)
	t.Base = tempoBase[math.min(math.max(tbRev[t.Base]+dir, 1), #tempoBase)]
end

local function setFontClassScaled(font, scale)
	nwcdraw.setFontClass(font)
	nwcdraw.setFontSize(nwcdraw.getFontSize()*scale)
end

local function draw_Tempo(t)
	local tempo = t.Tempo
	local preText = t.PreText
	local postText = t.PostText
	local font = t.Font
	local base = t.Base
    local scale = t.Scale / 100

	local note = base:match('(%S+)')
	local dotted = base:match('( Dotted)')	

	setFontClassScaled(font, scale)
	nwcdraw.alignText('baseline', 'left')

	drawTextIf(preText)
	drawTextIf(preText, ' (')
	setFontClassScaled('StaffSymbols', scale)
	nwcdraw.text(symbols[note])
	if dotted then
		setFontClassScaled('StaffCueSymbols', scale)
		nwcdraw.text(dot)
	end
	setFontClassScaled(font, scale)
	nwcdraw.text(' = ' .. tempo)
	drawTextIf(preText, ') ')
	drawTextIf(postText)
end

return {
	spec = spec_Tempo,
	spin = spin_Tempo,
	draw = draw_Tempo
}