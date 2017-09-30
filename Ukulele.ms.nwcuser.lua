-- Version 0.4

--[[----------------------------------------------------------------
This plugin draw a ukulele chord chart. A variety of notation is shown, including 
the chord name, open strings, fret position and optional finger numbers. 

When adding a new chord, the user can choose from 180 predefined chords
for either C tuning (soprano, concert and tenor) or G tuning (baritone)
ukuleles. Alternately, the user can choose "(Custom)" to create a chord
chart from scratch. The chord chart can be positioned vertical by 
changing the object marker position. 

When a chord is added to a staff, if there is another Ukulele object 
earlier in the staff, it will inherit the style and properties of that 
object.
@Name
The name of the chord. It is displayed using a font which displays 'b' 
and '#' as flat and sharp symbols. 
@Style
This determines the font style to be used for the chord name and label 
text. The possible values are Serif (MusikChordSerif, Times New Roman), 
Sans (MusikChordSans, Arial) and Swing (SwingChord, SwingText). The 
default setting is Serif. 
@Finger
The fingerings for each string, entered from low to high string, 
separate by spaces. Each position can be a number, indicating the fret 
position, or a 'o' or 'x' for open or unplayed strings, respectively. 
@Size
The size of the chord chart, ranging from 1.0 to 5.0. The default is 1.
@Frets
The number of fret positions to show in the chart, ranging from 1 to 10. 
The default is 4. 
@TopFret
The top fret number displayed in the chart. When the value is 1, the top 
border of the chart will be thicker. For larger values, the number of 
the first fingered fret will be displayed to the right of the chart. The 
default is 1. 
@Span
For playback, the number of notes/rests that the chord should span. A 
value of 0 will disable playback. The default is 0. 
@LabelOpen
Determines whether open strings will be labeled at the top of the chart. 
The default is true.
@FretPos
For charts where the top fret is greater than one, the fret position which
will be labeled to the right of the chart. The default is 1.
@NameOffset
The vertical offset for the chord name, ranging from -5.0 to 5.0. The default is 0.
--]]----------------------------------------------------------------

