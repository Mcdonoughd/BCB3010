;Neuro Simulation by Daniel McDonough

globals[]
breed[transmitters transmitter]
breed[receptors receptor]
breed[gproteins gprotein]
breed[aproteins aprotein]
breed[bgproteins bgprotein]
breed[pkas pka]
breed[plcs plc]
breed[camps camp]
breed[channels channel]
breed[ions ion]
receptors-own[is-activated? waited-time is-burned?]
transmitters-own[is-used? life-time]
gproteins-own[]
bgproteins-own[]
plcs-own[has-ATP? charge-time]
aproteins-own[has-GTP?]
camps-own[life-time]
pkas-own[has-cAMP? is-used? binded-time]
channels-own[is-phospho? open-time]
ions-own[life-time]
turtles-own[]
patches-own[]

to setup
  clear-all ;clear all agents and patches
  make-plc
  make-cellMem
  make-transmitter
  make-receptor
  make-gprotein
  make-pka
  make-smoothER
  make-channel
  make-ions
  reset-ticks
end

to go
  spawn-transmitter
  spawn-ions
  ask gproteins[
    move-gproteins
  ]
  ask receptors [
    receptor-check-collision
  ]
  ask transmitters[
    move-transmitters
  ]
  if any? aproteins[
    ask aproteins[
      move-aproteins
    ]
  ]
  if any? bgproteins[
    ask bgproteins[
      move-bgproteins
    ]
  ]
  if any? pkas[
    ask pkas[
      move-pka
    ]
  ]
  if any? plcs[
    ask plcs[
      charge-plc
    ]
  ]
  if any? camps[
    ask camps[
      move-camp
    ]
  ]
  if any? ions[
    ask ions[
      move-ions
    ]

  ]
  tick
end

;;--------------------------------------Cell Membrane FUNCTIONS ------------------------------------------------------------------------

;Make Cell Membrane
to make-cellMem
  ; create the cell membrane horizontally
  ask patches with [pycor = 18]
      [ set pcolor violet ]
end



;--------------------------------------Transmitter FUNCTIONS ------------------------------------------------------------------------



;Make Transmitters function
to make-transmitter
  create-transmitters num-transmitters [
    setxy (random(30) - random(30)) 25
    set color yellow
    set shape "circle"
    set is-used? false
    set life-time 0
  ]
end

;Spawn Transmitter at random rate
to spawn-transmitter
  let randomnum random(100)
  if randomnum < transmitter-spawn-rate[
    create-transmitters 1 [
      setxy (random(30) - random(30)) 25
      set color yellow
      set shape "circle"
      set is-used? false
      set life-time 0
    ]
  ]
end

;Move Transmitters function
to move-transmitters
  ;if used then dont move
  ifelse life-time <= transmitter-life-time[
    ;show is-used?
    ifelse is-used?[   ;do nothing
    ]
    [
      ifelse patch-ahead 1 = nobody or [pcolor] of patch-ahead 1 = violet
      [ lt random-float 360 ]   ;; We see a violet patch in front of us. Turn a random amount.
      [ fd 1 ]                  ;; Otherwise, it is safe to move forward.
      set life-time life-time + 1
    ]
  ]
  [
    die
  ]
  ;else move
end



;--------------------------------------Receptor FUNCTIONS ------------------------------------------------------------------------

;Make receptor
to make-receptor
  create-receptors num-receptors[
    setxy (random(30) - random(30)) 18
    set shape "receptor_inactive_shape"
    set color red
    set size 2
    set heading 360
    set is-activated? false
    set waited-time 0
    set is-burned? false
  ]
end

;check collision for activation factor
to receptor-check-collision
  ;check if receptor is burned
  ifelse is-burned? = true[
    ;do nothing
  ][
    ;check if receptor is activated
    ifelse is-activated?
    [
      ;check if its waited longer than the set wait time
      ifelse waited-time > receptor-activated-time
      [
        ;if so reset all vars
        set is-activated? false
        set color color - 2
        set shape "receptor_inactive_shape"
        set waited-time 0
        check-burn
        ;get the transmitter to not constantly enter the receptor
        if any? transmitters-on patch-ahead 1 ;this if statement is just for if wait time is 0
        [
          ask one-of transmitters-on patch-ahead 1 [
            ;reset transmitter vars
            set is-used? false
            ;move them go 1 step at random angle
            set heading random(45) - random(-45)
            fd 1
          ]
        ]
      ]
      ;else check if gprotein is below the receptor
      [
        if any? gproteins-on patch-ahead -1 [
          ;if so split gprotein
          ask one-of gproteins-on patch-ahead -1 [
            split-gprotein
          ]
          ;check-burn
        ]
        ;increment the time waited and
        set waited-time waited-time + 1
      ]
    ]
    [ ;if not active check if it should be
      if any? transmitters-on patch-ahead 1
      [
        ;activate the receptor
        set color color + 2
        set shape "receptor_active_shape"
        set is-activated? true
        ;set the transmitter to being used
        ask one-of transmitters-on patch-ahead 1 [
          set is-used? true
        ]
        ;check if any Gproteins are directly under the receptor
        if any? gproteins-on patch-ahead -1 [
          ;if so split the protein
          ask one-of gproteins-on patch-ahead -1 [
            split-gprotein
          ]
        ]
      ]
    ]
  ]
