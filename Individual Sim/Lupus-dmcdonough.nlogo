;Lupus Simulation by Daniel McDonough 4/27/18
;global variables
globals[total-cell-death-rate max-cell-death-rate]

;Link between dcells and healthy cells
directed-link-breed [sents sent]
;link between acell and
directed-link-breed [tags tag]

;breeds
breed[bodycells bodycell]
breed[bcells bcell]
breed[tcells tcell]
breed[dcells dcell]
breed[antibodies antibody]
breed[auto-antibodies auto-antibody]
breed[DNAs DNA]
breed[afls afl];antifroulamb
breed[acells acell];autoreactive T-cells

;agent variables
bodycells-own[is-necrosis?] ;body cells go undner necrosis
bcells-own[is-activated? plasma-cell? production-timer has-afl? is-autoreactive?]  ;do they have antigen? ;is the bcell currently a plasma cell  ;check the roduction timer ;is antifrolumab bound to it? ;was it initiated by a mature dcell?
tcells-own[is-activated? has-afl?] ;do they have antigen? ;is antifrolumab bound to it?
dcells-own[is-activated? is-matured?] ;do they have antigen? ;is dcell mature?
antibodies-own[is-activated?] ;do they have antigen? ;was it initiated by a mature dcell?
auto-antibodies-own[is-activated? is-killing? killing-timer] ;do they have antigen?
acells-own[is-killing? killing-timer] ;is the agent currently killing a healthy cell ;for how long should a cell spend killing

turtles-own[lifetime] ;all agents have lifetime


;------------       SETUP       -----------------------------;
to setup
  clear-all ;clear all agents and patches
  make-bodycells ;make body cells
  make-bcells ;make bcells
  make-tcells ;make tcells
  make-dcells ;make denditic cells
  set-total-cell-death-rate ;calculate total cell death rate from base input and predisposition
  reset-ticks
end

;------------       GO           -----------------------------;
to go

  spawn-cells ;spawn cells
  spawn-tcells ;spawn tcells
  spawn-bcells ;spawn bcells
  spawn-dcells ;spawn dcells

  ;inject-afl

  ;dna on tick
  ask DNAs[
    move-DNA ;move dna
  ]

  ;tcell on tick
  ask tcells[
    move-tcells ;move tcells

    ]

  ;bcell on tick
  ask bcells[
    move-bcells ;move bcells
    ]
 ;body cell on tick
  ask bodycells[
    necrosis ;body cells under go necrosis
  ]
  ;dcell on tick
  ask dcells[
    move-dcells ;move dcells
  ]
  ;antibodies on tick
  ask antibodies[
   move-antibodies ;move antibodies
  ]
   ;auto-antibodies on tick
  ask auto-antibodies[
   move-auto-antibodies ;move antibodies
  ]

  ;autoreactive cells on tick
  ask acells[
    move-acell ;move acell
  ]

  ;anifrolumab on tick
  ask afls[

    move-afl ;move anifrolumab
  ]

  kill-old-cells ;kill old cells that overstayed their welcome

  tick
  if count(bodycells) = 0 [
  stop
  ]
end



;------------      Kill Old Cells    -----------------------------;
to kill-old-cells
ask dcells[
if lifetime > dcell-lifetime [
die
]
]
ask tcells[
if lifetime > tcell-lifetime [
die
]
]
ask bcells[
if lifetime > bcell-lifetime [
die
]
]
ask antibodies[
if lifetime > antibody-lifetime [
die
]
]
ask auto-antibodies[
if lifetime > antibody-lifetime [
die
]
]
ask dnas[
if lifetime > antigen-lifetime [
die
]
]
ask afls[
if lifetime > anifrolumab-lifetime [
die
]
]
ask acells[
if lifetime > tcell-lifetime [
die
]
]
ask turtles[
set lifetime lifetime + 1
]
end



;------------      Body Cells    -----------------------------;

;Make bodycells
to make-bodycells
  ask patches with [pycor > 10] ;all patches above 10
  [
    sprout-bodycells 1 [
      set lifetime 0
      set color white
      set shape "square"
      set is-necrosis? false
    ]
  ]
end