local standardChords = {
	['(Custom)'] = { '', 1, 1 },
	
	['A'] = { '2 1 o o', 1, 1 },
	['Am'] = { '2 o o o', 1, 1 },
	['Aaug'] = { '2 1 1 4', 1, 1 },
	['Adim'] = { '2 3 2 3', 1, 1 },
	['A7'] = { 'o 1 o o', 1, 1 },
	['Am7'] = { 'o o o o', 1, 1 },
	['Amaj7'] = { '1 1 o o', 1, 1 },
	['A6'] = { '2 1 2 o', 1, 1 },
	['Am6'] = { '2 o 2 o', 1, 1 },
	['Aadd9'] = { '2 1 o 2', 1, 1 },
	['Am9'] = { '2 o o 2', 1, 1 },
	['A9'] = { 'o 1 o 2', 1, 1 },
	['Asus2'] = { '2 4 5 2', 2, 3 },
	['Asus4'] = { '2 2 o o', 1, 1 },
	['A7sus4'] = { 'o 2 o o', 1, 1 },

	['A#'] = { '3 2 1 1', 1, 1 },
	['A#m'] = { '3 1 1 1', 1, 1 },
	['A#aug'] = { '3 2 2 1', 1, 1 },
	['A#dim'] = { '3 1 o 1', 1, 1 },
	['A#7'] = { '1 2 1 1', 1, 1 },
	['A#m7'] = { '1 1 1 1', 1, 1 },
	['A#maj7'] = { '3 2 1 o', 1, 1 },
	['A#6'] = { 'o 2 1 1', 1, 1 },
	['A#m6'] = { '3 1 3 1', 1, 1 },
	['A#add9'] = { '3 2 1 3', 1, 1 },
	['A#m9'] = { '3 1 1 3', 1, 1 },
	['A#9'] = { '3 2 4 3', 1, 1 },
	['A#sus2'] = { '3 o 1 1', 1, 1 },
	['A#sus4'] = { '3 3 1 1', 1, 1 },
	['A#7sus4'] = { '1 3 1 1', 1, 1 },

	['B'] = { '4 3 2 2', 1, 1 },
	['Bm'] = { '4 2 2 2', 1, 1 },
	['Baug'] = { '4 3 3 2', 1, 1 },
	['Bdim'] = { '4 2 1 2', 1, 1 },
	['B7'] = { '2 3 2 2', 1, 1 },
	['Bm7'] = { '2 2 2 2', 1, 1 },
	['Bmaj7'] = { '4 3 2 1', 1, 1 },
	['B6'] = { '1 3 2 2', 1, 1 },
	['Bm6'] = { '1 2 2 2', 1, 1 },
	['Badd9'] = { '4 3 2 4', 1, 1 },
	['Bm9'] = { '2 1 o 1', 1, 1 },
	['B9'] = { '4 3 5 4', 2, 3 },
	['Bsus2'] = { '4 1 2 2', 1, 1 },
	['Bsus4'] = { '4 4 2 2', 1, 1 },
	['B7sus4'] = { '2 4 2 2', 1, 1 },

	['C'] = { 'o o o 3', 1, 1 },
	['Cm'] = { 'o 3 3 3', 1, 1 },
	['Caug'] = { '1 o o 3', 1, 1 },
	['Cdim'] = { 'x 3 2 3', 1, 1 },
	['C7'] = { 'o o o 1', 1, 1 },
	['Cm7'] = { '3 3 3 3', 1, 1 },
	['Cmaj7'] = { 'o o o 2', 1, 1 },
	['C6'] = { 'o o o o', 1, 1 },
	['Cm6'] = { '2 3 3 3', 1, 1 },
	['Cadd9'] = { 'o 4 3 3', 1, 1 },
	['Cm9'] = { '5 3 3 5', 2, 3 },
	['C9'] = { 'o 2 o 1', 1, 1 },
	['Csus2'] = { 'o 2 3 3', 1, 1 },
	['Csus4'] = { 'o o 1 3', 1, 1 },
	['C7sus4'] = { 'o o 1 1', 1, 1 },

	['C#'] = { '1 1 1 4', 1, 1 },
	['C#m'] = { '1 4 4 4', 1, 1 },
	['C#aug'] = { '2 1 1 o', 1, 1 },
	['C#dim'] = { 'o 1 o 4', 1, 1 },
	['C#7'] = { '1 1 1 2', 1, 1 },
	['C#m7'] = { '1 1 o 2', 1, 1 },
	['C#maj7'] = { '1 1 1 3', 1, 1 },
	['C#6'] = { '1 1 1 1', 1, 1 },
	['C#m6'] = { '1 1 o 1', 1, 1 },
	['C#add9'] = { '1 3 1 4', 1, 1 },
	['C#m9'] = { '1 3 o 4', 1, 1 },
	['C#9'] = { '1 3 1 2', 1, 1 },
	['C#sus2'] = { '1 3 4 4', 1, 1 },
	['C#sus4'] = { '1 1 2 4', 1, 1 },
	['C#7sus4'] = { '1 1 2 2', 1, 1 },

	['D'] = { '2 2 2 o', 1, 1 },
	['Dm'] = { '2 2 1 o', 1, 1 },
	['Daug'] = { '3 2 2 1', 1, 1 },
	['Ddim'] = { '1 2 1 x', 1, 1 },
	['D7'] = { '2 2 2 3', 1, 1 },
	['Dm7'] = { '2 2 1 3', 1, 1 },
	['Dmaj7'] = { '2 2 2 4', 1, 1 },
	['D6'] = { '2 2 2 2', 1, 1 },
	['Dm6'] = { '2 2 1 2', 1, 1 },
	['Dadd9'] = { '2 4 2 5', 2, 3 },
	['Dm9'] = { '2 5 o 5', 2, 3 },
	['D9'] = { '2 4 2 3', 1, 1 },
	['Dsus2'] = { '2 2 o o', 1, 1 },
	['Dsus4'] = { 'o 2 3 o', 1, 1 },
	['D7sus4'] = { '2 2 3 3', 1, 1 },

	['D#'] = { 'o 3 3 1', 1, 1 },
	['D#m'] = { '3 3 2 1', 1, 1 },
	['D#aug'] = { 'o 3 3 2', 1, 1 },
	['D#dim'] = { '2 3 2 o', 1, 1 },
	['D#7'] = { '3 3 3 4', 1, 1 },
	['D#m7'] = { '3 3 2 4', 1, 1 },
	['D#maj7'] = { '3 3 3 5', 2, 3 },
	['D#6'] = { '3 3 3 3', 1, 1 },
	['D#m6'] = { '3 3 2 3', 1, 1 },
	['D#add9'] = { 'o 3 1 1', 1, 1 },
	['D#m9'] = { '3 5 x 6', 3, 4 },
	['D#9'] = { 'o 1 1 1', 1, 1 },
	['D#sus2'] = { '3 3 4 4', 1, 1 },
	['D#sus4'] = { '1 3 4 1', 1, 1 },
	['D#7sus4'] = { '3 3 4 4', 2, 3 },

	['E'] = { '1 4 o 2', 1, 1 },
	['Em'] = { 'o 4 3 2', 1, 1 },
	['Eaug'] = { '1 o o 3', 1, 1 },
	['Edim'] = { 'o 1 o 1', 1, 1 },
	['E7'] = { '1 2 o 2', 1, 1 },
	['Em7'] = { 'o 2 o 2', 1, 1 },
	['Emaj7'] = { '1 3 o 2', 1, 1 },
	['E6'] = { '4 4 4 4', 1, 1 },
	['Em6'] = { 'o 1 o 2', 1, 1 },
	['Eadd9'] = { '1 4 2 2', 1, 1 },
	['Em9'] = { 'o 4 2 2', 1, 1 },
	['E9'] = { '1 2 2 2', 1, 1 },
	['Esus2'] = { '4 4 2 2', 1, 1 },
	['Esus4'] = { '2 4 5 2', 2, 3 },
	['E7sus4'] = { '4 4 5 5', 2, 3 },

	['F'] = { '2 o 1 o', 1, 1 },
	['Fm'] = { '1 o 1 3', 1, 1 },
	['Faug'] = { '2 1 1 o', 1, 1 },
	['Fdim'] = { '1 2 1 2', 1, 1 },
	['F7'] = { '2 3 1 3', 1, 1 },
	['Fm7'] = { '1 3 1 3', 1, 1 },
	['Fmaj7'] = { '2 4 1 3', 1, 1 },
	['F6'] = { '2 2 1 3', 1, 1 },
	['Fm6'] = { '1 2 1 3', 1, 1 },
	['Fadd9'] = { 'o o 1 o', 1, 1 },
	['Fm9'] = { 'o 5 4 3', 2, 3 },
	['F9'] = { '2 3 3 3', 1, 1 },
	['Fsus2'] = { 'o o 1 3', 1, 1 },
	['Fsus4'] = { '3 o 1 1', 1, 1 },
	['F7sus4'] = { '5 5 6 6', 4, 5 },

	['F#'] = { '3 1 2 1', 1, 1 },
	['F#m'] = { '2 1 2 o', 1, 1 },
	['F#aug'] = { '3 2 2 1', 1, 1 },
	['F#dim'] = { '2 3 2 3', 1, 1 },
	['F#7'] = { '3 4 2 4', 1, 1 },
	['F#m7'] = { '2 4 2 4', 1, 1 },
	['F#maj7'] = { '3 5 2 4', 2, 3 },
	['F#6'] = { '3 3 2 4', 1, 1 },
	['F#m6'] = { '2 1 2 3', 1, 1 },
	['F#add9'] = { '1 1 2 1', 1, 1 },
	['F#m9'] = { '1 2 2 o', 1, 1 },
	['F#9'] = { '1 1 o 1', 1, 1 },
	['F#sus2'] = { '1 1 2 4', 1, 1 },
	['F#sus4'] = { '4 1 2 2', 1, 1 },
	['F#7sus4'] = { '6 6 7 7', 5, 5 },

	['G'] = { 'o 2 3 2', 1, 1 },
	['Gm'] = { 'o 2 3 1', 1, 1 },
	['Gaug'] = { 'o 3 3 2', 1, 1 },
	['Gdim'] = { 'o 1 3 1', 1, 1 },
	['G7'] = { 'o 2 1 2', 1, 1 },
	['Gm7'] = { 'o 2 1 1', 1, 1 },
	['Gmaj7'] = { 'o 2 2 2', 1, 1 },
	['G6'] = { 'o 2 o 2', 1, 1 },
	['Gm6'] = { 'o 2 o 1', 1, 1 },
	['Gadd9'] = { 'o 2 5 2', 2, 3 },
	['Gm9'] = { '2 2 3 1', 1, 1 },
	['G9'] = { '2 2 1 2', 1, 1 },
	['Gsus2'] = { 'o 2 3 o', 1, 1 },
	['Gsus4'] = { 'o 2 3 3', 1, 1 },
	['G7sus4'] = { 'o 2 1 3', 1, 1 },

	['G#'] = { '5 3 4 3', 2, 3 },
	['G#m'] = { '4 3 4 2', 1, 1 },
	['G#aug'] = { '1 o o 3', 1, 1 },
	['G#dim'] = { '1 2 1 2', 1, 1 },
	['G#7'] = { '1 3 2 3', 1, 1 },
	['G#m7'] = { '1 3 2 2', 1, 1 },
	['G#maj7'] = { '1 3 3 3', 1, 1 },
	['G#6'] = { '1 3 1 3', 1, 1 },
	['G#m6'] = { '4 5 4 6', 3, 3 },
	['G#add9'] = { '3 3 4 3', 1, 1 },
	['G#m9'] = { '3 3 4 2', 2, 3 },
	['G#9'] = { '3 3 2 3', 1, 1 },
	['G#sus2'] = { '1 3 4 1', 1, 1 },
	['G#sus4'] = { '1 3 4 4', 1, 1 },
	['G#7sus4'] = { '1 3 2 4', 1, 1 },
}

