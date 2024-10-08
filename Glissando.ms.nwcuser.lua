-- Version 2.8

--[[----------------------------------------------------------------
This will draw a glissando line between two notes, with optional text above the line. If either of the notes is a chord, the bottom notehead
of that chord will be the starting or ending point of the line.
@Pen
Specifies the type for lines: solid, dot, dash or wavy. The default setting is solid.
@Text
The text to appear above the glissando line, drawn in the StaffItalic system font. The default setting is "gliss."
@Scale
The scale factor for the text above the glissando line. This is a value from 5% to 400%, and the default setting is 75%.

The text scale factor can be incremented/decremented by selecting the object and pressing the + or - keys.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@Weight
This will adjust the weight (thickness) of both straight and wavy line types. The range of values is 0.0 to 5.0, where 1 is the standard line weight. The default setting is 1.
@Playback
This can be used to activate different optional forms of play back.
The glissando duration is the duration of the left side note alone, disregarding possible ties.
Playback is best when both the left and right side notes are muted.

For PitchBend, the staff/instrument definition should establish a 24 semitone pitch-bend. For best results, the note pair should also be within ±24 semitones.
For the other playback modes only a single note plays glissando.
@GlissDelay
This can delay the start of the glissando for a certain percent of the note duration. Default is 0%, maximum is 99%.
@EndNoteShift
This will adjust the pitch of the ending note upwards or downwards by the specified number of semitones. It is used when a clef change or transposition (i.e. 8va or 8va bassa) occurs between the starting and ending note of the glissando. A value of ±20 would be used for changes between treble and bass clefs. The range of values  is -100 to 100. The default setting is 0.
@PitchBendPeriod
Delay in tics (NWC uses 384 tics/quarter) between PitchBend updates.
Too big the value and the glissato gets rough; too small the value and the MIDI channel can be overloaded, in special mode with the original HW.
In a sense, it is the reverse of the "Sweep Resolution" of the MPC.

--]]----------------------------------------------------------------

local userObjTypeName = ...
local priorNote = nwc.drawpos.new()
local nextNote = nwc.drawpos.new()
local scanidx = nwc.ntnidx.new()
local priorNoteidx = nwc.ntnidx.new()
local nextNoteidx = nwc.ntnidx.new()
local idx = nwc.ntnidx
local user = nwcdraw.user
local currentClef = 'Treble'
local currentOctaveShift = 'None'

local lineStyles = { 'solid', 'dot', 'dash', 'wavy' }
local squig = '~'
local showBoxes = { edit=true }
local pbNeutral = 0x02000 -- This is also the pitch-bend MIDI range

local PlaybackStyle = {'None', 'Chromatic', 'WhiteKeys', 'BlackKeys', 'PitchBend', 'Harp'}
local KeyIntervals = {
  None = {},
  Chromatic = {0,1,2,3,4,5,6,7,8,9,10,11},
  WhiteKeys = {0,2,4,5,7,9,11},
  BlackKeys = {1,3,6,8,10},
  PitchBend = {24},
  Harp      = {0,1,2,3,4,5,6}
}

local _spec = {
  { id='Pen', label='Line Style', type='enum', default=lineStyles[1], list=lineStyles },
  { id='Text', label='Text', type='text', default='gliss.' },
  { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=75 },
  { id='StartOffsetX', label='Start Offset X, Y', type='float', step=0.1, min=-100, max=100, default=0 },
  { id='StartOffsetY', label='', type='float', step=0.1, min=-100, max=100, default=0 },
  { id='EndOffsetX', label='End Offset X, Y', type='float', step=0.1, min=-100, max=100, default=0 },
  { id='EndOffsetY', label='', type='float', step=0.1, min=-100, max=100, default=0 },
  { id='Weight', label='Line Weight', type='float', default=1, min=0, max=5, step=0.1 },
  { id='Playback', label='Pla&yback', type='enum', default=PlaybackStyle[1], list=PlaybackStyle },
  { id='GlissDelay', label='Gliss &Delay (%)', type='int', min=-400, max=99, step=1, default=0 },
  { id='EndNoteShift', label='End Note Shift', type='int', min=-100, max=100, step=1, default=0 },
  { id='PitchBendPeriod', label='Pitch Bend Period', type='int', min=1, max=100, step=1, default=2 }
}

