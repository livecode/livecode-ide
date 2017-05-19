script "revMessageBoxMultipleLinesCardBehavior"
constant kSeparatorSize = 10
local lMoving, lDistance

on preOpenCard
   local tMessage, tActiveStack
   lock screen
   
   if revIDEGetPreference("IDELockedToStack") is true 
   then showFrameItem "unlockDefaultStack"
   else showFrameItem "lockDefaultStack"
   
   send "revInitialise" to field "script" of me
   
   if revIDEGetPreference("IDEMultipleLinesMessageHistory") is not empty then
      put line 1 of revIDEGetPreference("IDEMultipleLinesMessageHistory") into tMessage
      replace "\n" with return in tMessage
      put tMessage into field "script"
   else
      put empty into field "script"
   end if
   
   focus field "script"
   select the text of field "script"
   dispatch "scriptFormat" to the owner of field "script" with "script"
   
   put revIDEGetPreference("IDEActiveStack") into tActiveStack
   revUpdateActiveStack tActiveStack, tActiveStack
   set the label of button "Open Stacks" to tActiveStack
   
   set the cREVMinHeight of field "script" of this card to 50
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
   local tLineYLoc, tMouseV
   
   put item 2 of the mouseLoc into tMouseV
   put item 2 of the loc of graphic "line" into tLineYLoc   
   
   if tMouseV <= (tLineYLoc + kSeparatorSize/2) and tMouseV >= (tLineYLoc - kSeparatorSize/2) then 
      put true into lMoving
   end if
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
   if pMouseV <= (tLineYLoc + kSeparatorSize/2) and pMouseV >= (tLineYLoc - kSeparatorSize/2) then 
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
   put item 2 of the mouseLoc into tMouseYLoc
   
   put the rect of field "results" into tResultsRect
   put the rect of field "script" into tMessageRect
   
   if lMoving is true then
      if tMouseYLoc < (the cREVMinHeight of field "script" + the top of field "script") 
      then put (the cREVMinHeight of field "script" + the top of field "script") into tMouseYLoc
      if tMouseYLoc > (the bottom of field "results" - the cREVMinHeight of field "results")
      then put (the bottom of field "results" - the cREVMinHeight of field "results") into tMouseYLoc
      
      put tMouseYLoc + 2 into tResultsTop
      put tMouseYLoc - 2 into tMessageBottom
      
      put 0,the headerHeight of this stack, the width of this stack,tMessageBottom into tMessageRect
      put 0,tResultsTop,the width of this stack,the bottom of this card-the footerHeight of this stack into tResultsRect
      
      lock screen
      set the loc of graphic "line" to tLineXLoc,tMouseYLoc
      set the rect of field "results" to tResultsRect
      set the rect of field "script" to tMessageRect
      unlock screen
   end if
end dragLine
