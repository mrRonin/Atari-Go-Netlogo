__includes ["MCTS.nls"]

extensions [matrix]

breed [dots dot];; just for cosmetics
breed [pieces piece]
breed [temps temp]
globals [
  boardsize
  tl
]
patches-own [
  value   ;; value 0/1/2 empty/black/white
]

;;Debug must be used with basic funcions, with all UCT it slows down everything

to clear ;;clear turtles from debugging mode
  ask temps [die]
end

to-report MCTS:get-content [s]
  report item 0 s
end

to-report MCTS:get-playerJustMoved [s]
  report item 1 s
end

to-report MCTS:create-state [c p]
  report (list c p)
end

to-report MCTS:apply [r s] ;; not on original matrix, cause i wanna simulate and return a copy
  let m matrix:copy item 0 s
  ;let m item 0 s
  let p MCTS:get-playerJustMoved s
  let cpl get-other-player p ;; current player
  let x first r
  let y first bf r
  matrix:set m x y cpl
  report list m cpl
end

to-report MCTS:get-rules [s] ;; matrix player ;; [[STATE]] p deducibile da state
  let op item 1 (s) ;; old player
  let p get-other-player(op)
  let m (item 0 s)
  let vm-list []  ;;valid moves
  let wm-list []  ;;winning moves
  let x 0
  let y 0
  if (terminal? s)[report []]
  while [x < boardsize][
    while [y < boardsize][
      if (matrix:get m x y = 0)[ ;; if empty/playable
          if(((y + 1 < boardsize) and (matrix:get m x (y + 1) = op) and (count-liberties m x (y + 1) op = 1))
          ;;  if it captures smth even if it is a sucide is valid and winning so reporting ASAP, checking NSEW
          or ((y - 1 >= 0) and (matrix:get m x (y - 1) = op) and(count-liberties m x (y - 1) op = 1))
          or ((x + 1 < boardsize) and (matrix:get m (x + 1) y = op) and (count-liberties m (x + 1) y op = 1))
          or ((x - 1 >= 0) and (matrix:get m (x - 1) y = op) and (count-liberties m (x - 1) y op = 1)))[
          ;;also i can write a safe [s] function that prints True if it has more then 2 lib. less time spent in this config, but same complexity.
          ;;also it's more scalable like this, for example if i want to add an heuristic as for as "pick sol that maximize the minimum liberty number"
          set wm-list lput (list x y) wm-list ;; I could just return winning move, leave like this for completesness
          ;report (list list x y)
        ]
        if (count-liberties m x y p > 0)[ ;; check if its not a suicide
          set vm-list lput (list x y) vm-list ;;list all possibilities
        ]
      ]
      set y y + 1
    ]
    set y 0
    set x (x + 1)
  ]
  ifelse (not empty? wm-list)
  [report wm-list]
  [report vm-list]
end

to-report get-rules-full [s] ;; matrix player ;; [[STATE]] p deducibile da state
  let op item 1 (s) ;; old player
  let p get-other-player(op)
  let m (item 0 s)
  let vm-list []  ;;valid moves
  let x 0
  let y 0
  while [x < boardsize][
    while [y < boardsize][
      if (matrix:get m x y = 0)[ ;; if empty/playable
        if (count-liberties m x y p > 0)
        or (((y + 1 < boardsize) and (matrix:get m x (y + 1) = op) and (count-liberties m x (y + 1) op = 1)) ;;  if it captures something even if it is a sucide is valid
          or ((y - 1 >= 0) and (matrix:get m x (y - 1) = op) and(count-liberties m x (y - 1) op = 1))
          or ((x + 1 < boardsize) and (matrix:get m (x + 1) y = op) and (count-liberties m (x + 1) y op = 1))
          or ((x - 1 >= 0) and (matrix:get m (x - 1) y = op) and (count-liberties m (x - 1) y op = 1)))[
          set vm-list lput (list x y) vm-list ;;list all possibilities
        ]
      ]
      set y y + 1
    ]
    set y 0
    set x (x + 1)
  ]
  report vm-list
end

to-report MCTS:get-result [s p] ;; care! last moving player point of view has precendence! if he wins it will be ok even if he has a 0-liberties area
  let m (item 0 s)
  let traversedlist []
  let tempgroup []
  let x 0
  let y 0
  let lphit false ;; last player hit
  let lploss false
  let lp MCTS:get-playerJustMoved s ; last player
  let lpa get-other-player MCTS:get-playerJustMoved s ; last player's adversary, just to check his liberties
  while [x < boardsize][
    while [y < boardsize][
      let check matrix:get m x y
      if (check != 0 and count-liberties m x y (check) = 0)[
        ifelse (check = lpa)[set lphit true][set lploss true]
      ]
      set y y + 1
    ]
    set y 0
    set x (x + 1)
  ]
  if (lphit)[
    ifelse (lp = p)[report 1][report 0]
  ]
  if (lploss)[
    ifelse (lp = p)[report 0][report 1]
  ]
  if (empty? get-rules-full s) [
    report 0.5
  ]
  report [false]
