;Diffusion by Daniel McDonough
globals [
  radius   ;; distance of the farthest green patch from the center
  use-whole-world?
]
breed[red-dyes red-dye]
breed[blue-dyes blue-dye]



to setup
  clear-all
  set radius 0
  set use-whole-world? true
  ask patches with [pycor = 0]
    [ set pcolor violet ]

  ;;  This will make the outermost patches blue.  This is to prevent the turtles
  ;;  from wrapping around the world.  Notice it uses the number of neighbor patches rather than
  ;;  a location. This is better because it will allow you to change the behavior of the turtles
  ;; by changing the shape of the world (and it is less mistake-prone)
  ask patches with [count neighbors != 8]
    [ set pcolor red ]

  ;ask patch 0 0
  ;  [ set pcolor green ]
  reset-ticks
end

to go
  ;; stop when we get near the edge of the world
  if radius >= max-pxcor - 3
    [ stop ]
  ;; make new turtles, up to a maximum controlled by the MAX-PARTICLES
  ;; slider; also check clock so we don't make too many turtles too
  ;; soon, otherwise we get a big green clump at the center (only happens
  ;; USE-WHOLE-WORLD? is false)
  while [count turtles < max-particles and
         count turtles < ticks]
    [ make-new-red-dye
      make-new-blue-dye
  ]
  ;; now move the turtles
  ask red-dyes
    [ red-wander]
 ask blue-dyes
  [blue-wander]
  ;; advance clock
  tick
end

to make-new-red-dye
  ;; each new turtle starts its random walk from a position
  ;; a bit outside the current radius and facing the center
  create-red-dyes 1
    [ set color red
      set size 3  ;; easier to see
      setxy red-dye-xcoord red-dye-ycoord
      ifelse use-whole-world?
        [ ];jump max-pxcor ]
      [ ];jump radius + 1.5 ]
      rt 180 ]
end


to make-new-blue-dye
  ;; each new turtle starts its random walk from a position
  ;; a bit outside the current radius and facing the center
  create-blue-dyes 1
    [ set color blue
      set size 3  ;; easier to see
      setxy blue-dye-xcoord blue-dye-ycoord
      ifelse use-whole-world?
        [ ];jump max-pxcor ]
      [ ];jump radius + 1.5 ]
      rt 180 ]
end

to red-wander   ;; turtle procedure
  ifelse [pcolor] of patch-ahead 1 = red
      [ rt random-float wiggle-angle - random-float wiggle-angle ]   ;; We see a blue patch in front of us. Turn a random amount.
      [                    ;; Otherwise, it is safe to move forward.
  ;; the WIGGLE-ANGLE slider makes our path straight or wiggly
  ;; move
    fd 1
   rt random-float wiggle-angle - random-float wiggle-angle
  ]
end

