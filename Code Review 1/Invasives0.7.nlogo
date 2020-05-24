; V0.1: World spawns with bees, invasive flowers, and native flowers.
; V0.2: Bees move and flowers produce nectar.
; V0.3: Bees have energy and replenish it by foraging.
; V0.4: Bees search for nearby flowers and keep track of ones they've visited. [Some bug-fixing for flower energy.]
; V0.5: Bees carry nectar between flowers.
; V0.6: Flowers can be pollinated and produce seeds.
; V0.7: Seasons happen - flowers bloom and start making seeds in Spring. Seeds spread in Fall and grow into flowers in Spring.

globals [
  ; Variables for the general environment
  year-length ; Number of ticks a year lasts
  spring ; Time at which spring/summer starts
  fall ; Time at which fall/winter starts

  ; Variables for native flowers (swamp loosestrife)
  native-color
  native-lifespan
  native-gametes ; Gametes available for pollination
  native-flower-time ; Time at which natives flower and sprout

  ; Variables for invasive flowers (purple loosestrife)
  invasive-color
  invasive-lifespan ; May live over 20 years
  invasive-gametes
  invasive-flower-time ; Time at which invasives flower and sprout

  ; Variables for bees
  bee-lifespan
  energy-from-nectar ; Energy bees receive from nectar
  bee-memory ; Maximum length of visited list
]

breed [bees bee]
breed [flowers flower] ; Single breed with a boolean to denote sub-breeds
breed [seeds seed] ; Single breed with a boolean to denote sub-breeds

turtles-own [
  age ; all turtles will age...
  lifespan ; ... and die of old age...
  energy ; ... or starvation
]

bees-own [
  pollen-type ; Type of pollen the bee is currently carrying
  visited ; List of most recently visited flowers
]

flowers-own [
  is-invasive ; boolean to determine whether this is native (swamp loosestrife) or invasive (purple loosestrife)
  nectar ; Amount of nectar available
  nectar-cap ; Maximum nectar capacity
  gametes ; Number of gametes available to produce seeds
]

seeds-own [
  is-invasive ; Determine species of flower this seed will grow into
]

; ------------------------------ GENERAL SETUP -----------------------------------
to setup
  clear-all

  ; Set global variables
  set year-length 100 ; Arbitrarily-chosen time period
  set spring year-length * 0.25
  set fall year-length * 0.75
  ; Natives
  set native-color magenta
  set native-lifespan year-length * 6 ; TODO research typical lifespans!
  set native-gametes 5
  set native-flower-time floor spring + year-length / 25
  ; Invasives
  set invasive-color violet
  set invasive-lifespan year-length * 5
  set invasive-gametes 10
  set invasive-flower-time floor spring - year-length / 25
  ; Bees
  set bee-lifespan year-length
  set energy-from-nectar 10
  set bee-memory 25

  ; Spawn bees and flowers
  set-default-shape bees "bee"
  set-default-shape flowers "flower"

  spawn ; Make all agents

  ; Make grass
  ask patches [
    set pcolor lime - 2
  ]

  reset-ticks
end

to spawn
  ; Spawn bees
  create-bees bee-pop [
    init-bees
  ]

  ; Spawn flowers of each type, using the relevant variables
  create-flowers native-pop [
    init-flowers false
  ]
  create-flowers invasive-pop [
    init-flowers true
  ]

  ; Scatter all turtles
  ask turtles [
    setxy random-xcor random-ycor
  ]
end

to init-bees
  ; Helper function to ensure all bees are hatched with reasonable values
  set age 0
  set energy energy-from-nectar
  set lifespan bee-lifespan

  set visited []
  set pollen-type "none"
end

to init-flowers [is-inv]
  ; Helper function to ensure all flowers are hatched with reasonable values
  set age 0
  set energy 1
  set nectar 0
  set nectar-cap energy-from-nectar * 2 ; TODO make a better global variable

  ifelse is-inv
  [
    set is-invasive true
    set color invasive-color
    set lifespan invasive-lifespan
    set gametes invasive-gametes
  ]
  [
    set is-invasive false
    set color native-color
    set lifespan native-lifespan
    set gametes native-gametes
  ]