local _spec2 = {}

for k, v in ipairs(_spec) do
  _spec2[v.id] = k
end

local function _create(t)
  t.Class = 'Span'
end

local function _audit(t)
  if t.Style then
    if (t.Style == 'Wavy') then t.Pen = 'wavy' end
    t.Style = nil
  end
  t.ap = nil

  local barSpan = (idx:find('span', 1) or idx:find('last')) and idx:find('prior','bar') and (idx:indexOffset() > 0)
  t.Class = barSpan and 'Span' or 'Standard'
end

local function box(x, y, ap, p)
  local m = (ap == p) and 'strokeandfill' or 'stroke'
  nwcdraw.setPen('solid', 100)
  nwcdraw.moveTo(x, y)
  nwcdraw.beginPath()
  nwcdraw.roundRect(0.2)
  nwcdraw.endPath(m)
end

local stopItems = { Note=1, Chord=1, RestChord=1, Rest=-1, Bar=-1, RestMultiBar=-1, Boundary=-1 }

local function hasPriorSourceNote(idx)
  while idx:find('prior') do
    local d = stopItems[idx:objType()]
    if d then return d > 0 end
  end
  return false
end

local function drawGliss(x1, y1, x2, y2, drawText, t)
  local xyar = nwcdraw.getAspectRatio()
  local _, my = nwcdraw.getMicrons()
  local pen, text, weight = t.Pen, t.Text, t.Weight

  local angle = math.deg(math.atan2((y2-y1), (x2-x1)*xyar))

  if drawText and text ~= '' then
    nwcdraw.alignText('bottom', 'center')
    nwcdraw.setFontClass('StaffItalic')
    nwcdraw.setFontSize(nwcdraw.getFontSize()*t.Scale*.01)
    nwcdraw.moveTo((x1+x2)*.5, (y1+y2)*.5)
    nwcdraw.text(text, angle)
  end
  if pen ~= 'wavy' then
    if weight ~= 0 then
      nwcdraw.setPen(pen, my*.3*weight)
      nwcdraw.line(x1, y1, x2, y2)
    end
  else
    nwcdraw.alignText('baseline', 'left')
    nwcdraw.setFontClass('StaffSymbols')
    nwcdraw.setFontSize(nwcdraw.getFontSize()*weight)
    local w = nwcdraw.calcTextSize(squig)
    local len = math.sqrt((y2-y1)^2 + ((x2-x1)*xyar)^2)
    local count = math.floor(len/w/xyar)
    nwcdraw.moveTo(x1, y1-1)
    nwcdraw.text(string.rep(squig, count), angle)
  end
end

local function _draw(t)
  local atSpanFront = not user:isAutoInsert()
  local atSpanEnd = nextNoteidx:find('span', 1)

  if not hasPriorSourceNote(priorNoteidx) or not atSpanEnd then
    if not atSpanFront then return 0 end
    local x, y = -4, 4
    if not nwcdraw.isDrawing() then return -x end
    drawGliss(x, 0, 0, y, true, t)
    return
  end
  if not nwcdraw.isDrawing() then return 0 end

  local xo, yo = .25, .5

  nextNote:find(nextNoteidx)
  priorNote:find(priorNoteidx)

  if not atSpanEnd then nextNoteidx:find('last') end
  local x1 = atSpanFront and priorNote:xyRight() + xo + t.StartOffsetX or -1.25
  local y1 = priorNoteidx:notePos(1)

  local x2 = (atSpanEnd and nextNote:xyAnchor() + t.EndOffsetX or 0) - xo
  local y2 = nextNoteidx:notePos(1) or 0

  local s = y1>y2 and 1 or y1<y2 and -1 or 0
  y1 = y1 - yo*s + t.StartOffsetY
  y2 = y2 + yo*s + t.EndOffsetY

  drawGliss(x1, y1, x2, y2, atSpanFront, t)

  if t.ap and showBoxes[nwcdraw.getTarget()] then
    local ap = tonumber(t.ap)
    box(x1, y1, ap, 1)
    box(x2, y2, ap, 2)
  end