to blue-wander   ;; turtle procedure
  ifelse [pcolor] of patch-ahead 1 = red or [pcolor] of patch-ahead 1 = violet
      [ rt random-float wiggle-angle - random-float wiggle-angle ]   ;; We see a blue patch in front of us. Turn a random amount.
      [                    ;; Otherwise, it is safe to move forward.
  ;; the WIGGLE-ANGLE slider makes our path straight or wiggly
  ;; move
    fd 1
   rt random-float wiggle-angle - random-float wiggle-angle
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
379
44
772
438
-1
-1
2.2515
1
10
1
1
1
0
0
0
1
-85
85
-85
85
1
1
1
ticks
30.0

SLIDER
8
122
261
155
max-particles
max-particles
1
300
300.0
1
1
NIL
HORIZONTAL

BUTTON
65
42
128
75
NIL
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
140
42
203
75
NIL
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
8
88
261
121
wiggle-angle
wiggle-angle
0.0
360.0
36.0
1.0
1
degrees
HORIZONTAL

SLIDER
8
174
180
207
red-dye-xcoord
red-dye-xcoord
-80
80
22.0
1
1
NIL
HORIZONTAL

SLIDER
8
211
180
244
red-dye-ycoord
red-dye-ycoord
-80
80
14.0
1
1
NIL
HORIZONTAL

SLIDER
9
269
181
302
blue-dye-xcoord
blue-dye-xcoord
-80
80
-11.0
1
1
NIL
HORIZONTAL

SLIDER
9
309
181
342
blue-dye-ycoord
blue-dye-ycoord
-80
80
-10.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates diffusion-limited aggregation, in which randomly moving (diffusing) particles stick together (aggregate) to form beautiful treelike branching fractal structures.  There are many patterns found in nature that resemble the patterns produced by this model: crystals, coral, fungi, lightning, and so on.

## HOW IT WORKS

The model begins with an initial green "seed" in the center of the world.  Red particles move around the world randomly.  When a red particle hits a green square, it "sticks" and turns green (and a new red particle is created to keep the process going).

## HOW TO USE IT

Press SETUP to make the initial seed, then press GO to run the model.

The WIGGLE-ANGLE slider controls how wiggly the paths the particles follow are.  If WIGGLE-ANGLE is 0, they move in straight lines.  If WIGGLE-ANGLE is 360, they move in a totally random direction at each time step.

The MAX-PARTICLES slider controls how many red particles can exist at the same time.

Both settings may be altered in the middle of a model run.

The USE-WHOLE-WORLD? switch controls whether the red particles start at the edge of the world, or from just outside a circle enclosing the green area.  If the switch is on, it's easier to see what's going on, but the model runs slower, particularly when WIGGLE-ANGLE is high.

## THINGS TO NOTICE

Note that the resulting structure has a branching structure, like a tree.  Why does this happen?

What other phenomena in the world do the shapes remind you of?  Is this aggregation process a plausible model of how those phenomena occur?

When the enclosing circle gets too near to the edge of the world, the model stops, since allowing the particles to wrap around the edges of the world would distort the shape of the aggregate.

New red particles are created not at the edge of the world, but at the edge of a circle enclosing the current size of the green aggregate, instead of traveling from the edge of the world.  Also, if a red particle wanders too far outside the circle, it disappears and a new one is created.  Neither of these behaviors is essential to the model -- it is done this way just to the model runs fast.

## THINGS TO TRY

Try different settings for WIGGLE-ANGLE.  What is the effect on the appearance of the resulting aggregate?  Why?

Does the MAX-PARTICLES slider make any difference?  Why or why not?

Do you think the USE-WHOLE-WORLD? setting has an effect on the appearance of the resulting aggregate?  Why or why not?  Experiment and find out.  If you initially thought differently from what you found, why do you think you thought otherwise?  Can you explain why it does happen the way you found?

## EXTENDING THE MODEL

What happens if you start with more than one "seed" patch?  What happens if the seed is a line instead of a point?

Can you find a way to modify the code so the resulting pattern spirals out instead of radiating straight out?

The rule used in this model is that a particle "sticks" if any of the eight patches surrounding it are green.  What do the resulting structures look like if you use a different rule (for example, only testing the single patch ahead, or using `neighbors4` instead of `neighbors`)?

Can you compute the fractal dimension of the aggregate?

If instead of using green, you gradually vary the color of deposited particles over time, you can see more vividly the accretion of "layers" over time.  (The effect is also visually pleasing.)

The model will run faster if the turtles are invisible, so you may want to add a switch that hides them (using the `hide-turtle` command).

Let's use the term "envelope" to describe the large "circle" created by all the green particles, with the green particle that is farthest from the center defining the radius of this envelope.  Within this envelope, what is the ratio between patches with green particles and patches that have no particles?  Or, what is the ratio between particles and patches?  Create a graph to track this ratio.  Create a histogram that accumulates the end value of this process over multiple runs.

How circular is the envelope at the end of a simulation? Is it "smooth" or "bumpy"? How would you define the goodness of this circle?

Let's use the term "end particles" to describe the green particles at the end of an outward reaching branch (so they are connected only to one other particle).  Create a procedure to calculate and report the average number of nodes along all the possible paths from the center to the end particles).  You can also create a histogram of these values.

How many "end particles" are there over time?  It seem likely that this number should grow, but how would you expect this number to grow?  Create a graph to track the growth in the number of these "end particles."

What is the ratio between "end particles" and nodes?  Does this ratio change over time?  Create a graph to track this ratio as the simulation runs.

Create a procedure that allows you to click on any two green particles and have another moving particle sprout at the first green particle you clicked and then track and color the path between these two green particles. What is the longest path between any two green particles?  Is this number bound above?

## NETLOGO FEATURES

Note the use of the `neighbors` and `distancexy` primitives.

## RELATED MODELS

In this model, the green squares are on a grid.  For a different implementation of the same idea that does not involve a grid, see DLA Alternate.  It uses circular particles that stick to each other.

DLA Alternate Linear has particles that fall straight down from the top of the world, instead of falling towards a central point.

DLA Simple is a simplified (but less computationally efficient) version of this model.

The various models in the "Fractals" subsection of the "Mathematics" section of the Models Library demonstrate some other ways of "growing" fractal structures.

The "Percolation" model in the "Earth Science" section produces patterns resembling the patterns in this model.

The "Hex Cell Aggregation" model in the "Computer Science" section uses a grid of hexagons, rather than squares, and uses a cellular automaton with a growth rule instead of moving particles.

## CREDITS AND REFERENCES

The concept of diffusion limited aggregation was invented by T.A. Witten and L.M. Sander in 1981.  Tamas Viczek's book "Fractal Growth Phenomena" contains a discussion, as do many other books about fractals.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo DLA model.  http://ccl.northwestern.edu/netlogo/models/DLA.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Wilensky, U. (1993). Thesis - Connected Mathematics: Building Concrete Relationships with Mathematical Knowledge. Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.  Adapted to NetLogo, 2002, as part of the Participatory Simulations Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2002.

<!-- 1997 2002 Wilensky -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
set use-whole-world? false
setup
repeat 450 [ go ]
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