end

to-report terminal? [s]
  let m (item 0 s)
  let traversedlist []
  let tempgroup []
  let x 0
  let y 0
  while [x < boardsize][
    while [y < boardsize][
      let check matrix:get m x y
      if (check != 0 and count-liberties m x y (check) = 0)[
        report true
      ]
      set y y + 1
    ]
    set y 0
    set x (x + 1)
  ]
  report false
end

to-report get-other-player [p]
  if p = 1 [
  report 2]
  ifelse p = 2
  [report 1]
  [print "unexpected value"] ;; like this for DEBUGging reasons, it pops error
end

to-report count-liberties [m x y p]
  set tl []
  set tl lput list x y tl ;;setting a global list tl to have just this node, then my recursive part will fill it with traversed nodes
  if debug [print "count-liberties launched for"
    ifelse (p = 1)
    [print "BLACK"]
    [print "WHITE"]
  ]
  if (matrix:get m x y = get-other-player p)[report 0]
  report reduce + (list
    count-liberties-in m (x + 1) y p
    count-liberties-in m x (y + 1) p
    count-liberties-in m (x - 1) y p
    count-liberties-in m x (y - 1) p
  )
end

to-report count-liberties-in [m x y p]
  let lib 0
  if debug [print "vvvvvv   launched on   vvvvvvv "]
  if (x < boardsize and y < boardsize and x >= 0 and y >= 0)
  [if (debug)[print "position -> "
    print list x y
    print "found -> "]
  let found matrix:get m x y
  if (debug and found = 1)
    [print "BLACK"]
  if (debug and found = 2)
    [print "WHITE"]
  if (debug and found = 0)
    [print "EMPTY"]
  if debug [  print "traversed nodes -> "
      print tl]
  ]
  if (x >= boardsize or y >= boardsize or x < 0 or y < 0 or member? (list x y) tl)[ ;; not valid
    if (debug) [
      print "not valid"
      ask patch  y ((boardsize - 1) - x) [
        sprout-temps 1[
          set color red
          set shape "o"
        ]
      ]
    ]
    report 0
  ]
  set tl lput list x y tl
  if-else (matrix:get m x y = 0)
  [if (debug)[
    print "spotted one liberty in"
    ask patch  y ((boardsize - 1) - x) [
      sprout-temps 1 [
        set color green
        set shape "o"
      ]
    ]
   ]
    if debug [
      print list x y
      print "\n"
    ]
    report 1 ;;case empty
  ]
  [if (matrix:get m x y = get-other-player p)
    [
      if (debug)[
        print "other player stone, break"
        ask patch  y ((boardsize - 1) - x) [
          sprout-temps 1 [
            set color red
            set shape "x"
          ]
        ]
      ]
      report 0]
  ]
  ;;ofc dont do nothing, dont add liberties
  if (matrix:get m x y = p)[;;in case I find the same color, recursive NSEW search NorthSouthEastWest
    ;print "launched recursion"
    if (debug) [
      ask patch  y ((boardsize - 1) - x) [
        ask temps-here [
          set color grey
          set shape "recurs"
        ]
      ]
    ]
    report reduce + (list
    count-liberties-in m (x + 1) y p
    count-liberties-in m x (y + 1) p
    count-liberties-in m (x - 1) y p
    count-liberties-in m x (y - 1) p
  )
  ]
end

to pone [i x y]
  if (i = 0)[
    ask patch y ((boardsize - 1) - x)
      [
        set value 0
        ask pieces-here [ die ]
      ]
  ]
  if (i = 1)[
     ask patch y (boardsize - x - 1) [
      set value 1
      sprout-pieces 1 [
        set shape "circle"
        set color black
      ]
    ]
  ]
    if (i = 2)[
      ask patch y (boardsize - x - 1) [
        set value 2
        sprout-pieces 1 [
          set shape "circle"
          set color white]
      ]
    ]
end