;Determines if the Cell should be exploding and if they are increase size
to necrosis
  ifelse is-necrosis? = true[
    ;if exploding
    emit-sent ;re-recruit Dcells
    set size size + (cell-growth-rate / 100) ;grow

    if size > 2[ ;if big enough then
      spawn-DNA  ;release antigen
      die ;explode
    ]
  ];if not dieing have a change to die
  [
    let randnum random(max-cell-death-rate) ;random number
    if randnum < base-cell-death-rate[
      set is-necrosis? true ;is now dieing
      set color grey ;set color
      emit-sent ;recruit dcells
    ]
  ]
end

;spawns new cells
to spawn-cells
  ;ask proper patches if there are no body cells there
  ask patches with [ pycor > 10 ]
  [
  ;get empty space
    if not any? bodycells-here[
    ;make sure neightbors must have atleast 1 agasent cell
      if count(bodycells-on neighbors)  > 0[
        let randnum random(100)
        if randnum < body-cell-spawn-rate[ ;randomly spawn a new cell
          sprout-bodycells 1 [
            set lifetime 0
            set color white
            set shape "square"
            set is-necrosis? false
          ]
        ]
      ]
    ]
  ]
end

;Calculate cell death rate
to set-total-cell-death-rate
  ifelse has-predisposition? = true[
    set total-cell-death-rate base-cell-death-rate * 10 ;predispositions cause X10 more likelyhood
  ]
  [
    set total-cell-death-rate base-cell-death-rate ;otherwise total death rate is the base death rate
  ]
  set max-cell-death-rate 10000 ;maximum cell death rate to pick a random number from
end

;Have apoptotic cells emit a sent
to emit-sent
  let x min-one-of dcells with [is-activated? = false and is-matured? = false] in-radius 100 [distance myself] ;get closest dcell
  if x != nobody[
    create-sent-to x ;create a link to that dcell
  ]
end


;------------       DNA       -----------------------------;
;spawn dna
to spawn-DNA
let randnum random(nucleic-antigen-per-cell) ;get random number
  ask patch-here[
    sprout-DNAs randnum[ ;spawn that many dna antigens
      set color blue
      set shape "circle"
      set size .25 ;set small
      set lifetime 0
    ]
  ]
end

;move dna
to move-DNA
  ;set back and forth movement
  check-patch
  ifelse patch-ahead 1 = nobody [
    set heading heading + random(180)
  ]
  [
    left random(90)
  right random(90)
  fd 1 ]
end

;check if it can be bound to anything
to check-patch

;check if Bcells are here
  if any? bcells-here[
    ask one-of bcells-here[
      if is-activated? = false[
        set is-activated? true
        set shape "bcell-active"
        ask one-of DNAs-here[
          die
        ]
      ]
    ]
  ]
;  ;check tcells here
;  if any? tcells-here[
;    ask one-of tcells-here[
;      if is-activated? = false[
;        set is-activated? true
;        set shape "tcell-active"
;        ask one-of DNAs-here[
;          die
;        ]
;      ]
;    ]
;  ]
  ;check for dcells here
  if any? dcells-here[
    ask one-of dcells-here[

       set shape "dcell-active"
        set is-activated? true
        ask my-in-links[
        die
        ]
        ask one-of DNAs-here[
          die
        ]

    ]
  ]
  ;check for antibodies here
  if any? antibodies-here[
    ask one-of antibodies-here[
      if is-activated? = false[
        set is-activated? true
        set shape "antibody-antigen"
        set lifetime 0
        ask one-of DNAs-here[
          die
        ]
      ]
    ]
  ]
   ;check for auto-antibodies here
  if any? auto-antibodies-here[
    ask one-of auto-antibodies-here[
      if is-activated? = false[
        set is-activated? true
        set shape "antibody-antigen"
        set lifetime 0
        ask one-of DNAs-here[
          die
        ]
      ]
    ]
  ]

end


;------------       B Cells       -----------------------------;
;make Bcells
to make-bcells
  create-bcells num-bcells [
    setxy (random(16) - random(16)) (random(8) - random(8))
    set color red
    set shape "bcell"
    set is-autoreactive? false
    set is-activated? false
    set plasma-cell? false
    set lifetime 0
    set has-afl? false
  ]
end

;Move Bcells
to move-bcells
  ;set back and forth movement

  ifelse patch-ahead 1 = nobody[
    set heading heading + random(180)
    ;fd 1
  ]
  [
    left random(90)
  right random(90)
  fd 1 ]
  produce-antibodies ;produce antibdies