end

local function GlissOctaveNearestNextInterval(t, inOctaveSemiTone)
  for i, v in ipairs(t) do
    if v >= inOctaveSemiTone then return i - 1 end
  end
  return 0
end

local function CountGlissIntervals(k, v)
  local o = math.floor(v/12)
  local i = v % 12

  return #k*o + GlissOctaveNearestNextInterval(k, i)
end

local function GlissNoteFromInterval(k, v)
  local opitches = #k
  local o = math.floor(v/opitches)
  local i = v % opitches

  return 12*o + k[i + 1]
end

local function isStandAloneMutedNote(n)
  return n:isMute() and not n:isTieIn() and not n:isTieOut()
end

-- Function partOfNextPlayGliss has a side effect on idx, so be careful when using it
local function partOfNextPlayGliss(n)
  if not idx:find(n) or not idx:find('next', 'noteOrRest') then return false end
  return idx:find('prior', 'user', userObjTypeName, 'Playback') and (idx:indexOffset() > 0)
end

local Octave = {['Octave Up'] = 12, ['None'] = 0, ['Octave Down'] = -12}

local ClefChangeTable = {
 ['Treble']    ={['Treble']=0, ['Bass']=-20,['Alto']=-10,['Tenor']=-13,['Percussion']=-20},
 ['Bass']      ={['Treble']=20,['Bass']=0,  ['Alto']=10, ['Tenor']=7,  ['Percussion']=0},
 ['Alto']      ={['Treble']=10,['Bass']=-10,['Alto']=0,  ['Tenor']=-3, ['Percussion']=-10},
 ['Tenor']     ={['Treble']=13,['Bass']=-7, ['Alto']=3,  ['Tenor']=0,  ['Percussion']=-7},
 ['Percussion']={['Treble']=20,['Bass']=0,  ['Alto']=10, ['Tenor']=7,  ['Percussion']=0}}

-- This is to fix the playing environment that ignores clef changes
local function clefChangeShift()
  local shift = 0 -- default
  scanidx:reset()
  if scanidx:find('next', 'Clef') and (scanidx:indexOffset() < nextNoteidx:indexOffset()) then
    local newClef = scanidx:objProp('Type')
    local newOctaveShift = scanidx:objProp('OctaveShift')
    if (newClef ~= currentClef) or (newOctaveShift ~= currentOctaveShift) then
      shift = ClefChangeTable[currentClef][newClef] - Octave[currentOctaveShift] + Octave[newOctaveShift]
    end
  end
  return shift
end

local function setPitchBend(Start, pbValue)
  local Value = pbValue + pbNeutral
  local dLSB = math.floor(Value % 128)
  local dMSB = math.floor(Value/128)
  nwcplay.midi(Start, 'pitchBend', dLSB, dMSB)
end

local function sanityCheck(x)
  return math.max(x, 1) - 1
end

-- Fraction of note duration based on articulation
local function getDurationFraction(n)
  local durationFraction = 0.83
  if n:isStaccatissimo() then
    durationFraction = 0.28
  else
    if n:isStaccato() then
      durationFraction = 0.38
    else
      if n:isTenuto() or n:isSlurOut() or n:isTieOut() then
        durationFraction = 1
      end
    end
  end
  return durationFraction
end

-- Duration of note, including ties and articulation, as tenuto and rest after glissando
local function getTiedDuration(n)
  local duration = 0
  local count = 0
  local restDuration = 0
  local start = n:sppOffset()
  local lastNoteStart = start
  while n:isTieOut() and n:find('next', 'noteOrRest') do
    count = count + 1
    if n:objType() ~= 'Rest' then
      -- Full note duration (tenuto)
      duration = duration + (n:sppOffset() - lastNoteStart)
      lastNoteStart = n:sppOffset()
    end
  end
  if n:find('next', 'noteOrRest') or n:find('next') then
    -- Last note of the tie chain (articulated)
    count = count + 1
    duration = duration + math.floor((n:sppOffset() - lastNoteStart)*getDurationFraction(n))
    lastNoteStart = n:sppOffset()
  end
  if n:objType() == 'Rest' then
    -- Rest following glissando
    if n:find('next', 'noteOrRest') or n:find('next') then
      count = count + 1
      restDuration = sanityCheck(n:sppOffset() - lastNoteStart)
    end
  end
  -- Restore n
  while count > 0 do
    n:find('prior', 'noteOrRest')
    count = count - 1
  end
  --       Articulated                Tenuto
  return sanityCheck(duration), sanityCheck(lastNoteStart - start), restDuration