to-report is-valid? [m x y p]
  if (matrix:get m x y = 0)[ ;; if empty/playable
        if (count-liberties m x y p != 0) ;; check if its not a suicide
        or ((y + 1 < boardsize) and (count-liberties m x (y + 1) 1 = 1)) ;;  btw if it a sucide, but captures something is still valid , checking NSEW
        or ((y - 1 >= 0) and (count-liberties m x (y - 1) 1 = 1))
        or ((x + 1 < boardsize) and (count-liberties m (x + 1) y 1 = 1))
        or ((x - 1 >= 0) and (count-liberties m (x - 1) y 1 = 1))[  ;; short-circuits
    report true
    ]
  ]
  report false
end

;;
;; STARTING AND CYCLING
;;
to start
  ca
  let t map [x -> [value] of x] (sort patches)
  set boardsize sqrt length t
  ask patches [
    set value 0
    set pcolor rgb 215 152 76
    if not any? pieces-here [
      sprout-dots 1[
        set color black
        set shape "go"
      ]
    ]
  ]
end


to go
  let played? false
  if (mouse-down? or (blackstarts? = false))   [
    ifelse blackstarts? [
      let x (boardsize - (round mouse-ycor) - 1)
      let y round mouse-xcor
      if debug[
        print ("coord are")
        print (list x y)
      ]
      print list x y
      ifelse (member? (list x y)(get-rules-full list board2state 2))[ ;; also check if player is playing a valid move
        ask patch y (boardsize - x - 1) [
          set value 1
          sprout-pieces 1 [
            set shape "circle"
            set color black]
          set played? true
        ]
        print "actual state"
      print matrix:pretty-print-text board2state
      print 1
      ][
        print ("NOT VALID!")
      ]
      print"checking winning conditions"
      if MCTS:get-result (list board2state 1) 1 = 1 [ ;; winning condition after player 1 move, so  state = [board2state , 1] , and POV = player 1
        user-message "You win!!!"
        stop
      ]
      if empty? MCTS:get-rules (list board2state 2) [
        user-message "Draw!!!"
        stop
      ]
    ]
    [set played? true
    set blackstarts? true]
    wait .1
    if played? [
      print "AI is thinking..."
      ;print "MTS:UTC is evaluating this state"
      print matrix:pretty-print-text board2state
      print 1
      let m MCTS:UCT (list board2state 1) MAx_iterations
      show m
      ask ( item ((first bf m)  + first m * boardsize)(sort patches)) [
        set value 2
        sprout-pieces 1 [
          set shape "circle"
          set color white]
      ]

  print ("check after MC move")
  if MCTS:get-result (list board2state 2) 2 = 1 [
      user-message "I win!!!"
      stop
    ]
  if empty? MCTS:get-rules (list board2state 1) [
      user-message "Draw!!!"
      stop
    ]
   ]
  ]
end

to-report board-to-state
  let b map [x -> [value] of x] (sort patches)
  report b
end

to-report board2state  ;; matrix variant, at the end i just used this for everything
  let t map [x -> [value] of x] (sort patches)
  let b map [n -> sublist t (n * boardsize)(n * boardsize + boardsize)] range boardsize
  let bm matrix:from-row-list b
  if debug [print matrix:pretty-print-text bm]
  report bm
end




;;;;;; END, now unused functions



to-report get-group [m x y]
  let c matrix:get m x y
  let traversedlist []
  let grouplist []
  set grouplist lput list x y grouplist
  set traversedlist lput list x y traversedlist
  let i 0 ;; setting variables for my while
  let nextX 0
  let nextY 0
  while [i < length grouplist][
    set nextX first item i grouplist
    set nextY item 1 item i grouplist
    if (((nextX + 1) < boardsize) and (not member? list (nextX + 1) nextY traversedlist and matrix:get m (nextX + 1) nextY = c))[
      set traversedlist lput list (nextX + 1) nextY traversedlist
      set grouplist lput list (nextX + 1) nextY  grouplist
    ]
    if (((nextY + 1) < boardsize) and (not member? list nextX (nextY + 1) traversedlist and matrix:get m nextX (nextY + 1) = c))[
      set traversedlist lput list nextX (nextY + 1)  traversedlist
      set grouplist lput list nextX (nextY + 1) grouplist
    ]
    if (((nextX - 1) >= 0) and (not member? list (nextX - 1) nextY traversedlist and matrix:get m (nextX - 1) nextY = c))[
      set traversedlist lput list (nextX - 1) nextY traversedlist
      set grouplist lput list (nextX - 1) nextY grouplist
    ]
    if (((nextY - 1) >= 0) and (not member? list nextX (nextY - 1) traversedlist and matrix:get m nextX (nextY - 1) = c))[
      set traversedlist lput list nextX (nextY - 1) traversedlist
      set grouplist lput list nextX (nextY - 1) grouplist
    ]
    set i (i + 1)
  ]

  if (debug)[
    foreach grouplist [
      gli ->  ;;group list item
      create-temps 1 [
        setxy item 1 gli ((boardsize - 1) - first gli)
        set color orange
        set shape "triangle 2"
      ]
    ]
  ]
  report grouplist
  end

