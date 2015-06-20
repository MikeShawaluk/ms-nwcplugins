local user = nwcdraw.user

local symbols = {
	['Half'] = 'F',
	['Quarter'] = 'G',
	['Eighth'] = 'H',
}
local dot = 'z'
local tempoBase = nwc.txt.TempoBase

local function drawTextIf(str, str2)
	if str ~= '' then nwcdraw.text(str2 or str) end
end

local spec_Tempo = {
	Tempo = {type='text', default='60'},
	PreText = {type='text', default=''},
	PostText = {type='text', default=''},
	Font = {type='enum', default='StaffBold', list=nwc.txt.TextExpressionFonts },
	Base = {type='enum', default='Quarter', list=tempoBase },
}

local function create_Tempo(t)
	t.Tempo = t.Tempo
	t.PreText = t.PreText
	t.PostText = t.PostText
	t.Font = t.Font
	t.Base = t.Base
end

local function spin_Tempo(t,dir)
	local v = t.Base
	local j
	for i,s in ipairs(tempoBase) do
		if s == v then j = i end
	end
	j = j and math.min(math.max(j + dir,1),#tempoBase)
	t.Base = tempoBase[j]
end

local function draw_Tempo(t)
	local tempo = t.Tempo
	local preText = t.PreText
	local postText = t.PostText
	local font = t.Font
	local base = t.Base

	local note = base:match('(%S+)')
	local dotted = base:match('( Dotted)')	

	nwcdraw.setFontClass(font)
	nwcdraw.alignText('baseline', 'left')

	drawTextIf(preText)
	drawTextIf(preText, ' (')
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.text(symbols[note])
	if dotted then
		nwcdraw.setFontClass('StaffCueSymbols')
		nwcdraw.text(dot)
	end
	nwcdraw.setFontClass(font)
	nwcdraw.text(' = ' .. t.Tempo)
	drawTextIf(preText, ') ')
	drawTextIf(postText)
end

return {
	spec = spec_Tempo,
	create = create_Tempo,
	spin = spin_Tempo,
	draw = draw_Tempo
}