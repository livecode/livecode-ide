script "revStandaloneSettingsInclusionsBehavior"
local sExtensionDataA
constant kLineHeight = 41
constant kNumberOfRows = 12
constant kPlatforms = "MacOSX,Windows,Linux,iOS,Android,Emscripten"
local sHasOpened = false

local sPlatformsA, sFilter
on preOpenCard
   lock screen
   local tScroll
   if sHasOpened then
      put the viewProp["vscroll"] of group "extensionList" of me into tScroll
   end if
   local tFilterField
   put the long id of field "Filter" of group "filter" of me \
         into tFilterField
   set the cCallback of tFilterField to "filterChanged"
   set the cCallbackTarget of tFilterField to the long id of me
   set the cPlaceholderText of tFilterField to "Filter inclusions..."
   set the behavior of tFilterField to revIDEBehavior("filterfield")
   
   setUpExtensionList
   
   filterChanged sFilter
   
   if sHasOpened then
      set the viewProp["vscroll"] of group "extensionList" of me to tScroll
   end if
   
   local tHeight
   put the bottom of group "cards" of me \
         + kLineHeight * kNumberOfRows into tHeight
   set the cSize of this card to 568, tHeight
   
   unlock screen
   
   put true into sHasOpened
   
   pass preOpenCard
end preOpenCard

command setExtensionListData pFilter, pPlatformsA
   local tExtensionDataA, tDisplayedExtensionsA
   put revSBAvailableInclusions() into tExtensionDataA
   
   local tKeys
   put the keys of tExtensionDataA into tKeys
   -- Secondary order by title
   sort tKeys by tExtensionDataA[each]["title"]
   -- Primary order by type
   sort tKeys by tExtensionDataA[each]["type"]
   repeat for each line tIndex in tKeys
      local tExtensionA
      put tExtensionDataA[tIndex] into tExtensionA
      if pFilter is not empty and not \
            (tExtensionA["title"] contains pFilter) then
         next repeat
      end if
      if pPlatformsA is not empty then
         local tFound
         put false into tFound
         repeat for each key tPlatform in pPlatformsA
            if itemOffset(tPlatform, tExtensionA["platforms"]) \
                  is not 0 then
               put true into tFound
            end if
         end repeat
         if not tFound then
            next repeat
         end if
      end if
      addToList tExtensionA, tDisplayedExtensionsA
   end repeat
   put pFilter into sFilter
   put pPlatformsA into sPlatformsA
   put tDisplayedExtensionsA into sExtensionDataA
   send "renderView" to group "extensionList" of me
   setExtensionList
end setExtensionListData

on resizeStack
   local tCardRect, tFilterRect, tListRect
   put the rect of this card of this stack into tCardRect
   put tCardRect into tFilterRect
   put the bottom of group "cards" of this stack into \
         item 2 of tFilterRect
   put item 2 of tFilterRect + the formattedheight of \
         group "filter" of me into item 4 of tFilterRect
   set the rect of group "filter" of me to tFilterRect
   put tCardRect into tListRect
   put item 4 of tFilterRect into item 2 of tListRect
   set the rect of group "extensionList" of this card \
         to tListRect
end resizeStack

on setUpExtensionList
   local theStylesA, tGroupLongID
   put the long id of group "extensionList" of card "inclusions" of this stack into tGroupLongID
   
   set the behavior of tGroupLongID to revIDEDataViewBehavior()
   send "ResetView" to tGroupLongID
   
   put the long id of group "extensionRow" of card "inclusions" of this stack into theStylesA["extension"]
   
   set the viewProp["row style templates"] of tGroupLongID to theStylesA
   set the viewProp["hilite color"] of tGroupLongID to ideColorGet("pb_line_selected")
   set the viewProp["background color"] of tGroupLongID to empty
   
   set the viewProp["row color"] of tGroupLongID to revIDEColor("dataView_rowColor")
   set the viewProp["alternate row color"] of tGroupLongID to revIDEColor("dataView_rowAlternateColor")        
   
   set the viewProp["fixed row height"] of tGroupLongID to "true"
   set the viewProp["row height"] of tGroupLongID to kLineHeight
   set the viewProp["cache"] of tGroupLongID to "none"
   
   set the viewProp["scroll selections into view"] of tGroupLongID to false
end setUpExtensionList

command DataForRow pRow, @pDataA, @pTemplateStyle
   put sExtensionDataA[pRow] into pDataA
   put "extension" into pTemplateStyle
end DataForRow

function NumberOfRows
   return the number of elements in sExtensionDataA
end NumberOfRows


private command addToList pElement, @xArray
   put pElement into xArray[the number of elements in xArray + 1]
end addToList

local sHilitedExtensions
command updateInclusions
   local tInclusions, tExclusions
   repeat for each key tIndex in sExtensionDataA
      if sHilitedExtensions[tIndex] then
         addToList sExtensionDataA[tIndex], tInclusions
      else
         addToList sExtensionDataA[tIndex], tExclusions
      end if
   end repeat
   revSBUpdateInclusions tInclusions, tExclusions, getTargetStackName()
end updateInclusions

on setExtensionList
   lock screen
   put getExtensionHiliteList(sExtensionDataA) into sHilitedExtensions
   setHilited
   unlock screen 
end setExtensionList

on setHilited
   lock screen
   local tHilited
   repeat for each key tIndex in sHilitedExtensions
      if sHilitedExtensions[tIndex] then
         put tIndex & comma after tHilited
      end if
   end repeat
   delete the last char of tHilited
   set the dvHilitedRows[true] of group "extensionList" of me to tHilited
   unlock screen
end setHilited