end


;Spawns bcells through the simulation
to spawn-bcells
let randnum random(100) ;make a random number
if randnum <= bcell-spawn-rate[ ;if randnum is greater than set spawn rate then...
  create-bcells 1 [ ;spawn 1 dcell
    setxy (random(16) - random(16)) (random(8) - random(8)) ;set xy
    set color red ;color grey
    set shape "bcell" ;shape dcell
    set is-activated? false ;is not activated
    set plasma-cell? false
    set is-autoreactive? false
    set lifetime 0
    set has-afl? false
  ]
]
end

;produce Antibodies
to produce-antibodies
  ;if plasma cell produce antibodies for a time
  ifelse plasma-cell? = true[
  ;check if timer ran out
    ifelse production-timer > antibody-production-time[
      set plasma-cell? false
      set is-activated? false
      set color color + 2
    ]
    [
    ;else increase timer
      set production-timer production-timer + 1
      ifelse is-autoreactive? = false[
      make-antibodies
      ]
      [
      make-auto-antibodies
      ]
    ]

  ]
  ;else
  [
  ;check for tcells if bcell is activated
  if is-activated? = true[

  ;check for active tcell to activate antibody production
  if any? tcells-here[
    ask one-of tcells-here[
    if has-afl? = false[
      if is-activated? = true[
      ;remove anigen
        set is-activated? false
        ;set color color - 2
        ask one-of bcells-here with [is-activated? = true][
          set plasma-cell? true
          set production-timer 0
          set lifetime lifetime - 50
          set color color - 2
            ]
          ]
          ]
      ]
    ]
   if has-afl? = false[
  ;check for mature dcell to activate antibody production
  if any? dcells-here[
    ask one-of dcells-here[
      if is-matured? = true[
        ask one-of bcells-here with [is-activated? = true][
          set plasma-cell? true
          set is-autoreactive? true
          set production-timer 0
          set lifetime lifetime - 50
          set color color - 2
            ]
          ]
      ]
    ]
    ]
  ]
  ]
end

;------------       T Cells       -----------------------------;
;make tcells
to make-tcells
  create-tcells num-tcells [
    setxy (random(16) - random(16)) (random(8) - random(8))
    set color blue
    set shape "tcell"
    set has-afl? false
    set is-activated? false
    set lifetime 0
  ]
end

;Spawns tcells through the simulation
to spawn-tcells
let randnum random(100) ;make a random number
if randnum <= tcell-spawn-rate[ ;if randnum is greater than set spawn rate then...
  create-tcells 1 [ ;spawn 1 dcell

    set has-afl? false
    setxy (random(16) - random(16)) (random(8) - random(8)) ;set xy
    set color blue ;color grey
    set shape "tcell" ;shape tcell
    set is-activated? false ;is not activated
    set lifetime 0
  ]
]
end

;move tcells
to move-tcells
  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + random(180)
    ;fd 1
  ]
  [  left random(90)
  right random(90)
  fd 1 ]
end


;------------       D Cells       -----------------------------;

;Makes Dcells
to make-dcells
  create-dcells num-dcells [
    setxy (random(16) - random(16)) (random(8) - random(8))
    set color green
    set shape "dcell"
    set is-activated? false
    set lifetime 0
    set is-matured? false
  ]
end

;Spawns Dcells through the simulation
to spawn-dcells
let randnum random(100) ;make a random number
if randnum <= dcell-spawn-rate[ ;if randnum is greater than set spawn rate then...
  create-dcells 1 + floor(count dnas / 100) [ ;spawn 1 dcell + more
    setxy (random(16) - random(16)) (random(8) - random(8)) ;set xy
    set color green ;color green
    set shape "dcell" ;shape dcell
      set lifetime 0
      set is-matured? false
    set is-activated? false ;is not activated
  ]
]
end

;Movement for Dcells
to move-dcells
  set-direction ;set the direction of the dcell
  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [ ;check if its about to go out of bounds
    set heading heading + random(180) ;set random direction
    ;fd 1
  ]
  [
      left random(90)
  right random(90)
    fd 1 ;move forward
    ;if matured
    ifelse is-matured? = true[
    check-matured-tcells ;convert tcells
    ]
    [
    check-cell-death ;Check if apoptoti cell is occupying the same space
    check-tcells ;check if t cells are occupying the same space
    ]
  ]