local baritoneChords = {
	['(Custom)'] = { '', 1, 1 },

	['A'] = { '2 2 2 o', 1, 1 },
	['Am'] = { '2 2 1 o', 1, 1 },
	['Aaug'] = { '3 2 2 1', 1, 1 },
	['Adim'] = { '1 2 1 2', 1, 1 },
	['A7'] = { '2 2 2 3', 1, 1 },
	['Am7'] = { '2 2 1 3', 1, 1 },
	['Amaj7'] = { '2 2 2 4', 1, 1 },
	['A6'] = { '2 2 2 2', 1, 1 },
	['Am6'] = { '2 2 1 2', 1, 1 },
	['Aadd9'] = { '2 4 2 5', 2, 3 },
	['Am9'] = { '2 5 o 5', 2, 3 },
	['A9'] = { '2 4 2 3', 1, 1 },
	['Asus2'] = { '2 2 o o', 1, 1 },
	['Asus4'] = { 'o 2 3 o', 1, 1 },
	['A7sus4'] = { '2 2 3 3', 1, 1 },

	['A#'] = { 'o 3 3 1', 1, 1 },
	['A#m'] = { '3 3 2 1', 1, 1 },
	['A#aug'] = { 'o 3 3 2', 1, 1 },
	['A#dim'] = { '2 3 2 3', 1, 1 },
	['A#7'] = { '3 3 3 4', 1, 1 },
	['A#m7'] = { '3 3 2 4', 1, 1 },
	['A#maj7'] = { '3 3 3 5', 2, 3 },
	['A#6'] = { '3 3 3 3', 1, 1 },
	['A#m6'] = { '3 o 2 1', 1, 1 },
	['A#add9'] = { 'o 3 1 1', 1, 1 },
	['A#m9'] = { '3 5 x 6', 3, 3 },
	['A#9'] = { 'o 1 1 1', 1, 1 },
	['A#sus2'] = { '3 3 1 1', 1, 1 },
	['A#sus4'] = { '1 3 4 1', 1, 1 },
	['A#7sus4'] = { '3 3 4 4', 2, 3 },

	['B'] = { '1 4 o 2', 1, 1 },
	['Bm'] = { 'o 4 3 2', 1, 1 },
	['Baug'] = { '1 o o 3', 1, 1 },
	['Bdim'] = { 'o 4 o 1', 1, 1 },
	['B7'] = { '1 2 o 2', 1, 1 },
	['Bm7'] = { 'o 2 o 2', 1, 1 },
	['Bmaj7'] = { '1 3 o 2', 1, 1 },
	['B6'] = { '4 4 4 4', 1, 1 },
	['Bm6'] = { 'o 1 o 2', 1, 1 },
	['Badd9'] = { '1 4 2 2', 1, 1 },
	['Bm9'] = { 'o 6 o 5', 4, 5 },
	['B9'] = { '1 2 2 2', 1, 1 },
	['Bsus2'] = { '4 4 2 2', 1, 1 },
	['Bsus4'] = { '2 4 5 2', 2, 3 },
	['B7sus4'] = { '4 4 5 5', 2, 3 },

	['C'] = { '2 o 1 o', 1, 1 },
	['Cm'] = { '1 o 1 3', 1, 1 },
	['Caug'] = { '2 1 1 o', 1, 1 },
	['Cdim'] = { '1 2 1 2', 1, 1 },
	['C7'] = { '2 3 1 3', 1, 1 },
	['Cm7'] = { '1 3 1 3', 1, 1 },
	['Cmaj7'] = { '2 4 1 3', 1, 1 },
	['C6'] = { '2 2 1 3', 1, 1 },
	['Cm6'] = { '1 2 1 3', 1, 1 },
	['Cadd9'] = { 'o o 1 o', 1, 1 },
	['Cm9'] = { 'o 5 4 3', 2, 3 },
	['C9'] = { '2 3 3 3', 1, 1 },
	['Csus2'] = { 'o o 1 3', 1, 1 },
	['Csus4'] = { '3 o 1 1', 1, 1 },
	['C7sus4'] = { '5 5 6 6', 4, 5 },

	['C#'] = { '3 1 2 1', 1, 1 },
	['C#m'] = { '2 1 2 o', 1, 1 },
	['C#aug'] = { '3 2 2 1', 1, 1 },
	['C#dim'] = { '2 3 2 3', 1, 1 },
	['C#7'] = { '3 4 2 4', 1, 1 },
	['C#m7'] = { '2 4 2 4', 1, 1 },
	['C#maj7'] = { '3 5 2 4', 2, 3 },
	['C#6'] = { '3 3 2 4', 1, 1 },
	['C#m6'] = { '2 1 2 3', 1, 1 },
	['C#add9'] = { '1 1 2 1', 1, 1 },
	['C#m9'] = { '1 2 2 o', 1, 1 },
	['C#9'] = { '1 1 o 1', 1, 1 },
	['C#sus2'] = { '1 1 2 4', 1, 1 },
	['C#sus4'] = { '4 1 2 2', 1, 1 },
	['C#7sus4'] = { '6 6 7 7', 6, 7 },

	['D'] = { 'o 2 3 2', 1, 1 },
	['Dm'] = { 'o 2 3 1', 1, 1 },
	['Daug'] = { 'o 3 3 2', 1, 1 },
	['Ddim'] = { 'o 1 o 1', 1, 1 },
	['D7'] = { 'o 2 1 2', 1, 1 },
	['Dm7'] = { 'o 2 1 1', 1, 1 },
	['Dmaj7'] = { 'o 2 2 2', 1, 1 },
	['D6'] = { 'o 2 o 2', 1, 1 },
	['Dm6'] = { 'o 2 o 1', 1, 1 },
	['Dadd9'] = { 'o 2 5 2', 2, 3 },
	['Dm9'] = { '2 2 3 1', 1, 1 },
	['D9'] = { '2 2 1 2', 1, 1 },
	['Dsus2'] = { 'o 2 3 o', 1, 1 },
	['Dsus4'] = { 'o 2 3 3', 1, 1 },
	['D7sus4'] = { 'o 2 1 3', 1, 1 },

	['D#'] = { '5 3 4 3', 2, 3 },
	['D#m'] = { '4 3 4 2', 1, 1 },
	['D#aug'] = { '2 o o 3', 1, 1 },
	['D#dim'] = { '1 2 1 2', 1, 1 },
	['D#7'] = { '1 3 2 3', 1, 1 },
	['D#m7'] = { '1 3 2 2', 1, 1 },
	['D#maj7'] = { '1 3 3 3', 1, 1 },
	['D#6'] = { '1 3 1 3', 1, 1 },
	['D#m6'] = { '4 5 4 6', 3, 3 },
	['D#add9'] = { '3 3 4 3', 1, 1 },
	['D#m9'] = { '3 3 4 2', 2, 3 },
	['D#9'] = { '3 3 2 3', 1, 1 },
	['D#sus2'] = { '1 3 4 1', 1, 1 },
	['D#sus4'] = { '1 3 4 4', 1, 1 },
	['D#7sus4'] = { '1 3 2 4', 1, 1 },

	['E'] = { '2 1 o o', 1, 1 },
	['Em'] = { '2 o o o', 1, 1 },
	['Eaug'] = { '2 1 1 4', 1, 1 },
	['Edim'] = { '2 3 2 3', 1, 1 },
	['E7'] = { 'o 1 o o', 1, 1 },
	['Em7'] = { 'o o o o', 1, 1 },
	['Emaj7'] = { '1 1 o o', 1, 1 },
	['E6'] = { '2 4 2 4', 1, 1 },
	['Em6'] = { '2 o 2 o', 1, 1 },
	['Eadd9'] = { '2 1 o 2', 1, 1 },
	['Em9'] = { '2 o o 2', 1, 1 },
	['E9'] = { 'o 1 o 2', 1, 1 },
	['Esus2'] = { '2 4 5 2', 2, 3 },
	['Esus4'] = { '2 2 o o', 1, 1 },
	['E7sus4'] = { 'o 2 o o', 1, 1 },

	['F'] = { '3 2 1 1', 1, 1 },
	['Fm'] = { '3 1 1 1', 1, 1 },
	['Faug'] = { '3 2 2 1', 1, 1 },
	['Fdim'] = { 'o 1 o 1', 1, 1 },
	['F7'] = { '1 2 1 1', 1, 1 },
	['Fm7'] = { '1 1 1 1', 1, 1 },
	['Fmaj7'] = { '3 2 1 o', 1, 1 },
	['F6'] = { 'o 2 1 1', 1, 1 },
	['Fm6'] = { '3 1 3 1', 1, 1 },
	['Fadd9'] = { '3 2 1 3', 1, 1 },
	['Fm9'] = { '3 1 1 3', 1, 1 },
	['F9'] = { '1 2 1 3', 1, 1 },
	['Fsus2'] = { '3 o 1 1', 1, 1 },
	['Fsus4'] = { '3 3 1 1', 1, 1 },
	['F7sus4'] = { '1 3 1 1', 1, 1 },

	['F#'] = { '4 3 2 2', 1, 1 },
	['F#m'] = { '4 2 2 2', 1, 1 },
	['F#aug'] = { 'o 3 3 2', 1, 1 },
	['F#dim'] = { '1 2 1 2', 1, 1 },
	['F#7'] = { '2 3 2 2', 1, 1 },
	['F#m7'] = { '2 2 2 2', 1, 1 },
	['F#maj7'] = { '3 3 2 2', 1, 1 },
	['F#6'] = { '1 3 2 2', 1, 1 },
	['F#m6'] = { '1 2 2 2', 1, 1 },
	['F#add9'] = { '4 3 2 4', 1, 1 },
	['F#m9'] = { '2 1 o 2', 1, 1 },
	['F#9'] = { '2 3 2 4', 1, 1 },
	['F#sus2'] = { '4 1 2 2', 1, 1 },
	['F#sus4'] = { '4 4 2 2', 1, 1 },
	['F#7sus4'] = { '2 4 2 2', 1, 1 },

	['G'] = { 'o o o 3', 1, 1 },
	['Gm'] = { 'o 3 3 3', 1, 1 },
	['Gaug'] = { '1 o o 3', 1, 1 },
	['Gdim'] = { '2 3 2 3', 1, 1 },
	['G7'] = { 'o o o 1', 1, 1 },
	['Gm7'] = { '3 3 3 3', 1, 1 },
	['Gmaj7'] = { 'o o o 2', 1, 1 },
	['G6'] = { 'o o o o', 1, 1 },
	['Gm6'] = { 'o 3 3 o', 1, 1 },
	['Gadd9'] = { 'o 2 o 3', 1, 1 },
	['Gm9'] = { '5 3 3 5', 2, 3 },
	['G9'] = { 'o 2 o 1', 1, 1 },
	['Gsus2'] = { 'o 2 3 3', 1, 1 },
	['Gsus4'] = { 'o o 1 3', 1, 1 },
	['G7sus4'] = { 'o o 1 1', 1, 1 },

	['G#'] = { '1 1 1 4', 1, 1 },
	['G#m'] = { '1 4 4 4', 1, 1 },
	['G#aug'] = { '2 1 1 o', 1, 1 },
	['G#dim'] = { 'o 1 o 1', 1, 1 },
	['G#7'] = { '1 1 1 2', 1, 1 },
	['G#m7'] = { '1 1 o 2', 1, 1 },
	['G#maj7'] = { '1 1 1 3', 1, 1 },
	['G#6'] = { '1 1 1 1', 1, 1 },
	['G#m6'] = { '1 4 4 1', 1, 1 },
	['G#add9'] = { '1 3 1 4', 1, 1 },
	['G#m9'] = { '1 3 o 4', 1, 1 },
	['G#9'] = { '1 3 1 2', 1, 1 },
	['G#sus2'] = { '1 3 4 4', 1, 1 },
	['G#sus4'] = { '1 1 2 4', 1, 1 },
	['G#7sus4'] = { '1 1 2 2', 1, 1 },
}