end

local function replaceAccidental(note, newAcc)
  local start, finish, acc, remain = string.find(note, "^([#bnxv]?)(.*)")
  return newAcc..remain
end

-- This is the note pos number required by 'noteAt'
local function absoluteNotePos(note)
  local start, finish, accidental, notePos = string.find(note, "^([#bnxv]?)(-?%d+)")
  return tonumber(notePos), accidental
end

local function _play(t)
  local playbackt = t.Playback
  local playback = KeyIntervals[playbackt]
  if #playback < 1 then return end

  if not (hasPriorSourceNote(priorNoteidx) and nextNoteidx:find('span', 1)) then return end

  -- This is to correct a bug in NWC that ignores tie-propagated accidentals
  local accidentals = {}
  for j = 1, priorNoteidx:noteCount() do
    local absNotePos, accidental = absoluteNotePos(priorNoteidx:notePitchPos(j))
    scanidx:reset()
    local done
    repeat
      done = true
      -- N.B. The first time scanidx will point to priorNoteidx
      if scanidx:find('prior', 'noteAt', absNotePos) then
        for i = 1, scanidx:noteCount() do
          local pos, acc = absoluteNotePos(scanidx:notePitchPos(i))
          if pos == absNotePos then
            accidental = acc
            done = not scanidx:isTieIn(i)
            break
          end
        end
      end
    until done
    table.insert(accidentals, accidental)
  end

  -- Using only notePitchPos, the accidentals inherited
  -- from a tie from a previous bar are ignored
  local v1 = nwcplay.getNoteNumber(replaceAccidental(priorNoteidx:notePitchPos(1), accidentals[1]))
  if not v1 then return end

  currentClef = nwcplay.getClef()
  -- currentOctaveShift = nwcplay.???  Information not available: using default
  local targetShift = t.EndNoteShift + clefChangeShift()
  local v2 = nwcplay.getNoteNumber(nextNoteidx:notePitchPos(1)) + targetShift
  if (not v2) or (v2 == v1) then return end
  local step = (v1 < v2) and 1 or -1

  -- The gliss duration is by default the full duration of priorNote (source)
  local startSPP = priorNoteidx:sppOffset()
  local glissDur = -startSPP
  if glissDur == 0 then
    glissDur = 48 -- tics -> 1/32
  end
  local noteVel = nwcplay.getNoteVelocity()
  local SweepDelaySPP = math.floor((t.GlissDelay*glissDur)/100)

  -----------------------------------------------------------------------------
  if playbackt == 'PitchBend' then
    -- This technique requires that the part has a dedicated
    -- MIDI channel and a 24 semitone pitch-bend range
    local pbRange = 24 -- Semitones
    step = step*math.min(math.abs(v1 - v2), pbRange)
    local pbStart = 0 -- Start the sweep at the source pitch
    local pbEnd = ((pbNeutral - 1)*step)/pbRange
    local playingMidiNotes = {}

    -- If the source note/chord stands alone (is not tied) and is muted,
    -- then the pitch-bend can be applied against the target pitch
    if isStandAloneMutedNote(priorNoteidx) then
      local noteDur = glissDur
      -- Reverse the sweep direction
      pbStart = -pbEnd
      pbEnd = 0 -- Finish with pb = 0 at the target pitch

      -- If both source and target are muted
      -- then the target is played legato to the glissando
      if nextNoteidx:isMute() and not partOfNextPlayGliss(nextNoteidx) then
        -- Add the duration of the target note that will be played with stable pitch
        noteDur = noteDur + getTiedDuration(nextNoteidx)
      end

      -- Play the source muted note/chord transposed to target pitch
      local delta = v2 - v1
      for j = 1, priorNoteidx:noteCount() do
      	if nextNoteidx:isTieOut(j) then
      	  -- Let the tied note stopping this one
          nwcplay.midi(startSPP, 'noteOn', nwcplay.getNoteNumber(priorNoteidx:notePitchPos(j)) + delta, noteVel)
        else
          table.insert(playingMidiNotes,
                       nwcplay.getNoteNumber(priorNoteidx:notePitchPos(j)) + delta)
          -- If a source note has a corresponding note in the target (n.b. the target
          -- notes intervals are irrelevent, the source intervals are always used)
          -- it will sound the whole time, otherwise the note will stop playing
          -- at the end of glissando
          nwcplay.note(startSPP, nextNoteidx:notePitchPos(j) and noteDur or glissDur, playingMidiNotes[j], noteVel)
        end
      end
    else -- Pitch-bend applied against the source pitch
      for j = 1, priorNoteidx:noteCount() do
      	local note = nwcplay.getNoteNumber(replaceAccidental(priorNoteidx:notePitchPos(j), accidentals[j]))
        table.insert(playingMidiNotes, note)
        -- Let's play the not tied muted source notes
        if priorNoteidx:isMute() and not priorNoteidx:isTieIn(j) then
          nwcplay.note(startSPP, glissDur, note, noteVel)
        end
      end
    end

    -- Pitch-bend glissando
    setPitchBend(startSPP, pbStart)
     -- N.B. NWC uses 384 tics/quarter, i.e. 24 tics per 1/64
    local ticsStep = t.PitchBendPeriod
    startSPP = startSPP + ticsStep + SweepDelaySPP
    glissDur = glissDur - SweepDelaySPP
    local pbChanges = math.floor((glissDur/ticsStep) - 1)
    local pbStep = (pbEnd - pbStart)/pbChanges
    for i = 1, pbChanges do
      pbStart = pbStart + pbStep
      setPitchBend(startSPP, math.floor(pbStart))
      startSPP = startSPP + ticsStep
    end

    local resetSPP = startSPP
    if priorNoteidx:isTieIn() and priorNoteidx:isMute() then
      if nextNoteidx:isMute() then
        -- If the target is muted then keep playing for its duration
      	local duration, fullDuration, restDuration = getTiedDuration(nextNoteidx)
        startSPP = startSPP + duration
        -- To avoid glitch sounds reset the pitch-bend as late as possible
        -- If the glissato is followed by a rest we can delay the reset more
        resetSPP = resetSPP + fullDuration + restDuration
      end
      -- Stop the sound for it will not stop by itself
      for j = 1, #playingMidiNotes do
        -- nwcplay.midi(startSPP, 'noteOff', playingMidiNotes[j])
        -- N.B. NWC always use this instead
        nwcplay.midi(startSPP, 'noteOn', playingMidiNotes[j], 0)
      end
    end

    -- Warning: when pbEnd is not 0, depending on the release time of the
    -- voice there will be a nasty sound when the pitch-bend returns to 0
    setPitchBend(resetSPP, 0) -- Restore neutral pitch-bend
  else ------------------------------------------------------------------------
    -- Not pitch-bend: assumes it's a single note, not a chord
    -- In case of a chord, only the lowest note plays glissando
    local interval1
    local interval2
    if playbackt == 'Harp' then
      interval1 = priorNoteidx:notePos(1)
      interval2 = nextNoteidx:notePos(1)
    else
      interval1 = CountGlissIntervals(playback, v1)
      interval2 = CountGlissIntervals(playback, v2)
    end
    local deltav = math.abs(interval1 - interval2)
    if nextNoteidx:isGrace() and nextNoteidx:isMute() then
      -- Let's play a bit that note too
      deltav = deltav + 1
    end
    local deltaSPP
    if (SweepDelaySPP == 0) and not priorNoteidx:isTieIn() then
      -- Let the source note sound a bit
      deltaSPP = glissDur/deltav
      SweepDelaySPP = deltaSPP
    else
      deltaSPP = (glissDur - SweepDelaySPP)/deltav
    end
    if deltaSPP < 1 then return end -- Too fast
    if priorNoteidx:isMute() and not priorNoteidx:isTieIn() then
      -- Play the source note
      nwcplay.note(startSPP, SweepDelaySPP - 1, v1, noteVel)
    else
      -- Truncate the source note to have time for glissando
      -- N.B. There will be another note off event later that will be ignored
      nwcplay.midi(startSPP + SweepDelaySPP - 1, 'noteOn', v1, 0)
    end

    -- Play the glissando
    startSPP = startSPP + SweepDelaySPP
    for i = 2, deltav do
      interval1 = interval1 + step
      local notepitch
      if playbackt == 'Harp' then
    	notepitch = nwcplay.getNoteNumber(interval1)
      else
        notepitch = GlissNoteFromInterval(playback, interval1)
      end
      nwcplay.note(startSPP, deltaSPP, notepitch, noteVel)
      startSPP = startSPP + deltaSPP
    end

    -- If muted, play the target notes (chords allowed)
    if nextNoteidx:isMute() then
      local noteDur = getTiedDuration(nextNoteidx)
      for j = 1, nextNoteidx:noteCount() do
        nwcplay.note(startSPP, noteDur, nwcplay.getNoteNumber(nextNoteidx:notePitchPos(j)) + targetShift, noteVel)
      end
    end
  end