end


;look for Tcells to turn them into autoreactive cells
to check-matured-tcells
  ;check for mature dcell to activate antibody production
  if any? tcells-here[
    ask one-of tcells-here[
        if has-afl? = false[
        spawn-acell
        die
        ]
      ]
    ]
end

;Sets the direction of DCell in the direction of an Apoptotic cell
to set-direction
  ;set direction based on link
  if count(my-links) > 0[ ;ifthere are links then
    let id who ;save the id of the dcell
    ask one-of my-links[
      let destination other-end ;get the bodycell of the link
      ask dcell id [
        face destination ;have the dcell face the bodycell
      ]
    ]
  ]
end

;Check if bodycells occupy the same space
to check-cell-death
  if any? bodycells-here[
    ask one-of bodycells-here[

      if is-necrosis? = true[ ;kill that cell if it's undergoying necrosis
        die

      ]
    ]
  ]
end

;Check if Tcells occupy the same space
to check-tcells
  if any? tcells-here[
    ask one-of tcells-here[
     if has-afl? = false[
      if is-activated? = false[ ;pass on the antigen if the t cell does not have it already
        set is-activated? true
      ]
      ]
    ]
  ]
end

;------------       Antibodies       -----------------------------;

;make anitbodies
to make-antibodies
  hatch-antibodies 1 [
    set color red
    set shape "antibody"
    set is-activated? false
    set lifetime 0
  ]
end

;move antibodies
to move-antibodies
  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + random(180)
    ;fd 1
  ]
  [
    left random(90)
  right random(90)
  fd 1 ]

  ;if antibody is antibody-antigen complex
  if is-activated? = true[
  ;if dcell is here
  if any? dcells-here[
    ask one-of dcells-here[
      if is-matured? = false[ ;if d cell is not matured
        set is-matured? true
        set lifetime 0
        ask my-in-links[
        die
        ]
        set shape "dcell-mature"
      ]
    ]
    die ;kill antibody
  ]
  ]
end
;------------      Auto-reactive Antibody       -----------------------------;

;make autoanitbodies
to make-auto-antibodies
  hatch-auto-antibodies 1 [
    set color red + 2
    set shape "antibody"
    set is-activated? false
      set lifetime 0
      set is-killing? false
      set killing-timer 0
  ]
end

;move antibodies
to move-auto-antibodies
ifelse is-killing? = false[

  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + random(180)
    ;fd 1
  ]
  [
    left random(90)
  right random(90)
  fd 1 ]

  ;if antibody is antibody-antigen complex
  if is-activated? = true[
  ;if dcell is here
  if any? dcells-here[
    ask one-of dcells-here[

      if is-matured? = false[ ;if d cell is not matured
        set is-matured? true
        set lifetime 0
        ask my-in-links[
        die
        ]
        set shape "dcell-mature"
      ]
    ]
    die ;kill antibody
  ]
  look-for-healthy-cells
  set-direction-auto-antibody
   kill-healthy-cell

  ]
  ]
  [
  ;timer to stop eating
  ifelse killing-timer > autoantibody-eating-time[
    set is-killing? false
    set killing-timer 0
    if any? bodycells-here[
    ask one-of bodycells-here[
    spawn-dna
      die
    ]

    ]
    die
  ]
  [
    set killing-timer killing-timer + 1
     ask bodycells-here[
      if is-necrosis? = true[
        set is-necrosis? false
      ]
    ]
  ]
  ]
end

to kill-healthy-cell
  if any? bodycells-here[
    ask one-of bodycells-here[
      if is-necrosis? = false[
      if any? auto-antibodies-here[
        ask one-of auto-antibodies-here[
        set is-killing? true
        ]
      ]
      ]
    ]

  ]
end


to look-for-healthy-cells
  let x min-one-of bodycells with [is-necrosis? = false] in-radius 100 [distance myself] ;get closest dcell
  if x != nobody[
    create-sent-to x ;create a link to that bodycell
  ]
end

;set direction of the auto reactive antibody
to set-direction-auto-antibody
  ;set direction based on link
  if count(my-links) > 0[ ;ifthere are links then
    let id who ;save the id of the dcell
    ask one-of my-links[
      let destination other-end ;get the bodycell of the link
      ask auto-antibody id [
        face destination ;have the dcell face the bodycell
      ]
    ]
  ]