local allTonics = { 'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F', 'F#', 'Gb', 'G', 'Ab', 'A', 'A#', 'Bb', 'B' }
local allChords = { '', 'm', 'aug', 'dim', '7', 'm7', 'maj7', '6', 'm6', 'add9', 'm9', '9', 'sus2', 'sus4', '7sus4' }
local fsMap = {
	['Ab'] = 'G#', 
	['Bb'] = 'A#', 
	['Db'] = 'C#', 
	['Eb'] = 'D#', 
	['Gb'] = 'F#',
	['F#'] = 'Gb',
	['D#'] = 'Eb', 
	['C#'] = 'Db',
	['A#'] = 'Bb',
	['G#'] = 'Ab',
}

-- if nwcut then
-- 	local userObjTypeName = arg[1]
-- 	local score = nwcut.loadFile()
-- 	local staff, i1, i2 = score:getSelection()
-- 	local chord, chordName, o, commonChords
-- 	for i = 1, 2 do
-- 		commonChords = (i == 1) and standardChords or baritoneChords

-- 		for k1, v1 in ipairs({ 'A', 'Bb', 'B', 'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab' }) do
-- 			for k2, v2 in ipairs(allChords) do
-- 				chordName = v1 .. v2
-- 				chord = commonChords[chordName] and chordName or string.gsub(chordName, v1, fsMap[v1] or v1)
-- 				if commonChords[chord] then
-- 					o = nwcItem.new('User|' .. userObjTypeName)
-- 					o.Opts.Name = chordName
-- 					o.Opts.Finger = commonChords[chord][1]
-- 					o.Opts.TopFret = commonChords[chord][2]
-- 					o.Opts.FretPos = commonChords[chord][3]
-- 					o.Opts.Span = 1
-- 					o.Opts.Pos = 5
-- 					o.Opts.Size = 3
-- 					staff:add(o)
-- 					staff:add(nwcItem.new('|Rest|Dur:Half|Visibility:Never'))
-- 					staff:add(nwcItem.new(v2 == '7sus4' and '|Bar|SysBreak:Y' or '|Bar'))
-- 				end
-- 			end
-- 		end
-- 		staff:add(nwcItem.new('|Boundary|Style:NewSystem|NewPage:Y'))
-- 	end
-- 	score:setSelection(staff)
-- 	score:save()
-- 	return		
-- end

