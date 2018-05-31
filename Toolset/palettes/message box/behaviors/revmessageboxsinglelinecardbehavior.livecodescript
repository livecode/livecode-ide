script "revMessageBoxSingleLineCardBehavior"
on openCard
   lock screen
   --show relevant frame items
   showFrameItem "outputSource"
   if revIDEGetPreference("IDELockedToStack") is true 
   then showFrameItem "unlockDefaultStack"
   else showFrameItem "lockDefaultStack"
   
   send "revInitialise" to field "message" of me
   
   if revIDEGetPreference("IDESingleLineMessageHistory") is not empty 
   then put line 1 of revIDEGetPreference("IDESingleLineMessageHistory") into field "message"
   else put empty into field "message"
   
   dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of field "message" of me
   
   local tActiveStack
   put revIDEGetPreference("IDEActiveStack") into tActiveStack
   revUpdateActiveStack tActiveStack, tActiveStack
   set the label of button "Open Stacks" to tActiveStack
   layoutCard
   positionOpenStacksButton
   focus field "message"
   select the text of field "message"
   set the tooltip of field "message" to "Type a command or expression and press Return"
   unlock screen
   # AL-2015-04-17: [[ Bug 15227 ]] Pass openCard so it is handled by the palette behavior
   pass openCard
end openCard

on closeCard
   hideFrameItem "outputSource"
   hideFrameItem "unlockDefaultStack"
   hideFrameItem "lockDefaultStack"
end closeCard

on resizeStack
   layoutCard
   # AL-2015-04-17: [[ Bug 15227 ]] Pass resizeStack so it is handled by the palette behavior
   pass resizeStack
end resizeStack

on layoutCard
   set the rect of group "fields" of me to the contentRect of me
   lock screen
   local tLeft, tTop, tRight, tBottom, tWidth
   lock messages
   
   put the left of group "fields" of me into tLeft
   put the top of group "fields" of me into tTop
   put the right of group "fields" of me into tRight
   put the bottom of group "fields" of me into tBottom
   
   local tHeight
   put the effective textHeight of field "message" of me into tHeight
   
   local tMargins
   put the margins of field "message" of me into tMargins
   if the number of items of tMargins is 1 then
      add tMargins to tHeight
   else
      add item 2 of tMargins to tHeight
   end if
   
   set the rect of field "message" of me to tLeft,tTop,tRight,(tTop + tHeight)
   set the rect of field "auto complete" of me to tLeft,tTop,tRight,(tTop + tHeight)
   set the rect of field "results" of me to tLeft,(tTop + tHeight),tRight,tBottom
   
   put (tRight - tLeft) into tWidth
   set the width of graphic "line" of me to tWidth
   set the loc of graphic "line" of me to (tWidth/2),(tTop+tHeight)
   
   unlock messages
   send "positionOpenStacksButton" to me in 0 milliseconds
   unlock screen
end layoutCard

on closeField
   if the short name of the target is "results" then
      put the text of the target into msg
   end if
end closeField

