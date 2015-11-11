script "revDictionaryBehavior"
local sTab
on setAsBehavior pTarget
   dispatch "setAsBehavior" to stack revIDEFrameBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
   send "setFrame" to me in 0 millisecs
end setAsBehavior

on setFrame
   set the navigationDisplayStyle of me to "names"
   set the showPreferenceAction of me to false	
   resizeStack
end setFrame

on openStack
   lock screen
   set the width of me to 1000
   set the minWidth of me to 1000
   set the title of me to "Dictionary"
   if sTab is empty then
      put "api" into sTab
   end if
   showTab sTab
   set the cantModify of me to true	
   unlock screen
end openStack

on resizeStack
   set the rect of widget "Dictionary" of me to the contentRect of me
end resizeStack

on showAPIs
   showTab "api"
end showAPIs

on showGuides
   showTab "guide"
end showGuides

function getUrl pTab
   if pTab is "guide" then
      return ("file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "guide.html")
   else
      return ("file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer.html")
   end if 
end getUrl

on showTab pTab
   hiliteFrameItem pTab
   put pTab into sTab
   set the url of widget "Dictionary" of me to getUrl(pTab)
end showTab

on browserNavigateComplete
   resizeStack
end browserNavigateComplete