local userObjTypeName = ...
local idx = nwc.ntnidx
local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()

local styleListFull = {
    Serif = { 'MusikChordSerif', 1, 'Times New Roman', 1 },
    Sans = { 'MusikChordSans', 1, 'Arial', 1 },
    Swing = { 'SwingChord', 1.25, 'SwingText', 1.25 },
}
local styleList = { 'Serif', 'Sans', 'Swing' }
local strings = 4

local _spec = {
	{ id='Name', label='Chord Name', type='text', default='' },
    { id='Style', label='Font Style', type='enum', default=styleList[1], list=styleList },
	{ id='Finger', label='Fingerings', type='text', default='' },
	{ id='Size', label='Chart Size', type='float', default=1, min=0.5, max=5, step=.5 },
	{ id='Frets', label='Frets to Show', type='int', default=4, min=3, max=10 },
	{ id='TopFret', label='Top Fret', type='int', default=1, min=1 },
	{ id='Span', label='Note Span', type='int', default=0, min=0 },
	{ id='LabelOpen', label='Label Open Strings', type='bool', default=true },
	{ id='FretPos', label='Fret Number Position', type='int', default=1, min=1, max=10 },
	{ id='NameOffset', label='Chord Name Offset', type='float', default=0, min=-5, max=5, step=0.1 },
}