end

to go
  if count flowers with [is-invasive = true] = 0 or count flowers with [is-invasive = false] = 0 [stop]
  move-bees
  grow-flowers

  check-death
  tick
end

; ------------------------------ BEE BEHAVIOR -----------------------------------
to move-bees
  ask bees [
    forage
    reproduce-bees
  ]
end

to forage
  let speed 1

  ; Get lists of flowers on both this patch and neighboring patches that haven't yet been visited
  let new-flowers-here find-new-flowers flowers-here visited
  let new-flowers-nearby find-new-flowers (flowers-on neighbors) visited

  ifelse any? new-flowers-here
  [
    ; Choose one of the flowers here to visit
    let flower-picked one-of new-flowers-here
    visit-flower flower-picked
  ]
  [
    ifelse any? new-flowers-nearby
    [
      ; Pick the closest flower that we haven't yet visited and go towards it
      let flower-picked min-one-of new-flowers-nearby [distancexy xcor ycor]
      if flower-picked != nobody [
        face flower-picked
        ; Fix potential issue where the bee could overshoot the flower picked by moving too fast
        set speed max (list 0.5 distancexy [xcor] of flower-picked [ycor] of flower-picked) ; TODO this should fix the above issue
      ]
    ]
    [
      set heading heading - 30 + random 60 ; Nothing nearby - move semi-randomly
    ]
  ]

  forward speed
  set energy energy - 1
end