command toggleAllHilites pOn
   repeat for each key tIndex in sExtensionDataA
      if pOn then
         put true into sHilitedExtensions[tIndex]
      else
         delete variable sHilitedExtensions[tIndex]
      end if
   end repeat
   
   setHilited
end toggleAllHilites

on rowClicked pRow
   lock screen
   put not sHilitedExtensions[pRow] into sHilitedExtensions[pRow]
   setHilited
   updateInclusions
   unlock screen
end rowClicked

function getExtensionHiliteList pExtensionData
   local tHiliteList, tId, tShouldHilite, tTitle, tElement, tSettings
   put the customProperties["cRevStandaloneSettings"] of \ 
         stack the cRevTargetStack of this stack into tSettings
   
   repeat for each key tIndex in pExtensionData
      put pExtensionData[tIndex] into tElement
      put false into tShouldHilite
      put tElement["id"] into tId
      put tElement["title"] into tTitle
      
      switch tElement["type"]
         case "widget"
         case "library"
            put tId is among the lines of tSettings["extensions"] into tShouldHilite
            break
         case "script library"
            put tTitle is among the lines of tSettings["scriptLibraries"] into tShouldHilite
            break
         case "external"
            put tTitle is among the lines of tSettings["scriptLibraries"] or \ 
                  tTitle is among the lines of tSettings["externals"] into tShouldHilite
            
            repeat for each item tItem in "ios,android"
               if tSettings[tItem & ",include" && tId] then
                  put true into tShouldHilite
               end if
            end repeat
            break
         case "inclusion"
            put tTitle is among the lines of tSettings["scriptLibraries"] or \
                  tSettings[tTitle] into tShouldHilite
            
            repeat for each item tItem in "ios,android"
               if tSettings[revSBInclusionToMobileKey(tTitle, "external", tItem)] then
                  put true into tShouldHilite
               end if
            end repeat
            break
         case "database driver"
            put tTitle is among the lines of tSettings["databaseDrivers"] into tShouldHilite
            
            repeat for each item tItem in "ios,android"
               if tSettings[revSBInclusionToMobileKey(tTitle, "database driver", tItem)] then
                  put true into tShouldHilite
               end if
            end repeat
            break
         case "resource"
            put tSettings[tID] into tShouldHilite
            
            repeat for each item tItem in "ios,android"
               if tSettings[revSBInclusionToMobileKey(tID, "external", tItem)] then
                  put true into tShouldHilite
               end if
            end repeat
            break
      end switch
      put tShouldHilite into tHiliteList[tIndex]
   end repeat
   
   return tHiliteList
end getExtensionHiliteList

on filterChanged pFilter
   lock screen
   setExtensionListData pFilter, sPlatformsA
   shiftFilterRow
   unlock screen
end filterChanged

command shiftFilterRow
   local tScrollbarWidth
   if the viewProp["scrollbar is visible"] of group \
         "extensionList" of me then
      put the viewProp["effective scrollbar width"] of \
            group "extensionList" of me into tScrollbarWidth
   end if
   local tShift
   put tScrollbarWidth - the cScrollbarOffset of group \
         "filter" of me into tShift
   doShift tShift
   set the cScrollbarOffset of group "filter" of me \
         to tScrollbarWidth
end shiftFilterRow

command doShift pAmount
   lock screen
   local tRightItemsLoc
   put the loc of group "rightItems" of group "filter" of me \
         into tRightItemsLoc
   subtract pAmount from item 1 of tRightItemsLoc
   set the loc of group "rightItems" of group "filter" of me \
         to tRightItemsLoc
   
   local tBorderRect, tBgRect
   put the rect of graphic "border" of group "filter" of me \
         into tBorderRect
   put the rect of graphic "background" of group "filter" of me \
         into tBgRect
   subtract pAmount from item 3 of tBorderRect
   subtract pAmount from item 3 of tBgRect
   set the rect of graphic "border" of group "filter" of me \
         to tBorderRect
   set the rect of graphic "background" of group "filter" of me \
         to tBgRect
   unlock screen
end doShift

command deselectPlatformFilter pTarget
   local tColorOverlay
   put "normal" into tColorOverlay["blendmode"]
   put 128 into tColorOverlay["opacity"]
   put "255,255,255" into tColorOverlay["color"]
   set the colorOverlay of pTarget to tColorOverlay
end deselectPlatformFilter

command selectPlatformFilter pTarget
   set the colorOverlay of pTarget to empty
end selectPlatformFilter

command togglePlatformFilter pPlatform
   local tPlatformsA
   put sPlatformsA into tPlatformsA
   if tPlatformsA is empty then
      put true into tPlatformsA[pPlatform]
   else if tPlatformsA[pPlatform] then
      delete variable tPlatformsA[pPlatform]
   else
      put true into tPlatformsA[pPlatform]
   end if
   
   local tImage
   repeat for each item tItem in kPlatforms
      put the long id of image tItem of group "platformFilters" \
            of group "filter" of me into tImage
      if tPlatformsA is empty then
         selectPlatformFilter tImage
      else if tPlatformsA[tItem] then
         selectPlatformFilter tImage
      else
         deselectPlatformFilter tImage
      end if
   end repeat
   setExtensionListData sFilter, tPlatformsA
end togglePlatformFilter

on mouseUp
   if exists(the owner of the target) and \
         exists(the owner of the owner of the target) and \
         the short name of the owner of the owner of \
         the target is "platformFilters" then
      togglePlatformFilter the short name of the owner of the target
   else if exists(the owner of the target) and \
         the short name of the owner of the target is "rightItems" and \
         the short name of the target is "check" then
      toggleAllHilites the hilited of the target
   end if
end mouseUp