local tonics = {}
for k, v in pairs(standardChords) do
	local t, c
	if k ~= '(Custom)' then
		t, c = k:match('([A-G][b#]?)(.*)')
		if not tonics[t] then tonics[t] = true end
	end
end
for k, v in pairs(fsMap) do
	if not tonics[k] and tonics[v] then
		tonics[k] = true
	end
end
local tonicsList = ''
for k, v in ipairs(allTonics) do
	if tonics[v] then
		tonicsList = string.format('%s|%s', tonicsList, v)
		--tonicsList = tonicsList .. '|' .. v
	end
end
tonicsList = tonicsList .. '|(Custom)'

local priorParams = { 'Style', 'Size', 'Frets', 'Span', 'LabelOpen', 'Pos', 'NameOffset' }

local function _create(t)
	local tuning = nwcui.prompt('Select Instrument', '|Soprano, Concert, Tenor|Baritone')
	if not tuning then return end
	local commonChords = (tuning == 'Baritone') and baritoneChords or standardChords
	local chord
	local tonic = nwcui.prompt('Select Tonic', tonicsList)
	if not tonic then return end
	if tonic ~= '(Custom)' then
		local chordsList = ''
		for k, v in ipairs(allChords) do
			local ch = tonic .. v
			if commonChords[ch] or commonChords[(fsMap[tonic] or '') .. v] then
				chordsList = chordsList .. '|' .. ch
			end
		end
		chord = nwcui.prompt('Select Chord', chordsList)
		if not chord then return end
	else
		chord = tonic
	end
	t.Name = (chord == '(Custom)') and '' or chord
	if not commonChords[chord] then
		chord = string.gsub(chord, tonic, fsMap[tonic])
	end
	t.Finger = commonChords[chord][1]
	t.TopFret = commonChords[chord][2]
	t.FretPos = commonChords[chord][3]
	if idx:find('prior', 'user', userObjTypeName) then
		for k, s in ipairs(priorParams) do
			t[s] = idx:userProp(s)
		end
	end	