end

;------------       Autoreactive Cell       -----------------------------;
;make an autoreactive cell
to spawn-acell
  hatch-acells 1 [ ;spawn 1 acell
    set color pink ;color violet
    set shape "acell" ;shape dcell
    set lifetime 0
    set is-killing? false
    set killing-timer 0
  ]
end

;move an auto reactive cell
to move-acell
  ifelse is-killing? = false[
  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + random(180)
    ;fd 1
  ]
  [
    left random(90)
  right random(90)
  fd 1 ]

  look-for-healthy-cells
  set-direction-auto-reactive
  kill-cells ;check if cells are here
  ]
  [;timer to stop eating
  ifelse killing-timer > autoreactive-eating-time[
    set is-killing? false
    set killing-timer 0
    if any? bodycells-here[
    ask one-of bodycells-here[
    spawn-dna
      die
    ]
    ]
  ]
  [
    set killing-timer killing-timer + 1
     ask bodycells-here[
      if is-necrosis? = true[
        set is-necrosis? false
      ]
    ]
  ]
  ]
end

;kill bodycells
to kill-cells
  if any? bodycells-here[
    ask one-of bodycells-here[
      if is-necrosis? = false[
        ask one-of acells-here[
        set is-killing? true
        ]
      ]
    ]

  ]
end

;set direction of the auto reactive Tcell
to set-direction-auto-reactive
  ;set direction based on link
  if count(my-links) > 0[ ;ifthere are links then
    let id who ;save the id of the dcell
    ask one-of my-links[
      let destination other-end ;get the bodycell of the link
      ask acell id [
        face destination ;have the dcell face the bodycell
      ]
    ]
  ]
end


;------------       Anifrolumab       -----------------------------;
;inject afl every n ticks
to inject-afl
  if (ticks mod Anifrolumab-Cycle-Length) = 0[
  spawn-afl
  ]
end


;spawns afl
to spawn-afl
  if count(afls) + Anifrolumab-Amount <= 100 [
  create-afls Anifrolumab-Amount [ ;spawn 1 alf
    setxy (random(16) - random(16)) (random(8) - random(8)) ;set xy
    set color violet ;color violet
    set shape "afl" ;shape dcell
    set lifetime 0
  ]
  ]
end

;moves the alf
to move-afl
  ;set back and forth movement
  ifelse patch-ahead 1 = nobody [
    set heading heading + random(180)
    fd 1
  ]
  [
  left random(90)
  right random(90)
  fd 1
  ]
  check-tcells-cure ;check in afl came into contact with tcell
  check-bcells-cure ;check if tfl came into contact with b vcell
end

;check tcel cure by giving it afl
to check-tcells-cure
  if any? tcells-here[
    ask one-of tcells-here[
      if has-afl? = false[ ;pass on the antigen if the cell does not have it already
        set has-afl? true
        set color violet ;set violet indicator
      ]
    ]
    die ;kill antibody
  ]
end

