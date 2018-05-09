script "revDictionaryBehavior" with behavior "revPaletteBehavior"
-- The dictionary starts to hide elements at lower than 992 pixels
-- *TODO* Tweak the CSS to rearrange things appropriately 
constant kDictionaryMinWidth = 992

-- Some browsers have a built-in scrollbar. Add a fudge factor to 
-- take this into account
constant kScrollbarFudge = 18

-- The background colour for the dictionary stack
constant kBackColor = "white"

local sTab, sEntry
on setAsBehavior pTarget
   dispatch "setAsBehavior" to stack revIDEFrameBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

on openStack
   local tMinWidth
   put kDictionaryMinWidth + kScrollbarFudge into tMinWidth 
   lock screen
   --Force the browser to actually resize
   set the rect of widget "Dictionary" of me to 0,0,0,0
   set the javascripthandlers of widget "Dictionary" of me to "linkClicked" & return & "showUpgradeOptions"
   set the width of me to tMinWidth
   set the minWidth of me to tMinWidth
   set the title of me to "Dictionary"
   set the backColor of me to kBackColor
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
   set the rect of widget "Dictionary" of me to the contentRect of me
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
   end if
   toplevel me
end navigateToEntry

on linkClicked pLink
   launch url pLink
end linkClicked

on showUpgradeOptions pEdition, pDisplayName
   put urlEncode(pDisplayName) into pDisplayName
   replace "+" with "%20" in pDisplayName
   
   launch url revEnvironmentEditionProperty("edition_external_url", pEdition) & \
         "?utm_source=ide&utm_medium=docs&utm_campaign="&pDisplayName
end showUpgradeOptions

# bug 17819 enable cmd+c in dictionary
on commandKeyDown pWhich
   switch pWhich
      case "A"
         -- trap Cmd + A for select all
      case "C"
         -- trap Cmd + C for copy
         break
      case "W"
         close me
         break
      default
         pass commandKeyDown
   end switch
end commandKeyDown