end


;checks if receptor should be burned
to check-burn
  let randomnum random(100)
  if randomnum < receptor-burn-rate[
    set is-burned? true
    set color black
    set is-activated? false
  ]
end




;-------------------------------------- G Proteins FUNCTIONS ------------------------------------------------------------------------
;Makes a G protien
to make-gprotein
  create-gproteins num-g[
    setxy (random(30) - random(30)) 17
    let randomnum random(100)
    ifelse randomnum < 50
    [
      set heading 90
    ]
    [
      set heading 270
    ]
    set shape "molecule water"
    set color green
    set size 3
  ]
end

;Moves G proteins
to move-gproteins
  ; set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + 180
    fd 1
  ]
  [ fd 1 ]
end

;Splits G protein into Alpha and Beta-Gamma Subsections
to split-gprotein
  ;get gproteins x n y coords
  let xcoor xcor
  let ycoor ycor
  ;let g-heading heading
  ;"split into alpha and beta-gamma proteins"

  ask patch-here[
    sprout-bgproteins 1 [
      ;set is-recharged? false
      setxy xcoor - 1 ycoor
      set size 3
      set shape "molecule hydrogen"
      set color orange
      set heading -90
    ]
    sprout-aproteins 1 [
      setxy xcoor + 1 ycoor
      set size 3
      set shape "molecule oxygen"
      set color blue
      set heading 90
      set has-GTP? true ;say it obtains GTP instantly upon split
    ]
  ]
  die
end


;-------------------------------------- Beta-Gamma Protein FUNCTIONS ------------------------------------------------------------------------

;Moves BG proteins
to move-bgproteins
  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + 180
    fd 1
  ]
  [ fd 1 ]
end


;-------------------------------------- Alpha protein FUNCTIONS ------------------------------------------------------------------------

;Moves a proteins
to move-aproteins
  ;if Alpha has GTP
  ifelse has-GTP? = true[
    ;check for PLC

    ;check if alpha protein is next to PLC
    if any? plcs-on patch-here[
      ;if so attempt to charge the plc
      ask one-of plcs-on patch-here[
        if has-ATP? = true[
          convert-camp
        ]
      ]
    ]
  ]
  [
    ;else check for Beta Gamma
    ;check if alpha protein is next to PLC
    if any? bgproteins-on patch-here[
      ;if so remove gtp for gdp
      ask one-of bgproteins-on patch-here[
        die
      ]
      ask patch-here[
        sprout-gproteins 1[
          setxy pxcor pycor
          let randomnum random(100)
          ifelse randomnum < 50
          [
            set heading 90
          ]
          [
            set heading 270
          ]
          set shape "molecule water"
          set color green
          set size 3
        ]
      ]
      die
    ]
  ]
  ;Do movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + 180
    fd 1
  ]
  [fd 1]

end


;--------------------------------------Adenyl Cyclase (PLC) FUNCTIONS ------------------------------------------------------------------------

;Make PLC function
to make-plc
  create-plcs num-plc [
    setxy (random(30) - random(30)) 17
    set color orange
    set shape "triangle 2"
    set size 2
    set charge-time 0
    set has-ATP? false
  ]
end

;Converts PLC's ATP to cAMP when an Alpha protein in on site
to convert-camp
  ;check for aproteins
  if any? aproteins-on patch-here[
    ask one-of aproteins-on patch-here[
      if has-GTP? = true [
        set has-GTP? false
        set color green
        let xcoor xcor
        let ycoor ycor
        ;make a cAMP
        ask patch-here[
          sprout-camps 1 [
            setxy xcoor ycoor
            set shape "circle"
            set color blue
            set life-time 0
          ]
        ]
        ask one-of plcs-on patch-here[
          ;set remove atp
          set has-ATP? false
          set color orange
          set charge-time 0
        ]
      ]
    ]
  ]

end

;on each step check if plc is charged
to charge-plc
  ifelse plc-charge-time <= charge-time[
    set has-ATP? true
    set color blue
    ;set charge-time 0
    ;convert-camp
  ]
  [
    set charge-time charge-time + 1
  ]
