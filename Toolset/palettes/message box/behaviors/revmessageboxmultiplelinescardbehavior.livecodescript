script "revMessageBoxMultipleLinesCardBehavior"
local lMoving, lDistance

on preOpenCard
   local tMessage, tActiveStack
   lock screen
   
   if revIDEGetPreference("IDELockedToStack") is true 
   then showFrameItem "unlockDefaultStack"
   else showFrameItem "lockDefaultStack"

   send "revInitialise" to field "message" of me
   
   if revIDEGetPreference("IDEMultipleLinesMessageHistory") is not empty then
      put line 1 of revIDEGetPreference("IDEMultipleLinesMessageHistory") into tMessage
      replace "\n" with return in tMessage
      put tMessage into field "message"
   else
      put empty into field "message"
   end if
   
   focus field "message"
   select the text of field "message"
   
   put revIDEGetPreference("IDEActiveStack") into tActiveStack
   revUpdateActiveStack tActiveStack, tActiveStack
   set the label of button "Open Stacks" to tActiveStack
   
   set the cREVMinHeight of field "message" of this card to 50
   set the cREVMinHeight of field "results" of this card to 50
   set the loc of graphic "line" to the cREVLineLoc of this card
   send "resizeStack" to me
   positionOpenStacksButton("resize")
   
   unlock screen
end preOpenCard

on resizeStack
   set the rect of group "fields" of this card to the contentRect of me
   pass resizeStack
end resizeStack

on closeCard
   set the cREVLineLoc of this card to the loc of graphic "line"
   
   hideFrameItem "unlockDefaultStack"
   hideFrameItem "lockDefaultStack"
end closeCard

----------line in between message field and results field can be dragged up/down to decrease/increase the size of the message field----------
on mouseDown
   put true into lMoving
end mouseDown

on mouseUp
   put false into lMoving
   pass mouseUp
end mouseUp

on mouseRelease
   put false into lMoving
end mouseRelease

on mouseMove pMouseH, pMouseV
   local tLineYLoc
   put item 2 of the loc of graphic "line" into tLineYLoc
   if pMouseV <= (tLineYLoc + 10) and pMouseV >= (tLineYLoc - 10) then 
      set the cursor to 30
      lock cursor
   else
      unlock cursor
   end if
   dragLine
end mouseMove

command dragLine
   local tLineXLoc, tResultsRect, tMessageRect, tMouseYLoc, tResultsTop, tMessageBottom
   
   put item 1 of the loc of graphic "line" into tLineXLoc
   put the rect of field "results" into tResultsRect
   put the rect of field "message" into tMessageRect
   
   if lMoving is true then
      put item 2 of the mouseLoc into tMouseYLoc
      
      if tMouseYLoc < (the cREVMinHeight of field "message" + the top of field "message") 
      then put (the cREVMinHeight of field "message" + the top of field "message") into tMouseYLoc
      if tMouseYLoc > (the bottom of field "results" - the cREVMinHeight of field "results")
      then put (the bottom of field "results" - the cREVMinHeight of field "results") into tMouseYLoc
      put tMouseYLoc + 2 into tResultsTop
      put tMouseYLoc - 2 into tMessageBottom
      replace item 2 of tResultsRect with tResultsTop in tResultsRect
      replace item 4 of tMessageRect with tMessageBottom in tMessageRect
      
      lock screen
      set the loc of graphic "line" to tLineXLoc,tMouseYLoc
      set the rect of field "results" to tResultsRect
      set the rect of field "message" to tMessageRect
      unlock screen
   end if
end dragLine
