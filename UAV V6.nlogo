;below are indicative abbreviations used:
; NS: Navigation Sensor , FC: Flight Control, FM: Flight Manager, MM: Mission Manager


globals[

  B_MM-path-xcor-list
  B_MM-path-ycor-list
  B_MM-contigency-path-xcor-list
  B_MM-contigency-path-ycor-list
  B_FM-path-xcor-list
  B_FM-path-ycor-list

  ;Navigation sensor beliefs
  B_NS-xcor
  B_NS-ycor

  ;Flight control beleifs
  B_FC-angle
  B_FC-face

  ;Flight Manager beliefs
  B_FM-next-waypoint
  B_FM-power
  B_1R-down
  B_Drop-Dead


  ;Payload agent belief
  B_PL-image

  ;communication link agent beliefs
  B_CL-data
  B_CL-image
  B_CL-down       ; command link status of Communication agent
  B_CL-commandLink-failure-counter



  ;will add other beliefs of FM later

  ;other variables
  total-waypoints
  image-count
  altitude
  standard-altitude



]

breed [UAVs uav]
breed [UAVWAYPOINTS  uavwpts]
breed [UAVMISSIONMANAGERS  missionManager]
breed [UAVFLIGHTCONTROLS  flightControl]
breed [UAVFLIGHTMANAGERS  flightManager]
breed [UAVNAVIGATIONSENSORS  navigationSensor]
breed [UAVCOMMUNICATIONLINKS  communicationLink]
breed [UAVPAYLOADS  payload]


to setup

  clear-all
  reset-ticks
  import-drawing "terrain 1.png" ; importing image
  set payload-present true
  set videoLink-failure false
  set commnadLink-failure false
  set B_CL-down false
  set one-rotor-failure false
  set Fuel-Status "Complete journey"
  set B_1R-down false
  set B_Drop-Dead false
  set standard-altitude 20
  set altitude standard-altitude
  set total-waypoints 6
  set-MM-Path-xcor-list
  set-MM-Path-ycor-list
  create-UAVs 1[set shape "airplane"
    set size 1
    set color black
    setxy  item 0 B_MM-path-xcor-list item 0 B_MM-path-ycor-list
    set label-color cyan
    pd
  ]

  setup-UAVWAYPOINTS
  setup-Agents

end



to setup-Agents

  create-UAVMISSIONMANAGERS 1[             ; missionManager is agent number 7
    set shape "dot"
    hide-turtle
  ]

  create-UAVFLIGHTCONTROLS 1[             ; flightControl is agent number 8
    set shape "dot"
    hide-turtle
  ]

  create-UAVFLIGHTMANAGERS 1[             ; flightManager is agent number 9
    set shape "dot"
    hide-turtle
  ]

  create-UAVNAVIGATIONSENSORS 1[             ; navigationSensor is agent number 10
    set shape "dot"
    hide-turtle
  ]

  create-UAVCOMMUNICATIONLINKS 1[             ; communicationLink is agent number 11
    set shape "dot"
    hide-turtle
  ]

  create-UAVPAYLOADS 1[             ; payload is agent number 12
    set shape "dot"
    hide-turtle
  ]
end



; called by setup to set waypoints
to setup-UAVWAYPOINTS

  create-UAVWAYPOINTS 6
  [
    set shape "flag"
    set size 1
    set color magenta
    set heading 0

  ]

  ask  uavwpts 1 [setxy item 0 B_MM-path-xcor-list item 0 B_MM-path-ycor-list set label "A" set label-color magenta]
  ask  uavwpts 2 [setxy item 1 B_MM-path-xcor-list item 1 B_MM-path-ycor-list set label "B" set label-color magenta]
  ask  uavwpts 3 [setxy item 2 B_MM-path-xcor-list item 2 B_MM-path-ycor-list set label "C" set label-color magenta]
  ask  uavwpts 4 [setxy item 3 B_MM-path-xcor-list item 3 B_MM-path-ycor-list set label "D" set label-color magenta]
  ask  uavwpts 5 [setxy item 4 B_MM-path-xcor-list item 4 B_MM-path-ycor-list set label "E" set label-color magenta]
  ask  uavwpts 6 [setxy item 5 B_MM-path-xcor-list item 5 B_MM-path-ycor-list set label "F" set label-color magenta]
end



; called by setup to set the waypoint info (x-coord) in MissionManager
to set-MM-Path-xcor-list

  set B_MM-path-xcor-list []
  set B_MM-path-xcor-list lput(-9) B_MM-path-xcor-list
  set B_MM-path-xcor-list lput(-13) B_MM-path-xcor-list
  set B_MM-path-xcor-list lput(-6) B_MM-path-xcor-list
  set B_MM-path-xcor-list lput(10) B_MM-path-xcor-list
  set B_MM-path-xcor-list lput(13.3) B_MM-path-xcor-list
  set B_MM-path-xcor-list lput(5) B_MM-path-xcor-list

end