end


;-------------------------------------- cAMP FUNCTIONS ------------------------------------------------------------------------
;move cAMP
to move-camp
  ifelse life-time < camp-life-time[
    ;check bounceables
    ifelse patch-ahead 1 = nobody or [pcolor] of patch-ahead 1 = violet or [pcolor] of patch-ahead 1 = pink
    [ lt random-float 360 ]   ;; We see a violet patch in front of us. Turn a random amount.
    [  fd 1 ]
    set life-time life-time + 1
  ]
  [
    die
  ]
end


;-------------------------------------- PKA FUNCTIONS ------------------------------------------------------------------------
;moves the PKA
to move-pka
  ;check if pka is currently in use
  ifelse is-used? = false[
    ;if pka doesnt have camp then
    ifelse has-cAMP? = false[
      ;look for camp
      ifelse any? camps-on patch-here[
        ;if on same patch as cAMP
        set has-cAMP? true ;set to true
        set color color + 2 ;change color
        ask one-of camps-on patch-here[
          die  ;kill cAMP
        ]
      ]
      ;if no cAMP here then...
      [
        ;Move away if edge, cell mem, or smooth er
        ifelse patch-ahead 1 = nobody or [pcolor] of patch-ahead 1 = violet or [pcolor] of patch-ahead 1 = pink
        [lt random-float 360];turn
        [ ifelse any? channels-on patch-ahead 1[
          lt random-float 360
          ][fd 1]
        ]
      ]
    ]
    ;if cAMP then...
    [ifelse patch-ahead 1 = nobody[
      lt random-float 360;turn
    ][
      ifelse any? channels-on patch-ahead 1[
        set is-used? true
        ask one-of channels-on patch-ahead 1[
          make-open
        ]
      ]
      [
        ;still check for boundaries
        ifelse patch-ahead 1 = nobody or [pcolor] of patch-ahead 1 = violet or [pcolor] of patch-ahead 1 = pink
        [ lt random-float 360 ]   ; We see a violet patch in front of us. Turn a random amount.
        [ fd 1 ]
      ]
      ]
    ]
  ]
  ;if in use then check how long it has binded
  [
    ifelse binded-time >= channel-activated-time
    [ let ycoor ycor - 1
      let xcoor xcor
      ;close the channel
      ask channels-on patch-ahead 1 [
        if shape = "square 2"[
          make-close
        ]
      ]
      ;if times up resset vars and send it flying
      set is-used? false
      ;lt random-float 360
      set heading heading + 180
      fd 1
      set has-cAMP? false;
      set color violet
      set binded-time 0
    ]
    ;increase binding time
    [set binded-time binded-time + 1]
  ]
end

;Make PKA function
to make-pka
  create-pkas num-pka [
    setxy (random(30) - random(30)) (random(10) - random(10))
    set color violet
    set shape "box"
    set size 2
    set has-cAMP? false
    set binded-time 0
    set is-used? false
  ]
end


;-------------------------------------- Smooth ER FUNCTIONS ------------------------------------------------------------------------

;Make Smooth ER
to make-smoothER
  ; create the smoothER
  ask patches with [pycor = -28]
      [ set pcolor pink ]
end

;-------------------------------------- Channel FUNCTIONS ------------------------------------------------------------------------

;Make Channels
to make-channel
  ; create the cell membrane horizontally
  create-channels num-channels[
    setxy (random(30) - random(30)) -28
    set shape "square"
    ask patch-here[
      set pcolor pink
    ]
    set color red + 2
    set size 2
    set heading 0
  ]
end

;makes the Channel Open!
to make-open
  set shape "square 2"
  ask patch-here[
    set pcolor black
  ]
end

;makes the Channel CLOSE!
to make-close
  set shape "square"
  ask patch-here[
    set pcolor pink
  ]
end

;--------------------------------------IONS FUNCTIONS ------------------------------------------------------------------------

;Make IONS function
to make-ions
  create-ions num-ions [
    setxy (random(30) - random(30)) -30
    set color white
    set shape "circle"
    set life-time 0
  ]
end

;Spawn Ions
to spawn-ions
  let randomnum random(100)
  if randomnum < ion-spawn-rate[
    create-ions 1 [
      setxy (random(30) - random(30)) -30
      set color white
      set shape "circle"
      set life-time 0
    ]
  ]
end


;Move ions function
to move-ions

  ifelse life-time < ion-life-time[
    ifelse patch-ahead 1 = nobody or [pcolor] of patch-ahead 1 = violet or [pcolor] of patch-ahead 1 = pink
    [ lt random-float 360 ]   ; We see a violet patch in front of us. Turn a random amount.
    [ fd 1 ]
    set life-time life-time + 1
  ]
  [
    die
  ]
  ; Otherwise, it is safe to move forward.
  ;else move