;check bcell cure by giving it afl
to check-bcells-cure
  if any? bcells-here[
    ask one-of bcells-here[
      if has-afl? = false[ ;pass on the antigen if the cell does not have it already
        set has-afl? true
        set color violet ;set violet indicator
      ]
    ]
    die ;kill antibody
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
539
10
1010
482
-1
-1
14.030303030303031
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
3
11
252
71
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
4
75
251
133
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
1

SLIDER
397
157
534
190
body-cell-spawn-rate
body-cell-spawn-rate
1
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
255
193
396
226
base-cell-death-rate
base-cell-death-rate
1
50
27.0
1
1
NIL
HORIZONTAL

SWITCH
4
282
250
315
has-predisposition?
has-predisposition?
0
1
-1000

SLIDER
255
11
395
44
num-tcells
num-tcells
1
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
256
48
394
81
num-bcells
num-bcells
1
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
258
119
394
152
num-dcells
num-dcells
1
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
256
157
395
190
cell-growth-rate
cell-growth-rate
1
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
257
84
529
117
antibody-production-time
antibody-production-time
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
396
11
529
44
tcell-spawn-rate
tcell-spawn-rate
0
50
32.0
1
1
NIL
HORIZONTAL

SLIDER
396
48
528
81
bcell-spawn-rate
bcell-spawn-rate
0
50
32.0
1
1
NIL
HORIZONTAL

SLIDER
397
120
528
153
dcell-spawn-rate
dcell-spawn-rate
0
50
32.0
1
1
NIL
HORIZONTAL

SLIDER
399
193
536
226
nucleic-antigen-per-cell
nucleic-antigen-per-cell
1
5
3.0
1
1
NIL
HORIZONTAL

BUTTON
4
136
251
210
Inject Anifrolumab
inject-afl
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
4
212
250
245
Anifrolumab-Amount
Anifrolumab-Amount
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
4
247
250
280
Anifrolumab-Cycle-Length
Anifrolumab-Cycle-Length
10
300
300.0
10
1
NIL
HORIZONTAL

PLOT
1016
14
1331
219
Effect of Anifrolumab
time
# of agents
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Autoreactive Agents" 1.0 0 -2064490 true "" "plot count acells + count auto-antibodies with[is-activated? = true]"
"Anifrolumab Angents" 1.0 0 -13791810 true "" "plot count tcells with[has-afl? = true]"

SLIDER
256
228
406
261
autoreactive-eating-time
autoreactive-eating-time
1
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
256
265
415
298
autoantibody-eating-time
autoantibody-eating-time
1
10
5.0
1
1
NIL
HORIZONTAL

PLOT
1015
226
1328
354
Infamation Respose
time
# of Agents
0.0
1000.0
0.0
20.0
true
true
"" ""
PENS
"Nucleic Antigens" 1.0 0 -13345367 true "" "plot count dnas"
"Matured Dcells" 1.0 0 -14439633 true "" "plot count (dcells with [ is-matured? = true])"

PLOT
1016
356
1329
481
Dead Cells Over Time
Time
Dead Cells
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 198 - count bodycells "

SLIDER
5
321
97
354
tcell-lifetime
tcell-lifetime
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
100
321
192
354
bcell-lifetime
bcell-lifetime
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
129
359
221
392
dcell-lifetime
dcell-lifetime
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
5
358
123
391
antibody-lifetime
antibody-lifetime
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
5
394
137
427
anifrolumab-lifetime
anifrolumab-lifetime
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
142
394
255
427
antigen-lifetime
antigen-lifetime
0
100
50.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The immune system relies on several cells signaling to one another and passing information, but when distorted, this signaling can result in unintuitive processes. Systemic Lupus Erythematosus (SLE), which tricks antibodies and T-cells into attacking healthy cells. From an unknown cause, healthy cells go under some form of cell death (apoptosis/necrosis) and nucleic antigens become present in the system. When cleaned up through phagocytosis, dendritic cells (D-cells) recognize the DNA as a foreign invader and go through the normal immune pathway. This involves D-cell to T-cell interaction in which type 1 interferons (T1IFN) are transferred between D-cells and T-cells along with the nucleic antigen. This coupled transition of the antigen and T1IFN allow the spread of information that a foreign invader has effected the host. This leads to T-cell to B-cell interactions, using the same mechanism as D to T cell interactions. When B-cells have information on an antigen it in tern produces antigen specific antibodies. These antibodies then bind to the nucleic antigens induced by apoptosis to form an antibody-antigen complex. The antibody-antigen complex can be destroyed by phagocytes such as D-cells. When D-cells consume the antibody-antigen complex, D-cells then increase their potency of T1IFN. Such that when in contact, D-cells alter T-cells to become autoreactive cell that attacks the hosts’ own healthy cells and B-cells can then become corrupted again to produce autoreactive antibodies which attack the host cells.


This simulation will look at what would happen across several positions in the SLE pathway and hope to add preventative measures to parts of the pathway in hope to model a potential solutions. The preventative measure, Anifrolumab, attaches to type 1 interferon receptors blocking the passage of antigen presentation signals between T-cells and B-cells therefore preventing them from going autoreactive. Due to the coupled nature of transferring the antigen and cytokines, blocking the cytokines would prevent the transport of antigens, thereby preventing the autoreactive response.


## HOW IT WORKS

D Cell + Apoptotic Cell = No Antigens

Time + Apoptotic Cell = Antigens

Antigens + B Cell = Activated B Cell

Antigens + D Cell = Activated D Cell

Activated D Cell + T Cell = Activated T Cell + Activated D Cell

Activated T Cell + Activated B Cell = T Cell + Activated B Cell + Antibodies

Antibodies + Antigens = Antibody-antigen

Antibody-antigen + D Cell = Mature D Cell

Mature D Cell + T Cell = Autoreactive Cell + Mature D Cell

Mature D Cell + Activated B Cell = Mature D Cell + Activated B Cell + Autoreactive Antibody

Autoreactive Antibody + Antigen = Autoreactive Antibody-Antigen

Autoreactive Antibody-Antigen + Healthy Cell = Dead Cell + Antigens

Autoreactive Cell + Healthy Cell = Autoreactive Cell + Dead Cell + Antigens

Anifrolumab + T Cell = Inhibited T Cell

Anifrolumab + B Cell = Inhibited B Cell

Inhibited T Cell + Mature D Cell = Inhibited T Cell + Mature D Cell

Inhibited B Cell + Mature D Cell = Inhibited B Cell + Mature D Cell

## HOW TO USE IT

•	Num-tcell = dictate the starting amount of Tcells
•	Num-bcells = dictate the starting amount of B cells
•	Num-dcells = dictate the starting amount of D cells
•	T Cell spawn rate = The chance that a Tcell will spawn on a tick
•	B Cell Spawn rate = The chance that a Bcell will spawn on a tick
•	D cell Spawn Rate = The chance that a Dcell will spawn on a tick
•	Antibody-Production time = The time required for a B cell to create antibodies
•	Cell growth rate = the amount a cell grows duting apoptosis
•	Body-cell-spawn-rate = the chance that a healthy cell will split into two
•	Base cell death rate = the chance that a healthy cell will undergo apoptosis
•	Nucleic-antigen-per-cell = the number of antigens a cell creates when it explodes
•	Autoreactive-eating-time = the time required for autoreactive cells to kill a healthy cell
•	Has predisposition = does the host have a predisposition to sle?
•	Autoantibody eating-time = the time required for auto-antibody cells to kill a healthy cell
•	T cell lifetime = Life time of a tcell
•	B cell lifetime = Life time of a bcell
•	D cell lifetime = Life time of a dcell
•	Anifrolumab lifetime = Life time of a anifrolumab protein
•	Antibody lifetime = Life time of an antibody
•	Antigen lifetime Life time of an antigen
•	Anifrolumab amount = amount of anifroulamb given during a doseage
•	Anifrolumab Cycle Length = amount of ticks between doseages

## THINGS TO NOTICE

Notice the rate of cell death along with the useage of anifrolumab.
Notice how the rate of T cells spawn influence the rate of Autoreactive cells

## THINGS TO TRY

Try to kill the host and note what aspects of the simulation cuased it.

## EXTENDING THE MODEL

Add another pathogen and see if it thrives with Tcells being inhibited

## NETLOGO FEATURES

Links

## CREDITS AND REFERENCES

By Daniel McDonough

References:

•	Dörner, Thomas. Giesecke, Claudia.  Lipsky, Peter E. 2011. Mechanisms of B cell autoimmunity in SLE. Arthritis Research & Therapy. 12;13(5): 243.
•	Saigal R, Goyal LK, Agrawal A, Mehta A, Mittal P, Yadav RN.. 2013. Anti-nucleosome antibodies in patients with systemic lupus erythematosus: potential utility as a diagnostic tool and disease activity marker and its comparison with anti-dsDNA antibody. J Assoc Physicians India. Jun;61(6):372-7
•	Anolik, J. and Aringer, M. (2005). New treatments for SLE: cell-depleting and anti-cytokine therapies. Best Practice & Research Clinical Rheumatology, 19(5), pp.859-878.
•	Bubier, J., Sproule, T., Foreman, O., Spolski, R., Shaffer, D., Morse, H., Leonard, W. and Roopenian, D. (2009). A critical role for IL-21 receptor signaling in the pathogenesis of systemic lupus erythematosus in BXSB-Yaa mice. Proceedings of the National Academy of Sciences, 106(5), pp.1518-1523.
•	Z-G Li, R Mu, Z-P Dai, X-M Gao. 2005. T cell vaccination in systemic lupus erythematosus with autologous activated T cells. Lupus. Nov;14(11):884-9.
•	R. H. B. Benedict, J. L. Shucard, R. Zivadinov, D. W. Shucard. 2008 Neuropsychological Impairment in Systemic Lupus Erythematosus: A Comparison with Multiple Sclerosis. Neuropsychol Rev. Jun; 18(2): 149–166.

@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

acell
true
0
Rectangle -7500403 true true 105 75 195 105
Polygon -7500403 true true 105 60 75 240 120 240 135 165 165 165 180 240 225 240 195 60 105 60
Polygon -16777216 true false 150 90 135 135 165 135 150 90 150 90

afl
true
0
Circle -7500403 true true 75 75 88
Circle -7500403 true true 88 133 92
Circle -7500403 true true 133 88 92

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

antibody
true
0
Rectangle -7500403 true true 135 150 165 255
Polygon -7500403 true true 150 120 150 150 135 165 60 90 75 75 150 150
Polygon -7500403 true true 165 165 150 165 150 150 225 75 240 90

antibody-antigen
true
0
Rectangle -7500403 true true 135 150 165 255
Polygon -7500403 true true 150 120 150 150 135 165 60 90 75 75 150 150
Polygon -7500403 true true 165 165 150 165 150 150 225 75 240 90
Circle -13345367 true false 101 41 96

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bcell
true
0
Rectangle -7500403 true true 75 45 120 255
Circle -7500403 true true 104 44 122
Circle -7500403 true true 104 134 122
Rectangle -7500403 true true 75 45 180 75
Rectangle -7500403 true true 75 135 180 255
Circle -16777216 true false 133 73 62
Rectangle -16777216 true false 105 75 165 135
Rectangle -16777216 true false 105 165 165 225
Circle -16777216 true false 135 165 58

bcell-active
true
0
Rectangle -7500403 true true 75 45 120 255
Circle -7500403 true true 104 44 122
Circle -7500403 true true 104 134 122
Rectangle -7500403 true true 75 45 180 75
Rectangle -7500403 true true 75 135 180 255
Circle -16777216 true false 133 73 62
Rectangle -16777216 true false 105 75 165 135
Rectangle -16777216 true false 105 165 165 225
Circle -16777216 true false 135 165 58
Circle -7500403 false true -2 -2 302

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

dcell
true
0
Rectangle -7500403 true true 75 75 120 225
Circle -7500403 true true 75 75 150
Rectangle -7500403 true true 75 75 150 90
Rectangle -7500403 true true 75 210 150 225
Circle -16777216 true false 105 105 90
Rectangle -16777216 true false 105 105 150 195

dcell-active
true
0
Rectangle -7500403 true true 75 75 120 225
Circle -7500403 true true 75 75 150
Rectangle -7500403 true true 75 75 150 90
Rectangle -7500403 true true 75 210 150 225
Circle -16777216 true false 105 105 90
Rectangle -16777216 true false 105 105 150 195
Circle -7500403 false true 0 0 300

dcell-mature
true
0
Rectangle -7500403 true true 60 75 120 90
Rectangle -7500403 true true 180 75 240 90
Rectangle -7500403 true true 60 90 90 225
Rectangle -7500403 true true 210 90 240 225
Polygon -7500403 true true 90 90 135 165 165 165 210 90 180 75 150 150 120 75 105 90 90 90
Circle -7500403 false true 0 0 300

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

tcell
true
0
Rectangle -7500403 true true 60 60 240 90
Rectangle -7500403 true true 135 90 165 270

tcell-active
true
0
Rectangle -7500403 true true 60 60 240 90
Rectangle -7500403 true true 135 90 165 270
Circle -7500403 false true -2 -2 304

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
<experiments>
  <experiment name="experiment" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>count tcells with[has-afl? = true]</metric>
    <metric>count acells + count auto-antibodies with[is-activated? = true]</metric>
    <enumeratedValueSet variable="bcell-lifetime">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autoreactive-eating-time">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bcell-spawn-rate">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tcell-spawn-rate">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dcell-lifetime">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antigen-lifetime">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antibody-lifetime">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="body-cell-spawn-rate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dcell-spawn-rate">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autoantibody-eating-time">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tcell-lifetime">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="has-predisposition?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nucleic-antigen-per-cell">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antibody-production-time">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-dcells">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anifrolumab-Amount">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anifrolumab-Cycle-Length">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-tcells">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-bcells">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="anifrolumab-lifetime">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cell-growth-rate">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-cell-death-rate">
      <value value="10"/>
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