; called by setup to set the waypoint info (y-coord) in MissionManager
to set-MM-Path-ycor-list

  set B_MM-path-ycor-list []
  set B_MM-path-ycor-list lput(-12) B_MM-path-ycor-list
  set B_MM-path-ycor-list lput(-4) B_MM-path-ycor-list
  set B_MM-path-ycor-list lput(8) B_MM-path-ycor-list
  set B_MM-path-ycor-list lput(5) B_MM-path-ycor-list
  set B_MM-path-ycor-list lput(9) B_MM-path-ycor-list
  set B_MM-path-ycor-list lput(-5) B_MM-path-ycor-list

end



; This is the main function of FlightManager. This function coordinates with other agents to move UAV. This function is called by button Go.
; to be done: remove if() constructs with a single while loop
to go

  ask missionManager 7[
    set-B_FM-path-xcor-list
    set-B_FM-path-ycor-list
  ]

  let end-point false
  let uavxcor 0  ; initialized with 0, should not matter
  let uavycor 0  ; initialized with 0, should not matter
  let commandLink-failure-counter 0      ; counts number of times command link has failed

  ask navigationSensor 10[
    set uavxcor getCurrentLocationX-NS
    set uavycor getCurrentLocationY-NS
  ]
  let at-Waypoint 0

  ;repeat until UAV reaches end point. End point in this case is waypoint 1 (same as starting point).
  while[B_Drop-Dead != true and end-point != true][

    ask flightManager 9[

      ; below if() conditions check for the waypoint at which UAV is currently present.
      if(uavxcor = item 0 B_FM-path-xcor-list) and (uavycor = item 0 B_FM-path-ycor-list)[
        set at-Waypoint 1
      ]

      if(abs (uavxcor - item 1 B_FM-path-xcor-list) <= 0.1 ) and (abs (uavycor - item 1 B_FM-path-ycor-list) <= 0.1 )[
        set at-Waypoint 2
      ]

      if(abs (uavxcor - item 2 B_FM-path-xcor-list) <= 0.1 ) and (abs (uavycor - item 2 B_FM-path-ycor-list) <= 0.1)[
        set at-Waypoint 3
      ]

      if(abs (uavxcor - item 3 B_FM-path-xcor-list) <= 0.1 ) and (abs (uavycor - item 3 B_FM-path-ycor-list) <= 0.1)[
        set at-Waypoint 4
        ;show at-Waypoint
      ]

      if(abs (uavxcor - item 4 B_FM-path-xcor-list) <= 0.1 ) and (abs (uavycor - item 4 B_FM-path-ycor-list) <= 0.1)[
        set at-Waypoint 5
        ;show at-Waypoint
      ]

      if(abs (uavxcor - item 5 B_FM-path-xcor-list) <= 0.1 ) and (abs (uavycor - item 5 B_FM-path-ycor-list) <= 0.1)[
        set at-Waypoint 6
        ;show at-Waypoint
      ]

      ; based on current waypoint of UAV , calculate next waypoint
      ; to be done: put this calculation in a different function. This calculation may need some modification for contigency plan
      set B_FM-next-waypoint (at-Waypoint + 1) mod total-waypoints
      if(B_FM-next-waypoint = 0)[set B_FM-next-waypoint total-waypoints]
    ]

    ask flightControl 8[
      fc-setUav-angle
    ]

    ask flightManager 9[
      ;set uav's altitude to standard-altitude in start of this leg of flight
      set altitude standard-altitude
      plot altitude

      ;move UAV to next waypoint
      ask uav 0[
        ;fd 1
        while[ abs (xcor - (item (B_FM-next-waypoint - 1) B_FM-path-xcor-list)) > 0.1 or abs (ycor - (item (B_FM-next-waypoint - 1) B_FM-path-ycor-list)) > 0.1][


          ;check the status of fuel
          check_fuel_status
          if B_Drop-Dead = true[
            stop
          ]




          ;check the status of rotor
          if(one-rotor-failure = true)[
            if (B_1R-down = false)[
              show "One rotor failure"
              set B_1R-down true
            ]

            ifelse(Fuel-Status = "Drop Dead")[
              show "No fuel. Dropping dead"
              set altitude 0
              plot altitude
              set B_Drop-Dead true
              stop
            ]
            ;else check if fuel is sufficient to return
            [
              if (Fuel-Status = "Return Journey")[
                return-home
              ]
            ]
          ]


          ;if command link failed and control is entering here for first time (checked using B_CL-down belief) then raise the UAV
          ifelse(commnadLink-failure = true)[
            if(B_CL-down = false)[
              ask communicationLink 11[
                set B_CL-commandLink-failure-counter (B_CL-commandLink-failure-counter + 1)
              ]
              ask communicationLink 11[
                set commandLink-failure-counter B_CL-commandLink-failure-counter
              ]
              ; raise the UAV only if command link failure counter is less than or equal to 2
              ifelse(commandLink-failure-counter <= 2)[
                raiseUp-and-find-commLink
              ]
              [
                show "command link lost"
                set B_CL-down true
              ]
            ]
          ]
          [
            ;if command link was down and became active recently
            if(B_CL-down = true)[
              show "Command link regained"
              set B_CL-down false
            ]
          ]


          fd .1
          plot altitude
          ask payload 12[

            ;check for video link failure

            ; video link is up
            ifelse(videoLink-failure = false)[
              take-image
              send-image-to-communicatioLink
              ask communicationLink 11[
                send-image-to-ground
              ]
            ]
            ; video link failed
            [
              ;check if onboard hard disk is present or not in case of failure

              ;onboard hard disk is present
              ifelse(payload-present)[
                take-image
                move-image-to-disk

              ]
              ;onboard hard disk is not present
              [
                ;function to return home
                return-home    ; need change, right now it is called again and again.

              ]
            ]
          ]
        ]

      ]
    ]

    ask navigationSensor 10[
      set uavxcor getCurrentLocationX-NS
      set uavycor getCurrentLocationY-NS
    ]

    ask flightManager 9[

      ; check if end-point is reached
      if(abs (uavxcor - item 0 B_FM-path-xcor-list) <= 0.1 ) and (abs (uavycor - item 0 B_FM-path-ycor-list) <= 0.1)[
        set end-point true
      ]
    ]

  ]

