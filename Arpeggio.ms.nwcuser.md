# Arpeggio.ms.nwcuser.md

This object draws an arpeggio for a chord. It uses no special fonts. It will draw the arpeggio marking and optionally play the chord in arpeggio style.

To add an arpeggio to a chord, insert the object immediately before the chord which you wish to ornament. The arpeggio will automatically cover the range of notes in the chord, and will update automatically if the chord is moved or modified.

The following parameters control the appearance and operation of the arpeggio:

| Parameter | Description |
| - | - |
| `Offset` | Used to increase or decrease the distance between the arpeggio and its chord. Value is between -5 and 5 notehead widths; default value is 0. |
| `Side` | Side of the chord (left, right) on which the arpeggio marking will be drawn. Default value is left. |
| `MarkerExtend` | Controls whether the user object marker vertical position extends the arpeggio above or below the notes of the chord. This can be used to 'stretch' the arpeggio to extend to an adjacent staff. Note that this does not affect the arpeggio's playback. Default value is false. |
| `Dir` | Determines the direction of the arpeggio (up, down). When the direction is down, adds an arrowhead to the bottom of the arpeggio. This option also controls the arpeggio's playback (see below). Default value is up. |
| `ForceArrow` | Used to force the appearance of an arrowhead for both up and down arpeggios. Default value is false. |

The following options only pertain to playback:

| Parameter | Description |
| - | - |
| `Play` | Determines whether arpeggio playback is enabled. Default value is true. Note that the chord following the arpeggio mark must also be muted for playback to occur. |
| `Speed` | Speed at which the arpeggio is played, Range of values is 1 (very slow) to 128 (very fast), with a default value of 32. The playback speed is proportional to the score's tempo. |
| `Anticipated` | When set to true, specifies that the arpeggio should anticipate (precede) the chord, so that the final arpeggiated note occurs on the chord's beat position. When set to false, a 'normal' arpeggio will occur, in which the first note of the arpeggiated chord is on the beat. |
