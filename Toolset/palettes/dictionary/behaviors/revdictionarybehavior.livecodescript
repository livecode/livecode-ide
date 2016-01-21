script "revDictionaryBehavior"
-- The dictionary starts to hide elements at lower than 992 pixels
-- *TODO* Tweak the CSS to rearrange things appropriately 
constant kDictionaryMinWidth = 992

-- Some browsers have a built-in scrollbar. Add a fudge factor to 
-- take this into account
constant kScrollbarFudge = 18

local sTab, sEntry
on setAsBehavior pTarget
   dispatch "setAsBehavior" to stack revIDEFrameBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

on openStack
   local tMinWidth
   put kDictionaryMinWidth + kScrollbarFudge into tMinWidth 
   lock screen
   set the width of me to tMinWidth
   set the minWidth of me to tMinWidth
   set the title of me to "Dictionary"
   if sTab is empty then
      put "api" into sTab
   end if
   revIDEGenerateDictionaryHTML sTab, sEntry["library"], sEntry["entry"], sEntry["type"]
   put empty into sEntry
   showTab sTab
   set the cantModify of me to true	
   unlock screen
end openStack

on resizeStack
   if there is a widget "Dictionary" of me then
      set the rect of widget "Dictionary" of me to the contentRect of me
   end if
end resizeStack

on showAPIs
   showTab "api"
end showAPIs

on showGuides
   showTab "guide"
end showGuides

on showTab pTab
   hiliteFrameItem pTab
   put pTab into sTab
   revIDEEnsureDictionaryUrl pTab
   local tUrl
   put "file://" & revIDEGetDictionaryUrl(pTab) into tUrl
   replace " " with "%20" in tUrl
   set the url of widget "Dictionary" of me to tUrl
end showTab

on browserNavigateComplete
   if sEntry is not empty then
      do "goEntryName('" & sEntry["library"] & "','" & sEntry["entry"] & "','" & sEntry["type"] & "')" in widget "Dictionary" of me
      put empty into sEntry
   end if
   if the mode of me is not 0 then
      resizeStack
   end if
end browserNavigateComplete

on navigateToEntry pLibrary, pEntry, pType
   put pLibrary into sEntry["library"]
   put pEntry into sEntry["entry"]
   put pType into sEntry["type"]
   if the mode of me is not 0 then
      browserNavigateComplete
   else
      toplevel me
   end if
end navigateToEntry
