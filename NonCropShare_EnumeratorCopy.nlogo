extensions [bitmap]

breed [crops crop]
breed [dividers divider]
breed [scorecards scorecard]

patches-own [player choice previousChoice currentScore currentNCHBonus currentYield currentSpending scoreWho cropWho taps]
scorecards-own [identity playerNumber]


globals [numPlayers 
  playerHHID
  playerShortNames
  playerNames 
  playerNameLengths
  playerDomains 
  playerScores
  playerCurrentScores
  playerCurrentSpending
  playerCurrentBonus
  playerCurrentYield
  playerInfoTracker
  playerThinkTimes
  midX midY 
  playerPosition
  choiceColors
  grayedChoiceColors
  confirmedChoiceColors
  confirmChoice
  centerPatches
  inGame
  gameName
  currentRound
  minNumRounds
  maxNumRounds
  maxNCHYield
  currentInfoScreen
  confirmButton
  confirmPixLoc
  yieldText
  yieldPixLoc
  costsText
  costsPixLoc
  nchBonusText
  nchBonusPixLoc
  scoreText
  scorePixLoc
  totalScoreText
  totalScorePixLoc
  prevRoundText
  prevRoundPixLoc
  roundText
  roundPixLoc
  langSuffix
  fontSize
  roundStartTimes
  inputFileLabels
  parsedInput
  currentSessionParameters
  farmX
  farmY
  numRounds
  baseYield
  maxYield
  nchYield
  nchBoost
  nchNeighborhood
  heavySprayBlockNeighborhood
  lightSprayBoost
  lightSprayCost
  heavySprayBoost
  heavySprayCost
  showMoves
  gameTag
  appendDateTime
  completedGamesIDs
        ]

to startup
  hubnet-reset
  file-close
  
  set playerNames (list)
  set playerShortNames (list)
  set playerHHID (list)
  set playerPosition (list)
  set playerThinkTimes (list)
  set numPlayers 0
  set choiceColors [35 35 35 35]
  set grayedChoiceColors [38 38 38 38]
  set confirmedChoiceColors [32 32 32 32]
  set inGame 0
  set currentRound 1
  set minNumRounds 8
  set maxNumRounds 12
  set maxNCHYield 12
  set appendDateTime true
  set-default-shape scorecards "blank"
  set-default-shape dividers "line"
  clear-ticks
  clear-patches
  clear-turtles
  clear-drawing
  

  file-open "experimentOrderingList.csv"
  let fullDataList []
  let foundEndLabel 0
  let lengthList 0
  while [not file-at-end?] [
    let tempValue file-read
    if (not is-string? tempValue and foundEndLabel = 0) [set foundEndLabel 1 set lengthList length fullDataList]
    set fullDataList lput tempValue fullDataList 
  ] 
  set inputFileLabels sublist fullDataList 0 lengthList
  set fullDataList sublist fullDataList lengthList length fullDataList
  file-close
  
  set completedGamesIDs []
  ifelse file-exists? "completedGames.csv" [
  file-open "completedGames.csv"
  while [not file-at-end?] [
    let tempValue file-read-line
    set completedGamesIDs lput read-from-string substring tempValue 0 position "_" tempValue completedGamesIDs
  ] 
  set completedGamesIDs remove-duplicates completedGamesIDs
  set sessionID max completedGamesIDs + 1
  file-close
  ] [
  set sessionID -9999
  ]
  
  ;; first element in each line is ID
  set parsedInput [[]]
  let currentID 0
  while [length fullDataList > 0] [
    let currentSubList sublist fullDataList 0 lengthList
    set fullDataList sublist fullDataList lengthList length fullDataList
    
    if (item 0 currentSubList != currentID) [set currentID item 0 currentSubList set parsedInput lput [] parsedInput]
    set parsedInput replace-item currentID parsedInput (lput currentSubList item currentID parsedInput)
  ]

  set currentSessionParameters []
end

to initialize-session
  
    if (length currentSessionParameters > 0) 
  [user-message "Current session is not complete.  Please continue current session.  Otherwise, to start new session, please first clear settings by clicking 'Launch Broadcast'"
    stop]
  
      if (sessionID > length parsedInput or sessionID < 1)
  [user-message "Session ID not found in input records"
    stop]
  
      if (member? sessionID completedGamesIDs)
  [user-message "Warning: At least one game file with this sessionID has been found"]
     
  set currentSessionParameters item sessionID parsedInput
  
end

to set-game-parameters
  
  let currentGameParameters item 0 currentSessionParameters
  set currentSessionParameters sublist currentSessionParameters 1 length currentSessionParameters
  
  (foreach inputFileLabels currentGameParameters [
      ifelse ?1 = "gameID" [
        ifelse ?2 = 0 [ set gameTag "GP" output-print (word "Game: GP") file-print (word "Game: GP")] [ set gameTag (word "G" ?2) output-print (word "Game: G" ?2) file-print (word "Game: G" ?2)] 
        output-print " "
        output-print " "
        output-print "Relevant Game Parameters:"
        output-print " "
      ] [
      ifelse ?1 = "showMoves" [
        ifelse ?2 = 0 [ 
          set showMoves "onEndTurn" output-print (word "Show moves: At end turn")
          file-print (word "Show moves: At end turn")
          ] 
        [ 
          set showMoves "onConfirm" output-print (word "Show moves: At confirm")
          file-print (word "Show moves: At confirm")
          ] 
      ] [
      if ?1 = "nchYield" [
        output-print (word ?1 ": " ?2)
      ]
      if ?1 = "numRounds" [
        output-print (word ?1 ": " ?2)
      ]
      run(word "set " ?1 " " ?2 )
      file-print (word ?1 ": " ?2 )
      ]
      ]
  ])
  file-print ""
  
end