end

local paramTable = {
  { _spec2.StartOffsetX, _spec2.StartOffsetY },
  { _spec2.EndOffsetX, _spec2.EndOffsetY },
}

local function toggleParam(t)
  local ap = tonumber(t.ap) or #paramTable
  ap = ap % #paramTable + 1
  t.ap = ap
end

local function updateParam(t, p, dir)
  local s = _spec[p]
  local x = s.id
  t[x] = t[x] + dir*s.step
  t[x] = t[x]
end

local function updateActiveParam(t, n, dir)
  local ap = tonumber(t.ap)
  if ap then
    updateParam(t, paramTable[ap][n], dir)
  end
end

local function updateEnds(t, dir)
  updateParam(t, _spec2.StartOffsetY, dir)
  updateParam(t, _spec2.EndOffsetY, dir)
end

local skip = { Text=true }

local function defaultAllParams(t)
  for k, s in ipairs(_spec) do
    if not skip[s.id] then t[s.id] = t[s.default] end
  end
end

local function defaultActiveParam(t)
  local ap = tonumber(t.ap)
  if ap then
    for i = 1, 2 do
      local s = _spec[paramTable[ap][i]]
      t[s.id] = s.default
    end
  end
end

local function toggleEnum(t, p)
  local s = _spec[p]
  local q = {}
  for k, v in ipairs(s.list) do
    q[v] = k
  end
  t[s.id] = s.list[q[t[s.id]] + 1]
end

local charTable = {
  ['+'] = { updateParam, _spec2.Scale, 1 },
  ['-'] = { updateParam, _spec2.Scale, -1 },
  ['7'] = { updateParam, _spec2.Weight, 1 },
  ['1'] = { updateParam, _spec2.Weight, -1 },
  ['8'] = { updateActiveParam, 2, 1 },
  ['2'] = { updateActiveParam, 2, -1 },
  ['6'] = { updateActiveParam, 1, 1 },
  ['4'] = { updateActiveParam, 1, -1 },
  ['5'] = { toggleParam },
  ['9'] = { updateEnds, 1 },
  ['3'] = { updateEnds, -1 },
  ['0'] = { defaultActiveParam },
  ['Z'] = { defaultAllParams },
  ['.'] = { toggleEnum, _spec2.Pen },
}

local function _onChar(t, c)
  local ptr = charTable[string.char(c)]
  if not ptr then return false end
  ptr[1](t, ptr[2], ptr[3])
  return true
end

return {
  create = _create,
  spec = _spec,
  audit = _audit,
  onChar = _onChar,
  draw = _draw,
  width = _draw,
  span = function() return 1 end,
  play = _play,
}