end
@#$#@#$#@
GRAPHICS-WINDOW
5
99
413
508
-1
-1
6.154
1
10
1
1
1
0
0
0
1
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
15
22
79
55
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
82
22
145
55
GO!
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1000
22
1154
55
num-transmitters
num-transmitters
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
686
22
855
55
num-receptors
num-receptors
0
30
19.0
1
1
NIL
HORIZONTAL

SLIDER
685
57
856
90
receptor-activated-time
receptor-activated-time
0
50
50.0
1
1
NIL
HORIZONTAL

SLIDER
500
22
682
55
num-g
num-g
0
30
14.0
1
1
NIL
HORIZONTAL

SLIDER
340
22
492
55
num-plc
num-plc
0
100
9.0
1
1
NIL
HORIZONTAL

SLIDER
340
58
493
91
plc-charge-time
plc-charge-time
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
499
57
682
90
camp-life-time
camp-life-time
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
421
137
1336
507
Number of Agents
Time
# of Agents
0.0
2000.0
0.0
50.0
true
true
"" ""
PENS
"Transmitters" 1.0 0 -987046 true "" "plot count transmitters"
"Active Receptors" 1.0 0 -1604481 true "" "plot count receptors with [is-activated? = true]"
"cAMP" 1.0 0 -13345367 true "" "plot count camps"
" Ions out of Smooth ER" 1.0 0 -12345184 true "" "plot count ions with [ycor > -18]"
"Open Channels" 1.0 0 -5825686 true "" "plot count channels with [shape = \"square 2\"]"
"PKA w/ cAMP" 1.0 0 -13840069 true "" "plot count pkas with [has-cAMP? = true]"
"PLC w/ ATP" 1.0 0 -955883 true "" "plot count plcs with [has-ATP? = true]"
"Burnt Receptors" 1.0 0 -16448764 true "" "plot count receptors with [is-burned? = true]"

SLIDER
999
57
1154
90
transmitter-spawn-rate
transmitter-spawn-rate
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
999
91
1154
124
transmitter-life-time
transmitter-life-time
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
499
89
683
122
num-pka
num-pka
0
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
152
22
337
55
num-channels
num-channels
0
100
46.0
1
1
NIL
HORIZONTAL

SLIDER
153
55
338
88
channel-activated-time
channel-activated-time
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
860
21
997
54
num-ions
num-ions
0
100
56.0
1
1
NIL
HORIZONTAL

SLIDER
860
96
994
129
ion-life-time
ion-life-time
0
100
29.0
1
1
NIL
HORIZONTAL

SLIDER
860
58
996
91
ion-spawn-rate
ion-spawn-rate
0
100
29.0
1
1
NIL
HORIZONTAL

SLIDER
685
93
857
126
receptor-burn-rate
receptor-burn-rate
0
100
30.0
1
1
NIL
HORIZONTAL

TEXTBOX
186
10
336
28
Channel Variables
11
0.0
1

TEXTBOX
353
10
503
28
PLC Variables
11
0.0
1

TEXTBOX
515
10
665
28
Gprotein, cAMP, PKA Variables\n
11
0.0
1

TEXTBOX
694
10
844
28
Receptor Variables
11
0.0
1

TEXTBOX
866
10
1016
28
Ion Variables
11
0.0
1

TEXTBOX
1013
10
1163
28
Transmitter Variables
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

a_protein_shape
false
0
Circle -7500403 true true 150 200 150

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bg_protein_shape
false
0
Circle -7500403 true true 255 100 200
Circle -7500403 true true 150 200 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

g_protein_shape
false
0
Circle -7500403 true true 255 100 200
Circle -7500403 true true 150 200 150

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

molecule hydrogen
true
0
Circle -1 true false 78 108 84
Circle -16777216 false false 78 108 84

molecule oxygen
true
0
Circle -7500403 true true 30 75 150
Circle -16777216 false false 30 75 150

molecule water
true
0
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -1 true false 33 63 84
Circle -16777216 false false 33 63 84

moon
false
0
Polygon -7500403 true true 175 7 83 36 25 108 27 186 79 250 134 271 205 274 281 239 207 233 152 216 113 185 104 132 110 77 132 51

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

receptor_active_shape
false
0
Polygon -7500403 true true 0 0 150 75 255 0 255 255 150 175 0 255

receptor_inactive_shape
false
0
Polygon -7500403 true true 0 0 150 75 255 0 255 255 0 255

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