end



;this function raises the UAV up to search for communication link
to raiseUp-and-find-commLink
  show "UAV rising up and hovering to find command link"
  set altitude (altitude + 10)
  plot altitude
  wait 4

  ;if communication link is failed permanently then no point in flying at high altitude, come down
  ifelse(commnadLink-failure)[
    show "Command link not found"
    set B_CL-down true
  ]

  ; if communication regained at high altitude then keep flying at that altitude
  [
    show "command link regained"
  ]

end

to return-home
  if(B_FM-next-waypoint != 1)[
    show "UAV returning home"
    set B_FM-next-waypoint 1  ; do we need to backtrack path or directly go to waypoint 1 ? Right now directly go to 1
    ask flightControl 8[
      fc-setUav-angle
    ]
  ]
end


;check the status of fuel at each iteration
to check_fuel_status
  ifelse(Fuel-Status = "Drop Dead")[
    show "No fuel at iteration. Dropping dead"
    set altitude 0
    plot altitude
    set B_Drop-Dead true
    stop
  ]
  ;else check if fuel is sufficient to return
  [
    if (Fuel-Status = "Return Journey")[
      return-home
      ]
  ]




end



;payload takes the image of surrounding
to take-image

  set image-count (image-count + 1)
  set B_PL-image word "image " image-count

end



;payload sends the image to communication link
to send-image-to-communicatioLink

 set B_CL-image B_PL-image

end


; payload moves the image to onboard hard disk in case communication link fails
to move-image-to-disk

  show word B_PL-image " moved to onboard hard disk"
end



;communication link sends the image to ground control
to send-image-to-ground

  show word B_CL-image " sent to ground by onboard communication link agent"
end




;below function of FlightControl will set the head of UAV towards the next_wayPoint
to fc-setUav-angle
  ask uav 0[
   face uavwpts  B_FM-next-waypoint
  ]
end


; whenever current x-coordinate of uav is needed, call this function of Navigation sensor. The result will stored be in B_NS-xcor
to-report getCurrentLocationX-NS
  set B_NS-xcor [xcor] of uav 0
  report B_NS-xcor
end


; whenever current y-coordinate of uav is needed, call this function of Navigation sensor. The result will stored be in B_NS-ycor
to-report getCurrentLocationY-NS
  set B_NS-ycor [ycor] of uav 0
  report B_NS-ycor
end


;called by function go to provide waypoints information (x-coordinates) to FlightManager by (MissionManager)
to set-B_FM-path-xcor-list
  set B_FM-path-xcor-list []
  foreach B_MM-path-xcor-list[
    set B_FM-path-xcor-list lput(?) B_FM-path-xcor-list
  ]

end


;called by function go to provide waypoints information (y-coordinates) to FlightManager by (MissionManager)
to set-B_FM-path-ycor-list
  set B_FM-path-ycor-list []
  foreach B_MM-path-ycor-list[
    set B_FM-path-ycor-list lput(?) B_FM-path-ycor-list
  ]
end





;CODE ENDS HERE -------------------+++++++++++++++++++++++------------------------------------------------
@#$#@#$#@
GRAPHICS-WINDOW
180
18
782
641
16
16
17.94
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
49
284
127
317
set up
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
48
326
127
359
Go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
-1
368
173
401
payload-present
payload-present
0
1
-1000

SWITCH
-5
402
173
435
videoLink-failure
videoLink-failure
1
1
-1000

PLOT
994
178
1240
372
UAV altitude
time
altitude
0.0
10.0
0.0
35.0
true
false
"" ""
PENS
"altitude" 3.0 0 -16777216 true "" "plot altitude"

SWITCH
-1
242
147
275
one-rotor-failure
one-rotor-failure
1
1
-1000

CHOOSER
0
185
147
230
Fuel-Status
Fuel-Status
"Complete journey" "Return Journey" "Drop Dead"
0

SWITCH
-5
437
174
470
commnadLink-failure
commnadLink-failure
1
1
-1000

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
NetLogo 5.3.1
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
