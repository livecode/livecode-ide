script "revStandaloneSettingsInclusionsBehavior"
local sExtensionData
constant kLineHeight = 41
constant kNumberOfRows = 12

local sHasOpened = false

on preOpenCard
   lock screen
   local tScroll
   if sHasOpened then
      put the viewProp["vscroll"] of group "extensionList" of me into tScroll
   end if
   
   put revSBAvailableInclusions() into sExtensionData
   setUpExtensionList
   
   send "renderView" to group "extensionList" of me
   if sHasOpened then
      set the viewProp["vscroll"] of group "extensionList" of me to tScroll
   end if
   
   setExtensionList
   
   local tHeight
   put the bottom of group "cards" of me \
         + kLineHeight * kNumberOfRows into tHeight
   set the cSize of this card to 568, tHeight
   
   unlock screen
   
   put true into sHasOpened
   
   pass preOpenCard
end preOpenCard

on resizeStack
   local tRect
   put the rect of this card of this stack into tRect
   put the bottom of group "cards" of this stack into item 2 of tRect
   set the rect of group "extensionList" of card "inclusions" of this stack to tRect
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
   put sExtensionData[pRow] into pDataA
   put "extension" into pTemplateStyle
end DataForRow

function NumberOfRows
   return the number of elements in sExtensionData
end NumberOfRows


private command addToList pElement, @xArray
   put pElement into xArray[the number of elements in xArray + 1]
end addToList

local sHilitedExtensions
command updateInclusions
   local tInclusions, tExclusions
   repeat for each key tIndex in sExtensionData
      if sHilitedExtensions[tIndex] then
         addToList sExtensionData[tIndex], tInclusions
      else
         addToList sExtensionData[tIndex], tExclusions
      end if
   end repeat
   revSBUpdateInclusions tInclusions, tExclusions, getTargetStackName()
end updateInclusions

on setExtensionList
   lock screen
   put getExtensionHiliteList(sExtensionData) into sHilitedExtensions
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
