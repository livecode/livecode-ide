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
   lock screen
   set the rect of group "fields" of this card to the contentRect of me
   send "positionOpenStacksButton" to me in 0 milliseconds
   unlock screen
end layoutCard
