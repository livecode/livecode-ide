script "revIDEExtensionManagerListBehavior"
on resizeStack
   set the rect of group "extensionList" of me to the contentRect of me
   pass resizeStack
end resizeStack

on preOpenCard
   lock screen
   set the rect of group "extensionList" of me to the contentRect of me
   send "resetView" to group "extensionList" of card 1 of this stack
   refreshExtensionList "widget"
   unlock screen
end preOpenCard

on openCard
   hiliteFrameItem "widget"
end openCard