to set-new-game

  if (inGame = 1) 
  [user-message "Current game is not complete.  Please continue current game.  Otherwise, to start new session, please first clear settings by clicking 'Launch Broadcast'"
    stop]
  
  clear-output
   
  if (length currentSessionParameters = 0)
  [user-message "No games left in session.  Re-initialize or choose new session ID"
    stop]

  if (length playerNames != 4)
  [user-message "Need 4 Players!"
    stop]

  
  if inGame = 1 [end-game]  ;; just to save any previous game, in case it didn't get ended properly
   
 
                            ;; make game file
  let tempDate date-and-time
  foreach [2 5 8 12 15 18 22] [set tempDate replace-item ? tempDate "_"]
  set gameName (word sessionID "_" gameTag "_" (item 0 playerNames) "_" (item 1 playerNames) "_" (item 2 playerNames) "_" (item 3 playerNames) (ifelse-value appendDateTime [word "_" tempDate ] [""]) ".csv" )
  carefully [file-delete gameName file-open gameName] [file-open gameName]
  
  ;;Initialize game file
  file-print word "Player 1 Name: " (item 0 playerShortNames)
  file-print word "Player 2 Name: " (item 1 playerShortNames)
  file-print word "Player 3 Name: " (item 2 playerShortNames)
  file-print word "Player 4 Name: " (item 3 playerShortNames)
  file-print word "Player 1 HHID: " (item 0 playerHHID)
  file-print word "Player 2 HHID: " (item 1 playerHHID)
  file-print word "Player 3 HHID: " (item 2 playerHHID)
  file-print word "Player 4 HHID: " (item 3 playerHHID)
  file-print ""
  
  set-game-parameters
  
   ask scorecards [die ]
  
  clear-patches
  clear-turtles
  clear-drawing
   
  if language = "English" [ set langSuffix "en"]
  if language = "Khmer" [ set langSuffix "kh"]
  if language = "Chinese" [ set langSuffix "cn"]
  if language = "Vietnamese" [ set langSuffix "vn"]
    
  set fontSize 50 ;; this is just a reference, it DOES NOT SET FONT SIZE.  change this if you change the size of the fonts in the view, this is used to help align player names
  
  ;; set other game parameters
  set confirmChoice (list 0 0 0 0)
  set playerScores (list 0 0 0 0)
  set playerCurrentScores (list 0 0 0 0)
  set playerCurrentYield (list 0 0 0 0)
  set playerCurrentBonus (list 0 0 0 0)
  set playerCurrentSpending (list 0 0 0 0)
  set playerInfoTracker (list 0 0 0 0)
  set playerThinkTimes (list 0 0 0 0)
  set roundStartTimes (list)
  set inGame 1
  set currentRound 1
  set currentInfoScreen 0
  
  set playerNameLengths (list 0 0 0 0)
  foreach playerShortNames [
   set playerNameLengths replace-item (position ? playerShortNames) playerNameLengths (length ?) 
  ]
  
  ;;Whatever size the world is, there is a buffer of 5 patches across on the left side that is used for game information
  resize-world -5 (farmX * 2 - 1) 0 (farmY * 2 - 1) ;; use the spaces -5 through -1 to display information about game
  
  ;;get farm size from world size
  set midX (max-pxcor - 0) / 2
  set midY (max-pycor - 0) / 2
 
  ;;assign domain to players
  ask patches with [pxcor >= 0] [
    ifelse (pxcor < midX and pycor < midY) [set player 1]
     [ifelse (pxcor > midX and pycor < midY) [set player 2]
       [ifelse (pxcor > midX and pycor > midY) [set player 3]
        [set player 4]
      ]
    ]  
  ]
  
  ;;The following code fixes the locations and sizes of the in-game text.  It was optimized to an 11 x 6 box with a patch size of 112 pixels, for use with a Dell Venue 8 as a client.
  ;;The structure of the location variables is [xmin ymin width height].  They have been 'converted' to scale with a changing patch size and world size, but this is not widely tested
  let yConvertPatch (farmY / 3)  ;;scaling vertical measures based on the currently optimized size of 6
  let xyConvertPatchPixel (patch-size / 112)  ;; scaling vertical and horizontal measures based on currently optimized patch size of 112
  
  
  set confirmPixLoc (list (20 * xyConvertPatchPixel) (20 * yConvertPatch * xyConvertPatchPixel) (200 * xyConvertPatchPixel) (125 * yConvertPatch * xyConvertPatchPixel))
  set yieldPixLoc (list (25 * xyConvertPatchPixel) (295 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set costsPixLoc (list (25 * xyConvertPatchPixel) (435 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set nchBonusPixLoc (list (25 * xyConvertPatchPixel) (365 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set scorePixLoc (list (25 * xyConvertPatchPixel) (500 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set totalScorePixLoc (list (25 * xyConvertPatchPixel) (585 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set prevRoundPixLoc (list (10 * xyConvertPatchPixel) (210 * yConvertPatch * xyConvertPatchPixel) (350 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  set roundPixLoc (list (250 * xyConvertPatchPixel)  (50 * yConvertPatch * xyConvertPatchPixel) (175 * xyConvertPatchPixel) (70 * yConvertPatch * xyConvertPatchPixel))
  
  set confirmButton bitmap:import (word "./image_label/confirm_" langSuffix ".png")
  set yieldText bitmap:import (word "./image_label/yield_" langSuffix ".png")
  set costsText bitmap:import (word "./image_label/costs_" langSuffix ".png")
  set nchBonusText bitmap:import (word "./image_label/nchBonus_" langSuffix ".png")
  set scoreText bitmap:import (word "./image_label/score_" langSuffix ".png")
  set totalScoreText bitmap:import (word "./image_label/totalScore_" langSuffix ".png")
  set prevRoundText bitmap:import (word "./image_label/prevRound_" langSuffix ".png")
  set roundText bitmap:import (word "./image_label/round_" langSuffix ".png")

               
  bitmap:copy-to-drawing (bitmap:scaled confirmButton (item 2 confirmPixLoc) (item 3 confirmPixLoc)) (item 0 confirmPixLoc) (item 1 confirmPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled yieldText (item 2 yieldPixLoc) (item 3 yieldPixLoc)) (item 0 yieldPixLoc) (item 1 yieldPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled costsText (item 2 costsPixLoc) (item 3 costsPixLoc)) (item 0 costsPixLoc) (item 1 costsPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled nchBonusText (item 2 nchBonusPixLoc) (item 3 nchBonusPixLoc)) (item 0 nchBonusPixLoc) (item 1 nchBonusPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled scoreText (item 2 scorePixLoc) (item 3 scorePixLoc)) (item 0 scorePixLoc) (item 1 scorePixLoc)
  bitmap:copy-to-drawing (bitmap:scaled totalScoreText (item 2 totalScorePixLoc) (item 3 totalScorePixLoc)) (item 0 totalScorePixLoc) (item 1 totalScorePixLoc)
  bitmap:copy-to-drawing (bitmap:scaled prevRoundText (item 2 prevRoundPixLoc) (item 3 prevRoundPixLoc)) (item 0 prevRoundPixLoc) (item 1 prevRoundPixLoc)
  bitmap:copy-to-drawing (bitmap:scaled roundText (item 2 roundPixLoc) (item 3 roundPixLoc)) (item 0 roundPixLoc) (item 1 roundPixLoc)
    
  set centerPatches (patch-set patch (floor midX / 2) (floor midY / 2) patch (floor 3 * midX / 2) (floor midY / 2)  patch (floor midX / 2) (floor 3 * midY / 2) patch (floor 3 * midX / 2) (floor 3 * midY / 2))
                  
  ask patches with [pxcor >= 0] [set choice 0 set previousChoice 0
    set pcolor item choice choiceColors
    sprout-crops 1 [let currentWho who ask patch-here [set cropWho currentWho] set shape "crop-base"]
    sprout-scorecards 1 [let currentWho who ask patch-here [set scoreWho currentWho] setxy (xcor - .2) (ycor + .2) set label-color black set identity "currentAndFinalScore"]
    ]
  
  ;;lay out the agents that will provide score information.  These too are optimized to a Dell Venue 8, with farm size 3 and 3, patch size 112, and may need adjustments if changes are made             
  create-scorecards 1 [setxy -1.5 max-pycor set label currentRound set identity "currentRound" set label-color yellow]
  create-scorecards 1 [setxy -1.75 (max-pycor - 2.2  * yConvertPatch) set label 0 set identity "yield"]
  create-scorecards 1 [setxy -1.75 (max-pycor - 2.8  * yConvertPatch) set label 0 set identity "bonus"]
  create-scorecards 1 [setxy -1.75 (max-pycor - 3.4 * yConvertPatch) set label 0 set identity "costs"]
  create-scorecards 1 [setxy -1.75 (max-pycor - 4 * yConvertPatch) set label 0 set identity "currentScore"]
  create-scorecards 1 [setxy -1.5 (max-pycor - 4.75 * yConvertPatch) set label 0 set identity "totalScore" set label-color red]
  create-scorecards 1 [setxy (midX / 2 - 0.75 + (item 0 playerNameLengths * fontSize / patch-size / 4)) midY / 2 set identity "playerName" set playerNumber 1 set label-color black]
  create-scorecards 1 [setxy (3 * midX / 2 - 0.25 + (item 1 playerNameLengths * fontSize / patch-size / 4)) midY / 2 set identity "playerName" set playerNumber 2 set label-color black]
  create-scorecards 1 [setxy (3 * midX / 2  - 0.25 + (item 2 playerNameLengths * fontSize / patch-size / 4)) (3 * midY / 2) + 0.5 set identity "playerName" set playerNumber 3 set label-color black]
  create-scorecards 1 [setxy (midX / 2 - 0.75  + (item 3 playerNameLengths * fontSize / patch-size / 4)) (3 * midY / 2) + 0.5 set identity "playerName" set playerNumber 4 set label-color black]
  
  ;;Add dividers between players
  let currentX 0
  let currentY 0
  while [currentY < max-pycor] [
    set currentX 0
    while [currentX < max-pxcor] [
      create-dividers 1 [setxy currentX  currentY + 0.5 facexy xcor - 1 ycor set color gray ]
    set currentX currentX + 1  
    ]
    create-dividers 1 [setxy currentX  currentY + 0.5 facexy xcor - 1 ycor set color gray ]
    set currentY currentY + 1    
  ]
  
  set currentX 0
  set currentY 0
  while [currentX < max-pxcor] [
    set currentY 0
    while [currentY < max-pycor] [
    create-dividers 1 [setxy currentX + 0.5 currentY facexy xcor ycor - 1 set color gray ]
    set currentY currentY + 1  
    ]
    create-dividers 1 [setxy currentX + 0.5 currentY facexy xcor ycor - 1 set color gray ]
    set currentX currentX + 1
    
  ]
  
  set currentX 0
  while [currentX <= max-pxcor] [
    create-dividers 1 [setxy currentX midY facexy xcor - 1 ycor set color black  ]
    set currentX currentX + 1  
  ]
  set currentY 0
  while [currentY <= max-pycor] [
   create-dividers 1 [setxy midX currentY facexy xcor ycor - 1 set color black  ]
   set currentY currentY + 1  
  ]  
  
  ;;Send overrides to clients for displays
  gray-out-others
  
    ;; make game file
  ;;let tempDate date-and-time
  ;;foreach [2 5 8 12 15 18 22] [set tempDate replace-item ? tempDate "_"]
  ;;set gameName (word sessionID "_" gameTag "_" (item 0 playerNames) "_" (item 1 playerNames) "_" (item 2 playerNames) "_" (item 3 playerNames) (ifelse-value appendDateTime [word "_" tempDate ] [""]) ".csv" )
  ;;carefully [file-delete gameName file-open gameName] [file-open gameName]
  
  file-print (word "Land Ownership:")
  file-print ""
  
  ;; write landscape to file
  let currentRow max-pycor
  while [currentRow >= 0] [
    let currentColumn 0
    while [currentColumn < max-pxcor] [
      ;;print (word currentColumn currentRow)
      
      ask (patch currentColumn currentRow) [file-write player] 
      set currentColumn currentColumn + 1
    ]
    ask patch currentColumn currentRow [file-print (word " " player) ]
    set currentRow currentRow - 1 
  ]
  file-print ""
  
  set roundStartTimes lput date-and-time roundStartTimes
  file-print word "Game Start Time: " item (currentRound - 1) roundStartTimes 
  file-print  ""
end


to listen
  
  while [hubnet-message-waiting?] [
    hubnet-fetch-message    
    ifelse hubnet-enter-message?[
      
      ifelse (member? hubnet-message-source playerNames) [ 
        ;; pre-existing player whose connection cut out
        let newMessage word hubnet-message-source " is back."
        hubnet-broadcast-message newMessage
        
        let currentMessagePosition (position hubnet-message-source playerNames);  0 to 3
        let currentPlayer currentMessagePosition + 1
        send-game-info currentMessagePosition
        if (currentInfoScreen = 1) [
          
          ask scorecards with [identity = "playerName"] [
            hubnet-send-override (item (position currentPlayer playerPosition) playerNames) self "label" [""] 
          ]
          ask patches [
            ;; if ? = player [
            hubnet-clear-override  (item (position currentPlayer playerPosition) playerNames) self "pcolor" 
            ask crops-here [hubnet-clear-override  (item (position currentPlayer playerPosition) playerNames) self "shape"  ]
            ;; ]
          ] ;; end ask patches 
          
         stop 
        ]

        
        gray-out-others 
        if (showMoves = "onConfirm" and currentInfoScreen = 0)[
          reveal-confirm
        ]  
        if item currentMessagePosition confirmChoice = 1 [
          ask patches [
            if currentPlayer = player [          
              hubnet-send-override  (item (position currentPlayer playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
            ]
          ]  
        ] 
      ] ;; end previous player re-entering code
      [ if (length playerNames < 4) [;; new player
        let tempName hubnet-message-source
        let hasHHID position "_" tempName
        let tempID []
        ifelse hasHHID != false [
          set tempID substring tempName (hasHHID + 1) (length tempName)
          set tempName substring tempName 0 hasHHID
          ] [
          set tempID 0
          ]
        set playerShortNames lput tempName playerShortNames
        set playerNames lput hubnet-message-source playerNames
        set playerHHID lput tempID playerHHID
        set numPlayers numPlayers + 1
        set playerPosition lput numPlayers playerPosition
      ]
      ]  ;; end new player code
    ] ;; end ifelse enter
    [
      ifelse hubnet-exit-message?
      [
        let newMessage word hubnet-message-source " has left.  Waiting."
        hubnet-broadcast-message newMessage
      ] ;; end ifexit
      
      
      [if inGame = 1 [
        
        let currentMessagePosition (position hubnet-message-source playerNames);  0 to 3
        let currentPlayer (currentMessagePosition + 1); 1 to 4
        
        if hubnet-message-tag = "View" [
          
          let xPixel ((item 0 hubnet-message) - min-pxcor + 0.5) * patch-size
          let yPixel (max-pycor + 0.5 - (item 1 hubnet-message)) * patch-size
          let xPixMin item 0 confirmPixLoc
          let xPixMax item 0 confirmPixLoc + item 2 confirmPixLoc
          let yPixMin item 1 confirmPixLoc
          let yPixMax item 1 confirmPixLoc + item 3 confirmPixLoc
          ifelse xPixel > xPixMin and xPixel < xPixMax and yPixel > yPixMin and yPixel < yPixMax [  ;; player "clicked"  confirm 
            confirm currentPlayer currentMessagePosition
          ] [ ;; it's not confirm but could be a land change
          ask patches with [pxcor = (round item 0 hubnet-message) and pycor = (round item 1 hubnet-message)][
              if currentPlayer = player and item (player - 1) confirmChoice = 0 [  ;;only change color if it's in the players domain and choices not confirmed
                set choice new-choice choice
                set taps taps + 1
                update-crop-image 
              ]
            ]
            ]
        ] ;; end ifelse view
        
      ] 
      ]
    ] 
  ]
  
  
end

to reveal-confirm
 
  ask patches with [pxcor >= 0] [
    if item (player - 1) confirmChoice = 1 [    
      foreach playerPosition [
        if ? != player [
          hubnet-send-override  (item (position ? playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
          ask crops-here [
            hubnet-clear-override  (item (position ? playerPosition) playerNames) self "shape" 
          ]
        ]
      ]    
    ]
  ]
  
end

to confirm [currentPlayer currentMessagePosition]
 
 if currentInfoScreen > 0 [stop]  ;if we aren't actively in a round, this shouldn't do anything, just exit
 
  set confirmChoice replace-item currentMessagePosition confirmChoice 1
  set playerThinkTimes replace-item currentMessagePosition playerThinkTimes date-and-time
  ask patches [
    if currentPlayer = player [
      
      hubnet-send-override  (item (position currentPlayer playerPosition) playerNames) self "pcolor" [item choice confirmedChoiceColors]
      if showMoves = "onConfirm" [
        reveal-confirm
      ]
    ]
  ]
  if sum confirmChoice = 4 [ ;; we've completed the turn  
    
    file-print (word "Round " currentRound " Choices")
    file-print ""
    
    ;; write landscape to file
    let currentRow max-pycor
    while [currentRow >= 0] [
      let currentColumn 0
      while [currentColumn < max-pxcor] [
        ;;print (word currentColumn currentRow)
        
        ask (patch currentColumn currentRow) [file-write choice] 
        set currentColumn currentColumn + 1
      ]
      ask patch currentColumn currentRow [file-print (word " " choice)]
      set currentRow currentRow - 1 
    ]
    file-print ""
        
    file-print (word "Round " currentRound " Taps")
    file-print ""
    
    ;; write landscape to file
    set currentRow max-pycor
    while [currentRow >= 0] [
      let currentColumn 0
      while [currentColumn < max-pxcor] [
        ;;print (word currentColumn currentRow)
        
        ask (patch currentColumn currentRow) [file-write taps set taps 0] 
        set currentColumn currentColumn + 1
      ]
      ask patch currentColumn currentRow [file-print (word " " taps) set taps 0]
      set currentRow currentRow - 1 
    ]
    file-print ""
    
    file-print (word "Player 1 Confirm Time Round " currentRound ": " (item 0 playerThinkTimes))
    file-print (word "Player 2 Confirm Time Round " currentRound ": " (item 1 playerThinkTimes))
    file-print (word "Player 3 Confirm Time Round " currentRound ": " (item 2 playerThinkTimes))
    file-print (word "Player 4 Confirm Time Round " currentRound ": " (item 3 playerThinkTimes))
    file-print ""
     
    ;; calculate score
    calculate-score
      
    foreach playerPosition [
      ask scorecards with [identity = "playerName"] [
       hubnet-send-override (item (position ? playerPosition) playerNames) self "label" [""] 
      ]
      ask patches [
        ;; if ? = player [
        hubnet-clear-override  (item (position ? playerPosition) playerNames) self "pcolor" 
        ask crops-here [hubnet-clear-override  (item (position ? playerPosition) playerNames) self "shape"  ]
        ;; ]
      ] ;; end ask patches 
    ] ;; end foreach player
    
    set currentInfoScreen 1

  ] ;; end if completed turn
  
end

to-report new-choice [currentChoice]
  
  set currentChoice currentChoice + 1
  if (currentChoice = 4) [set currentChoice 0]
  
  report currentChoice
end

to end-game
  set inGame 0
  file-close
  
  file-open "completedGames.csv"
  file-print gameName
  file-close
end

to clear-board
  set currentRound 0
  ask patches with [pxcor >= 0] [
    set pcolor item choice confirmedChoiceColors
  ]
  ask centerPatches [
    foreach playerPosition [
      ask scorecards with [identity = "playerName"] [
        hubnet-clear-override (item (position ? playerPosition) playerNames) self "label" 
      ]
    ]
    ;;ask scorecards-here with [identity = "playerName"] [ set label "" ] 
    ask scorecards-here with [identity = "currentAndFinalScore"] [
      let myScore (item (player - 1) playerScores)
      set label myScore
      set label-color red
    ]
    ask scorecards-here with [identity = "playerName" and playerNumber = 1][setxy (midX / 2 - 0.75 + (item 0 playerNameLengths * fontSize / patch-size / 4)) midY / 2 + midY / 4 set label (item 0 playerShortNames) ]
    ask scorecards-here with [identity = "playerName" and playerNumber = 2][setxy (3 * midX / 2 - 0.25 + (item 1 playerNameLengths * fontSize / patch-size / 4)) midY / 2 + midY / 4 set label (item 1 playerShortNames)]
    ask scorecards-here with [identity = "playerName" and playerNumber = 3][setxy (3 * midX / 2  - 0.25 + (item 2 playerNameLengths * fontSize / patch-size / 4)) (3 * midY / 2) + 0.5 + midY / 4 set label (item 2 playerShortNames)]
    ask scorecards-here with [identity = "playerName" and playerNumber = 4][setxy (midX / 2 - 0.75  + (item 3 playerNameLengths * fontSize / patch-size / 4)) (3 * midY / 2) + 0.5 + midY / 4 set label (item 3 playerShortNames)]
  ]
  ask crops [die]
end

to rand-nch-yield
  set nchYield (random (maxNCHYield - 1)) + 1
end

to rand-num-rounds
  set numRounds (random (maxNumRounds - minNumRounds)) + minNumRounds
end

to calculate-score
  
  ;; 0: base, no action
  ;; 1: NCH
  ;; 2: light spray
  ;; 3: heavy spray
  
  ask patches [
    
    set currentYield 0 
    set currentNCHBonus 0 
    set currentSpending 0
    set currentScore 0
    
    if choice = 0 [set currentYield baseYield]
    if choice = 1 [set currentYield nchYield]
    if choice = 2 [set currentYield baseYield + lightSprayBoost set currentSpending lightSprayCost]
    if choice = 3 [set currentYield baseYield + heavySprayBoost set currentSpending heavySprayCost]
       
   ] ;; end ask patches set yields
   
  ask patches [
    if choice = 1 [
      let myX pxcor
      let myY pycor
      let nchBeneficiaries patches with [(pxcor <= (myX + nchNeighborhood)) and (pxcor >= (myX - nchNeighborHood)) and pycor <= myY + nchNeighborhood and (pycor >= (myY - nchNeighborHood)) ]
      ask nchBeneficiaries [set currentNCHBonus currentNCHBonus + nchBoost] 
      
    ]
    
  ] ;; end ask patches set benefits
  
  ask patches [
    if choice = 1 [ set currentNCHBonus 0 ]
  ]
  
  ask patches [
    if choice = 3 [
      let myX pxcor
      let myY pycor
      let heavySpraySuckers patches with [(pxcor <= (myX + heavySprayBlockNeighborhood)) and (pxcor >= (myX - heavySprayBlockNeighborhood)) and (pycor <= (myY + heavySprayBlockNeighborhood)) and (pycor >= (myY - heavySprayBlockNeighborhood)) ]
      ask heavySpraySuckers [set currentNCHBonus 0]
    ]
  ] ;; end ask patches block benefits
  
  ask patches with [pxcor >= 0] [
    let cappedYield min (list maxYield (currentYield + currentNCHBonus))
    set currentNCHBonus cappedYield - currentYield
    set currentScore cappedYield - currentSpending
    ask scorecard scoreWho [set label currentScore]
  ]
  
  file-print (word "Round " currentRound " Scoring Summary:")
  file-print ""
  
  foreach playerPosition [
    let tempScore (sum [currentScore] of patches with [player = ?])
    let tempYields (sum [currentYield] of patches with [player = ?])
    let tempBonuses (sum [currentNCHBonus] of patches with [player = ?])
    let tempSpending (sum [currentSpending] of patches with [player = ?])
    set playerCurrentScores replace-item (? - 1) playerCurrentScores tempScore
    set playerCurrentYield replace-item (? - 1) playerCurrentYield tempYields
    set playerCurrentBonus replace-item (? - 1) playerCurrentBonus tempBonuses
    set playerCurrentSpending replace-item (? - 1) playerCurrentSpending tempSpending
    set playerScores replace-item (? - 1) playerScores (item (? - 1) playerScores + tempScore)
    file-print (word "Player " ? ": Yields " tempYields ", Bonuses " tempBonuses ", Spending " tempSpending ", Round Score " tempScore ", Total Score " (item (? - 1) playerScores))
  ]
  file-print ""
end

to send-game-info [currentPosition]
  
  ask scorecards with [identity = "yield"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playercurrentYield)] ]
  ask scorecards with [identity = "bonus"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerCurrentBonus)] ]
  ask scorecards with [identity = "costs"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerCurrentSpending)] ]
  ask scorecards with [identity = "currentScore"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerCurrentScores)] ]
  ask scorecards with [identity = "totalScore"]  [hubnet-send-override (item currentPosition playerNames) self "label" [(item currentPosition playerScores)] ]
       
end

to clear-information
  
  if sum confirmChoice = 4 [ ;; only do anything if we are at the end of the round
  ifelse  currentInfoScreen  = 1 [ ;; clear first info screen, load next
    set currentInfoScreen 2
    ask scorecards with [xcor > -1] [
      set label ""
    ]  
    ask centerPatches [
      let myScore (item (player - 1) playerCurrentScores)
      ask scorecards-here with [identity = "currentAndFinalScore"] [
        set label myScore
      ]
    ]
   
       foreach (playerPosition) [
      send-game-info (? - 1)
    ]
        
  ] 
  [ ;; clear 2nd info screen, move into next round
    
    ask centerPatches [
      ask scorecards-here [
        set label ""
      ]
    ]
    
    if inGame = 1 [ ;; haven't ended the game
 
    
  
    
    ;; let player modify screen again...
    set confirmChoice (list 0 0 0 0)
    set currentInfoScreen 0
    
    ;;update any other variables
    ifelse currentRound < numRounds [
      set currentRound currentRound + 1
      ask scorecards with [identity = "currentRound"] [set label currentRound] 
      ask patches [set previousChoice choice]
      
      set roundStartTimes lput date-and-time roundStartTimes
      file-print (word "Round " currentRound " Start Time: " item (currentRound - 1) roundStartTimes)
      file-print  ""
    ] [
    end-game
    clear-board
    ]
   
     ;; have to re-spray things ...
    ask patches with [pxcor >= 0] [if choice != 1 [set choice 0] update-crop-image]
    ] 
    
     gray-out-others

  ]
  ]
                
end

to update-crop-image
  set pcolor item choice choiceColors
  ask crops-here [
    ifelse choice = 0 [
      set shape "crop-base"
    ] [ ifelse choice = 1 [
      
      set shape "non-crop"
      
    ] [ ifelse choice = 2 [
      set shape "crop-spray-light"
      
    ] [
    
    set shape "crop-spray-heavy"
    ]
    
    ]
    ]
  ] 
  
end
to gray-out-others
  
  foreach playerPosition [
    ask patches with [pxcor >= 0] [
      hubnet-clear-override  (item (position ? playerPosition) playerNames) self "pcolor" 
      ask crops-here [hubnet-clear-override  (item (position ? playerPosition) playerNames) self "shape" ]
      if ? != player [
        hubnet-send-override  (item (position ? playerPosition) playerNames) self "pcolor" [item previousChoice grayedChoiceColors]
        
        ask crops-here [
          ifelse previousChoice = 0 [
            hubnet-send-override  (item (position ? playerPosition) playerNames) self "shape" ["crop-base"]
          ] [ ifelse previousChoice = 1 [
            
            hubnet-send-override  (item (position ? playerPosition) playerNames) self "shape" ["non-crop"]
            
          ] [ ifelse previousChoice = 2 [
            hubnet-send-override  (item (position ? playerPosition) playerNames) self "shape" ["crop-spray-light"]
            
          ] [
          
          hubnet-send-override  (item (position ? playerPosition) playerNames) self "shape" ["crop-spray-heavy"]
          
          ]
          
          ]
          ]
        ]
      ]
    ]
    ask scorecards with [identity = "playerName"] [
      if ? != playerNumber [
        hubnet-send-override  (item (position ? playerPosition) playerNames) self "label" [(item (position playerNumber playerPosition) playerShortNames)] 
      ]
    ] 
  ]
  
end
@#$#@#$#@
GRAPHICS-WINDOW
386
10
1628
713
5
-1
112.0
1
50
1
1
1
0
0
0
1
-5
5
0
5
0
0
1
ticks
30.0

BUTTON
13
17
121
112
Launch Broadcast
startup\n
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
127
16
231
111
Listen Clients
listen
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
213
126
368
232
Start Next Game
set-new-game
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
47
262
337
295
Clear Between-round Information Screen
clear-information
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
272
12
378
57
language
language
"Khmer" "English" "Chinese" "Vietnamese"
0

INPUTBOX
15
126
79
186
sessionID
25
1
0
Number

BUTTON
14
198
143
233
Initialize Game Session
initialize-session
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
13
313
363
715
15

@#$#@#$#@
## WHAT IS IT?

NonCropShare is a 4-player coordination game, framed around the provision of insect-based ecosystem services

## HOW IT WORKS

For each square in a player's grid, the player chooses among 4 actions, each with its own costs and benefits:

> 1. Do nothing - costs nothing, and yields baseYield
> 2. Plant non-crop habitat - costs nothing, yields nothing, but gives a bonus to cropped squares in a moore neighborhood of some radius around it
> 3. Do light, targeted spraying - carries a small cost, and brings a small boost to yields in the square
> 4. Do heavy spraying - carries a cost, and brings a big benefit to the square, at the cost of canceling out any non-crop habitat bonuses in and around the square

Depending on the values assigned to yields, costs, and benefits, different equilibria will exist.

## GAME VERSIONS AND PROTOCOLS

Sample game protocols (for framing the game and instructing participants) are available at http://www.ifpri.org/biosight/noncropsharegame.  This site also hosts a stand-alone version of the game in which game parameters can be manipulated from the user interface.  This version of the game is intended for use by enumerators and relies on an input file for game session parameters.

## ENUMERATOR INSTRUCTIONS 

> 1. Log all of your tablets onto the same network.  If you are in the field using a portable router, this is likely to be the only available wifi network.

> 2. Open the game file on your host tablet.  Zoom out until it fits in your screen

> 3. If necessary, change the language setting on the host.

> 4. Click ‘Launch Broadcast’.  This will reset the software, as well as read in the file containing all game settings.  

> 5. Select ‘Mirror 2D view on clients’ on the Hubnet Control Center.  

> 6. Click ‘Listen Clients’ on the main screen.  This tells your tablet to listen for the actions of the client computers.  If there ever are any errors generated by Netlogo, this will turn off.  Make sure you turn it back on after clearing the error.

> 7. Open Hubnet on all of the client computers.  Enter the player names in the client computers, in the form ‘PlayerName_HHID’.   

> 8. If the game being broadcast shows up in the list, select it.  Otherwise, manually type in the server address (shown in ‘Hubnet Control Center’.  With the HooToo Tripmate routers, it should be of the form 10.10.10.X.

> 9. Click ‘Enter’ on each client.

> 10. Back on the host tablet, verify the sessionID.  If you have previously saved games in the current directory, sessionID will automatically default to the ID following the highest ID that NetLogo finds in the directory.  If it finds no files, it defaults to -9999.  If necessary, modify the sessionID, and click ‘Initialize Game Session’.  This loads the settings for the practice session plus each of the 4 games you will play, in the correct game order for that session.  Once you’ve started, you can only go back by cleaning the workspace with ‘Launch Broadcast’

> 11. Click ‘Start Next Game’.  Each time you click it, it will start the next game in the cycle, loading the current settings in the window below for you to read.  You won’t be able to skip ahead to the next game if the current game isn’t finished.  Once again, the only way to clean the slate is with ‘Launch Broadcast’

** A small bug – once you start *EACH* new game, you must have one client exit and re-enter.  For some reason the image files do not load initially, but will load on all client computers once a player has exited and re-entered.  Be sure not to change the player name or number when they re-enter.

Within each game, you will have the responsibility of clearing information screens between rounds once farmers have viewed the score screens:

> 1. At the end of each turn, once players have seen the numbers on their screens and are ready to move on, click ‘Clear Between-round Information Screen’ to advance to the sum scores for each player

> 2. Once players are ready to continue to the next round, click ‘Clear Between-round Information Screen’ again.

> 3. At the end of the game, click through ‘Clear Between-round Information Screen’ until the numbers disappear, to make sure the game file gets saved

## ADAPTING THE GAME

NonCropShare can be customized to different geometries, but caution should be exercised to ensure that the visualization has been correctly adapted.

Additionally, the rules for scoring in the current game are specific to the insect-based ecosystem service application of NonCropShare.  Any rules of interest can be coded in the 'calculate-score' procedure.

## NETLOGO FEATURES

NonCropShare exploits the use of the bitmap extension, agent labeling, and hubnet overrides to get around the limitations of NetLogo's visualization capacities.

In the hubnet client, all actual buttons are avoided.  Instead, the world is extended, with patches to the right of the origin capturing elements of the game play, and patches to the left of the origin being used only to display game messages.

Language support is achieved by porting all in-game text to bitmap images that are loaded into the view.  The location of these images is optimized to a Dell Venue 8 Pro tablet, and will likely need some care if re-sized (it is necessary to think in both patch space and pixel space to place them correctly).  Scores are updated to the labels of invisible agents, whose values are overridden differently for each client.

## CREDITS AND REFERENCES

Earlier and current versions of NonCropShare are available at http://www.ifpri.org/book-735/biosight/noncropsharegame

Please cite any use of NonCropShare as:

Andrew Bell; Zhang, Wei; Bianchi, Felix; and vander Werf, Wopke (2013). NonCropShare – a coordination game for provision of insect-based ecosystem services. IFPRI Biosight Program. http://www.ifpri.org/biosight/noncropsharegame
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

blank
true
0

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

crop-base
false
0
Polygon -10899396 true false 240 285 285 225 285 165
Polygon -10899396 true false 225 285 210 135 180 75 180 240
Polygon -10899396 true false 225 105 240 105 240 285 225 285
Polygon -10899396 true false 90 270 45 60 45 210
Polygon -10899396 true false 105 270 165 180 165 90 120 180
Polygon -10899396 true false 90 60 90 285 105 285 105 60
Circle -1184463 true false 54 54 42
Circle -1184463 true false 99 69 42
Circle -1184463 true false 54 99 42
Circle -1184463 true false 99 114 42
Circle -1184463 true false 54 144 42
Circle -1184463 true false 99 159 42
Circle -1184463 true false 54 189 42
Circle -1184463 true false 84 24 42
Circle -1184463 true false 234 99 42
Circle -1184463 true false 189 114 42
Circle -1184463 true false 204 69 42
Circle -1184463 true false 234 144 42
Circle -1184463 true false 189 159 42
Circle -1184463 true false 234 189 42
Circle -1184463 true false 189 204 42

crop-spray-heavy
false
0
Polygon -10899396 true false 240 285 285 225 285 165
Polygon -10899396 true false 225 285 210 135 180 75 180 240
Polygon -10899396 true false 225 105 240 105 240 285 225 285
Polygon -10899396 true false 90 270 45 60 45 210
Polygon -10899396 true false 105 270 165 180 165 90 120 180
Polygon -10899396 true false 90 60 90 285 105 285 105 60
Circle -1184463 true false 54 54 42
Circle -1184463 true false 99 69 42
Circle -1184463 true false 54 99 42
Circle -1184463 true false 99 114 42
Circle -1184463 true false 54 144 42
Circle -1184463 true false 99 159 42
Circle -1184463 true false 54 189 42
Circle -1184463 true false 84 24 42
Circle -1184463 true false 234 99 42
Circle -1184463 true false 189 114 42
Circle -1184463 true false 204 69 42
Circle -1184463 true false 234 144 42
Circle -1184463 true false 189 159 42
Circle -1184463 true false 234 189 42
Circle -1184463 true false 189 204 42
Circle -2674135 true false 15 135 30
Circle -2674135 true false 45 105 30
Circle -2674135 true false 90 90 30
Circle -2674135 true false 90 180 30
Circle -2674135 true false 180 30 30
Circle -2674135 true false 45 165 30
Circle -2674135 true false 135 15 30
Circle -2674135 true false 255 135 30
Circle -2674135 true false 180 90 30
Circle -2674135 true false 135 195 30
Circle -2674135 true false 45 60 30
Circle -2674135 true false 60 210 30
Circle -2674135 true false 225 165 30
Circle -2674135 true false 90 30 30
Circle -2674135 true false 75 135 30
Circle -2674135 true false 90 240 30
Circle -2674135 true false 135 75 30
Circle -2674135 true false 225 105 30
Circle -2674135 true false 135 135 30
Circle -2674135 true false 195 135 30
Circle -2674135 true false 210 210 30
Circle -2674135 true false 180 180 30
Circle -2674135 true false 225 60 30
Circle -2674135 true false 180 240 30
Circle -2674135 true false 135 255 30

crop-spray-light
false
0
Polygon -10899396 true false 240 285 285 225 285 165
Polygon -10899396 true false 225 285 210 135 180 75 180 240
Polygon -10899396 true false 225 105 240 105 240 285 225 285
Polygon -10899396 true false 90 270 45 60 45 210
Polygon -10899396 true false 105 270 165 180 165 90 120 180
Polygon -10899396 true false 90 60 90 285 105 285 105 60
Circle -1184463 true false 54 54 42
Circle -1184463 true false 99 69 42
Circle -1184463 true false 54 99 42
Circle -1184463 true false 99 114 42
Circle -1184463 true false 54 144 42
Circle -1184463 true false 99 159 42
Circle -1184463 true false 54 189 42
Circle -1184463 true false 84 24 42
Circle -1184463 true false 234 99 42
Circle -1184463 true false 189 114 42
Circle -1184463 true false 204 69 42
Circle -1184463 true false 234 144 42
Circle -1184463 true false 189 159 42
Circle -1184463 true false 234 189 42
Circle -1184463 true false 189 204 42
Circle -2674135 true false 90 90 30
Circle -2674135 true false 90 180 30
Circle -2674135 true false 135 195 30
Circle -2674135 true false 180 90 30
Circle -2674135 true false 135 75 30
Circle -2674135 true false 195 135 30
Circle -2674135 true false 135 135 30
Circle -2674135 true false 75 135 30
Circle -2674135 true false 180 180 30

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

non-crop
false
0
Polygon -6459832 true false 180 255 120 195 135 195 165 225 135 135 150 150 165 210 195 105 210 120 180 195 210 165 210 180 180 210
Polygon -6459832 true false 60 210 105 255 75 120 60 120 90 225 60 195
Circle -10899396 true false 26 86 67
Circle -10899396 true false 116 101 67
Circle -10899396 true false 163 58 92
Circle -10899396 true false 45 180 30
Circle -10899396 true false 99 159 42
Circle -10899396 true false 195 150 30
Circle -10899396 true false 146 176 67
Polygon -13840069 true false 135 255 105 45 75 30 105 105 135 255
Polygon -13840069 true false 255 240 270 60 240 30 240 240
Polygon -13840069 true false 135 255 45 60 30 45 120 240
Polygon -13840069 true false 135 255 45 15 60 15 120 210
Polygon -6459832 true false 195 105 165 30 180 90 135 75 180 105
Circle -10899396 true false 144 9 42
Circle -10899396 true false 120 60 30

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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
4
10
1255
681
0
0
0
1
1
1
1
1
0
1
1
1
-5
5
0
5

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