end

local function _spin(t, d)
	t.Span = t.Span + d
	t.Span = t.Span
end

local function hasTargetDuration()
	searchObj:reset()
	while searchObj:find('next') do
		if searchObj:userType() == userObjTypeName then return false end
		if searchObj:durationBase() then return true end
	end
	return false
end

local function _width(t)
	return hasTargetDuration() and 0 or strings * t.Size / nwcdraw.getAspectRatio()
end

local function _draw(t)
	local _, my = nwcdraw.getMicrons()
	local xyar = nwcdraw.getAspectRatio()
	local size, frets, topFret, span, labelOpen, fretPos, nameOffset = t.Size, t.Frets, t.TopFret, t.Span, t.LabelOpen, t.FretPos, t.NameOffset
	local penStyle = 'solid'
	local lineThickness = my * 0.125 * size
	local xspace, yspace = size / xyar, size
	local height = yspace * frets

	local userwidth = user:width()
	local hasTarget = hasTargetDuration()
	local width = xspace * (strings - 1)
	user:find('next', 'duration')
	local offset = hasTarget and user:xyRight() or -userwidth
	local xoffset = (offset - width) / 2
    local slf = styleListFull[t.Style]
    nwc.hasTypeface(slf[1])
    nwc.hasTypeface(slf[3])
	local chordFontFace = slf[1]
	local chordFontSize = 5 * size * slf[2]
	local fingeringFontFace = slf[3]
	local fingeringFontSize = slf[4] * 1.5 * size
	local dotXSize = 0.375 * xspace
	nwcdraw.setPen(penStyle, lineThickness)
	for i = 0, strings - 1 do
		nwcdraw.line(i * xspace + xoffset, 0, i * xspace + xoffset, height)
	end
	for i = 0, frets do
		nwcdraw.line(xoffset, i * yspace, xoffset + width, i * yspace)
	end
	nwcdraw.moveTo(offset/2, height + (1.75 + nameOffset) * yspace)
	nwcdraw.setFont(chordFontFace, chordFontSize)
	nwcdraw.alignText('baseline', 'center')
	nwcdraw.text(t.Name)
	nwcdraw.setFont(fingeringFontFace, fingeringFontSize)
	local stringNum = 1
	local x = xoffset
	local lowFret = 99
	local highFret = 0
	for f in t.Finger:gmatch('%S+') do
		if stringNum > strings then break end
		if tonumber(f) then
			lowFret = math.min(f, lowFret)
			highFret = math.max(f, highFret)
		end
	end
	if topFret == 1 and highFret > frets then
		topFret = math.max(highFret - frets + 1, 1)
	end
	local height2 = (topFret == 1) and height + .25 * yspace or height
	if topFret == 1 then
		nwcdraw.moveTo(xoffset, height)
		nwcdraw.beginPath()
		nwcdraw.line(xoffset, height2)
		nwcdraw.line(xoffset+width, height2)
		nwcdraw.line(xoffset+width, height)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end	
	for f in t.Finger:gmatch('%S+') do
		if stringNum > strings then break end
		if tonumber(f) then
			local y = yspace * (frets - f + topFret - .5)
			if y > 0 and y < height then
				nwcdraw.moveTo(x, y)
				nwcdraw.beginPath()
				nwcdraw.ellipse(dotXSize)
				nwcdraw.endPath()
			end
		else
			if labelOpen or f == 'x' then
				nwcdraw.moveTo(x, height2 + yspace * .25)
				nwcdraw.text(f)
			end
		end
		stringNum = stringNum + 1
		x = x + xspace
	end
	if topFret > 1 then
		if topFret <= lowFret then
			nwcdraw.alignText('baseline', 'left')
			nwcdraw.moveTo(xoffset + width + .5 * xspace, height - (fretPos - topFret + 1) * yspace)
			nwcdraw.text(fretPos)
		end
	end
	if hasTarget then
		user:reset()
		local spanned = 0
		while (spanned < span) and user:find('next', 'duration') do
			spanned = spanned + 1
		end
		if spanned > 0 then
			local w = user:xyRight()
			nwcdraw.moveTo(0)
			nwcdraw.hintline(w)
		end
	end
end

return {
--	nwcut = { ['Test'] = 'ClipText' },
	spec = _spec,
	create = _create,
	width = _width,
	spin = _spin,
	draw = _draw,
}