to visit-flower [flower-to-visit]
  set visited lput flower-to-visit visited

  ; Remove the least-recently-visited flower if the bee runs out of "memory" (but make sure some flowers aren't on the list)
  if length visited > max (list bee-memory (count flowers / 2)) [
    set visited remove 0 visited
  ]

  ; Take nectar, if the flower has any
  if [nectar] of flower-to-visit > 0 [
    ; if flower has enough nectar, then take a full amount; otherwise, take all the nectar that's left
    let nectar-to-take max (list [nectar] of flower-to-visit energy-from-nectar)

    ; Move energy from the nectar to the bee
    set energy energy + nectar-to-take
    ask flower-to-visit [
      set nectar nectar - nectar-to-take
      pollinate [pollen-type] of myself
    ]
  ]

  ; Set which type of pollen was collected
  ifelse [is-invasive] of flower-to-visit
  [
    set pollen-type "invasive" ; TODO hard-coded values are bad!
  ]
  [
    set pollen-type "native"
  ]
end

to reproduce-bees
  ; Bees reproduce if they're old enough and have enough energy
  if energy > energy-from-nectar * 5 and age > lifespan / 10 [
    ; Bees start with a certain amount of energy
    set energy energy - energy-from-nectar
    hatch 1 [
      init-bees
    ]
  ]
end

to-report find-new-flowers [flowers-set flowers-visited]
  ; Find flowers in the given agentset that have not yet been visited
  report flowers-set with [not member? self flowers-visited]
end

; ------------------------------ FLOWER AND SEED BEHAVIOR -----------------------------------
to grow-flowers
  ask flowers [
    ; Get energy based on how many plants are nearby TODO depend on species
    let competing-neighbors neighbors with [any? flowers-here with [is-invasive] != [is-invasive] of myself]
    set energy energy + 10 - count competing-neighbors ; TODO change based on growing conditions
    ;(flowers-here with [is-invasive] = [is-invasive] of myself) didn't work

    ifelse day-of-year = fall or day-of-year = spring
    [
      ; Flower again on the first day of spring
      if day-of-year = spring and age >= year-length * 0.75 [
        ifelse is-invasive
        [set gametes invasive-gametes]
        [set gametes native-gametes]
      ]
      ; Stop flowering and spread all seeds on the first day of fall
      if day-of-year = fall [
        set gametes 0
        ask seeds-here [
          ; Choose a new patch within a certain radius
          ; This is more realistic because seeds can be spread over great distances
          let new-patch one-of patches in-radius (world-height / 2)
          setxy [pxcor] of new-patch [pycor] of new-patch
        ]
      ]
    ]
    [
      ; Grow all seeds, or pick the most successful seeds based on available energy to grow them
      let seeds-to-grow seeds-here
      if count seeds-to-grow > energy - 1 [
        set seeds-to-grow max-n-of (energy - 1) seeds-here [energy]
      ]

      ; Grow the seeds
      set energy energy - count seeds-to-grow
      ask seeds-to-grow [
        set energy energy + 1
      ]
    ]

    ; Flowers produce nectar, if possible
    if nectar < nectar-cap and energy > 2 [
      set nectar nectar + 1
      set energy energy - 1
    ]
  ]

  grow-seeds
end

to pollinate [type-of-pollen]
  if gametes > 0 [
    ; If the types match, this plant has been pollinated - produce a seed
    if (is-invasive and type-of-pollen = "invasive") or (not is-invasive and type-of-pollen = "native")
    [
      ; Hatch a seed in the same area as the
      hatch-seeds 1 [
        set shape "circle"
        set color brown - 1
        set size 0.25
        set is-invasive [is-invasive] of myself
        set energy 2
        set lifespan year-length * 2
      ]
    ]

    set gametes gametes - 1 ; Reduce number of available gametes
  ]
end

to grow-seeds
  ; Sprout seeds at the appropriate season each Spring
  ; Seeds have a 60-70% survival rate?
  ask seeds [
    ; Seeds use energy during Fall/Winter
    ;set energy energy - 0.1

    ; Check if it's time for the seed to sprout
    if is-invasive and day-of-year = invasive-flower-time [
      grow-from-seed true
    ]
    if not is-invasive and day-of-year = native-flower-time [
      grow-from-seed false
    ]
  ]
end

to grow-from-seed [is-inv]
  ; Make sure we're not trying to grow on top of any other flowers
  if not any? flowers-here [
    hatch-flowers 1 [
      set age 0
      set size 1
      init-flowers is-inv
      set energy [energy] of myself
    ]
  ]

  die
end

; ------------------------------ GENERAL TURTLE BEHAVIOR -----------------------------------
to check-death
  ask turtles [
    if energy < 1 [die]
    set age age + 1
    if age > lifespan [die]
  ]
end

to-report day-of-year
  report ticks mod year-length
end

to-report is-spring
  report day-of-year >= spring and day-of-year < fall
end

to-report is-fall
  report not is-spring
end

to-report season
  ifelse is-spring
  [report "Spring"]
  [report "Fall"]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
680
481
-1
-1
14.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
11
21
183
54
native-pop
native-pop
1
100
17.0
1
1
NIL
HORIZONTAL

SLIDER
10
63
182
96
invasive-pop
invasive-pop
1
100
17.0
1
1
NIL
HORIZONTAL

BUTTON
16
418
80
451
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
108
419
171
452
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
11
292
183
325
bee-pop
bee-pop
1
100
48.0
1
1
NIL
HORIZONTAL

PLOT
702
14
958
164
Populations
Time
Population
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Bees" 1.0 0 -16777216 true "" "plot count bees"
"Natives" 1.0 0 -5825686 true "" "plot count flowers with [is-invasive = false]"
"Invasives" 1.0 0 -8630108 true "" "plot count flowers with [is-invasive = true]"

PLOT
703
177
959
327
Pollen Being Carried
Time
Percent of Bees
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"None" 1.0 0 -16777216 true "" "plot count bees with [pollen-type = \"none\"] / count bees"
"Invasive" 1.0 0 -8630108 true "" "plot count bees with [pollen-type = \"invasive\"] / count bees"
"Native" 1.0 0 -5825686 true "" "plot count bees with [pollen-type = \"native\"] / count bees"

MONITOR
12
118
69
163
Season
season
0
1
11

MONITOR
94
118
180
163
Native Seeds
count seeds with [is-invasive = false]
0
1
11

MONITOR
94
172
191
217
Invasive Seeds
count seeds with [is-invasive = true]
0
1
11

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

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

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
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="native-pop">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bee-pop">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="invasive-pop">
      <value value="17"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