to-report capture[m g] ; matrix group
  let x 0
  let y 0
  foreach g[
    gi ->
    set x first gi
    set y item 1 gi
    matrix:set m x y 0
  ]
  report m
end


to g-capture [g] ;; graphical-capture shouldn be called on void square, player should be 1 or 2, just to simplify code
  foreach g
  [
    gli ->  ;;group list item
      ask patch item 1 gli ((boardsize - 1) - first gli)
      [
        ask pieces-here [ die ]
      ]
    ]
end


to-report perimeter-color[m group]  ;; mostly to calculate score
  let perimetercolor -1 ;; cause its better than zero for debuugging reasons
  let groupcolor matrix:get m first first group item 1 first group ;; assuming group has at least 1 element OFC
  foreach group [
    pos ->
    let x first pos
    let y item 1 pos
    if ((y + 1 < boardsize) and (matrix:get m x (y + 1) != groupcolor)) ;; or i can say its not in group, but faster this approach tho, O(1)
    [ ifelse (perimetercolor = -1)
      [set perimetercolor matrix:get m x (y + 1)]
      [if (perimetercolor != matrix:get m x (y + 1))
        [report -1] ;; means not all perimeters has the same color, it's NEUTRAL, i dont have to continue, it breaks
      ]
    ]

    if ((y - 1 >= 0) and (matrix:get m x (y - 1) != groupcolor)) ;; or i can say its not in group, but faster this approach tho, O(1)
    [ ifelse (perimetercolor = -1)
      [set perimetercolor matrix:get m x (y - 1)]
      [if (perimetercolor != matrix:get m x (y - 1))
        [report -1]
      ]
    ]

    if ((x + 1 < boardsize) and (matrix:get m (x + 1) y != groupcolor)) ;; or i can say its not in group, but faster this approach tho, O(1)
    [ ifelse (perimetercolor = -1)
      [set perimetercolor matrix:get m (x + 1) y]
      [if (perimetercolor != matrix:get m (x + 1) y)
        [report -1]
      ]
    ]

    if ((x - 1 >= 0) and (matrix:get m (x - 1) y != groupcolor)) ;; or i can say its not in group, but faster this approach tho, O(1)
    [ ifelse (perimetercolor = -1)
      [set perimetercolor matrix:get m (x - 1) y]
      [if (perimetercolor != matrix:get m (x - 1) y)
        [report -1]
      ]
    ]
  ]
  report perimetercolor ;; if it didn't break, reports the color of the omogeneous perimeter
end
@#$#@#$#@
GRAPHICS-WINDOW
190
43
484
338
-1
-1
57.3
1
10
1
1
1
0
1
1
1
0
4
0
4
0
0
1
ticks
30.0

BUTTON
23
10
86
43
Start
start
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
91
10
154
43
Play!
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
22
52
154
85
Max_iterations
Max_iterations
0
10000
10000.0
100
1
NIL
HORIZONTAL

SWITCH
23
99
153
132
debug
debug
1
1
-1000

SWITCH
22
206
153
239
blackstarts?
blackstarts?
0
1
-1000

MONITOR
23
146
151
191
NIL
boardsize
17
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

go
false
0
Circle -7500403 true true 135 135 30
Line -7500403 true 150 -135 150 405
Line -7500403 true 420 150 -120 150

godot
false
0
Line -7500403 true 435 300 -105 300
Line -7500403 true 300 -135 300 405
Circle -7500403 true true 135 135 30
Line -7500403 true 0 -135 0 405
Line -7500403 true 150 -135 150 405
Line -7500403 true 450 0 -90 0
Line -7500403 true 420 150 -120 150
Line -7500403 true 300 -135 300 405
Line -7500403 true 435 300 -105 300

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

o
false
0
Circle -7500403 true true 30 30 240
Circle -16777216 true false 60 60 180

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

recurs
false
0
Rectangle -7500403 true true 135 75 165 105
Line -7500403 true 150 105 120 165
Line -7500403 true 180 165 150 105
Line -7500403 true 150 105 150 165
Rectangle -7500403 true true 90 165 120 195
Rectangle -7500403 true true 135 165 165 195
Rectangle -7500403 true true 180 165 210 195

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
NetLogo 6.1.1
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
