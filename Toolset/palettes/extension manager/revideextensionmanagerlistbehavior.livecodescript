script "revIDEExtensionManagerListBehavior"
local sSection
on setSection pSection
   if pSection is empty then
      if sSection is empty then
         put "widget" into sSection
      end if
   else
      put pSection into sSection
   end if
end setSection

on showList pSection
   if the short name of this card of this stack is not "list" then
      go card "list"
   end if
   setSection pSection
   refreshList
end showList

on resizeStack
   set the rect of group "extensionList" of me to the contentRect of this stack of me
   pass resizeStack
end resizeStack

on preOpenCard
   lock screen
   setSection
   set the rect of group "extensionList" of me to the contentRect of this stack of me
   send "resetView" to group "extensionList" of me
   unlock screen
end preOpenCard

on openCard
   lock screen
   refreshList
   unlock screen
end openCard

on refreshList
   hiliteFrameItem sSection
   refreshExtensionList sSection
end refreshList
