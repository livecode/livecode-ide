script "revmobilelibrary"

on revLoadLibrary
   if the target is me then
      insert the script of me into back
   end if
end revLoadLibrary

on revUnloadLibrary
   if the target is me then
      remove the script of me from back
   end if
end revUnloadLibrary

function revTargetStack pWhich
   local tParse
   if pWhich is not empty and there is a pWhich and word 1 of pWhich is not "the"
   then put the long id of pWhich into tParse
   else put the long id of the target into tParse
   get wordOffset("stack",tParse)
   
   local tStackName
   put word (it) to (it+1) of tParse into tStackName
   put the short name of tStackName into tStackName
   return tStackName
end revTargetstack

--on revGoURL pUrl

--on revGoPDF pFilename

#--command revMail pTo, pCC, pSubject, pBody

#--command revMailUnicode pTo, pCC, pSubject, pBody

#--function revRunningWindowsNT

#--on revSetWindowsShellCommand

getProp revProfile
  return the cREVGeneral["profile"] of the target
end revProfile

setProp revProfile pWhich
  set the cREVGeneral["profile"] of the target to pWhich
end revProfile

getProp cREVGeneral[pWhichProp]
   local tTarget
   put the long id of the target into tTarget
   
   if pWhichProp is "revUniqueID" then
      lock messages
      local tRevUniqueID
      put the cREVGeneral["revUniqueID"] of the target into tRevUniqueID
      unlock messages
      
      if tRevUniqueID is empty then
         put the milliseconds into tRevUniqueID
         set the cREVGeneral["revUniqueID"] of tTarget to tRevUniqueID
      end if
      return tRevUniqueID
   end if
   
   global gREVSuppressMessages
   if pWhichProp is not "profile" then if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass cREVGeneral

   lock messages
   local tProfile
   put the cREVGeneral["profile"] of tTarget into tProfile
   if tProfile is empty or tProfile is the cREVGeneral["masterName"] of tTarget then put "Master" into tProfile
   unlock messages

   return tProfile
end cREVGeneral

setProp cREVGeneral[pWhichProp] pWhichProfile
   local tTarget
   put the long id of the target into tTarget
   
   local tTargetLongID
   put tTarget into tTargetLongID
   if pWhichProp is not "profile" and pWhichProp is not "inLineImages" and \
         pWhichProp is not "virtualWidth" and pWhichProp is not "virtualHeight" and \
         pWhichProp is not "breakPoints" then pass cREVGeneral

   if pWhichProp is "virtualWidth" then
      lock messages
      local tOriginalWidth
      put the cREVGeneral["virtualWidth"] of tTarget into tOriginalWidth
      set the cREVGeneral["virtualWidth"] of tTarget to pWhichProfile
      
      local tDifference
      put tOriginalWidth - pWhichProfile into tDifference
      
      local tRect
      put the rect of stack revTargetStack() into tRect
      put item 3 of tRect + tDifference into item 3 of tRect
      set the rect of stack revtargetStack() to tRect
      unlock messages
      exit cREVGeneral
   end if

   if pWhichProp is "virtualHeight" then
      lock messages
      local tOriginalHeight
      put the cREVGeneral["virtualHeight"] of tTarget into tOriginalHeight
      set the cREVGeneral["virtualHeight"] of tTarget to pWhichProfile
      put tOriginalHeight - pWhichProfile into tDifference
      put the rect of stack revTargetStack() into tRect
      put item 4 of tRect + tDifference into item 4 of tRect
      set the rect of stack revtargetStack() to tRect
      unlock messages
      exit cREVGeneral
   end if

   if pWhichProp is "breakPoints" then
      
      pass cREVGeneral
      
      local tBreakPointsList
      put the breakPoints into tBreakPointsList
      
      local tMainStack
      put the mainStack of stack revTargetStack(tTarget) into tMainStack
      
      local tObjects
      put the cREVGeneral["debugObjects"] of stack tMainStack into tObjects
      
      local tStack
      put word -2 to -1 of tTarget into tStack
      put the name of tStack into word -2 to -1 of tTarget
      if pWhichProfile is not empty then
         if tTarget is not among the lines of tObjects then
            --add breakpoint object
            put tTarget into line (the number of lines in tObjects)+1 of tObjects
         end if
      else
         if tTarget is among the lines of tOBjects then
            --remove breakpoint object
            delete line lineOffset(tTarget,tObjects) of tOBjects
         end if
      end if 
      set the cREVGeneral["debugObjects"] of stack tMainStack to tObjects
      
      local tOldPoints
      repeat for each line l in tBreakPointsList
         if tTargetLongID is not in l then put l & cr after tOldPoints
      end repeat
      delete last char of tOldPoints
      put tOldPoints into tBreakPointsList
      
      local tAddPoints
      repeat for each line l in pWhichProfile
         put tTarget,l & cr after tAddPoints
      end repeat
      delete last char of tAddPoints
      put tAddPoints into line (the number of lines in tBreakPointsList+1) of tBreakPointsList
      set the breakPoints to tBreakPointsList
      pass cREVGeneral
   end if --breakPoints

   if pWhichProp is "inLineImages" then
      if pWhichProfile is true then
         lock messages
         lock screen
         set the lockLocation of the templateGroup to true
         set the rect of the templateGroup to item 1 to 2 of the rect of tTarget,item 3 of the rect of tTarget-the scrollbarWidth of tTarget,item 4 of the rect of tTarget
         set the name of the templateGroup to the short name of tTarget&"images"&the number of this cd
         create group
         reset the templateGroup
         
         local tGroupName
         put the short name of tTarget & "images"&the number of this cd into tGroupName
         --now pad the group so it can scroll
         reset the templateGraphic
         set the style of the templateGraphic to "line"
         set the lineSize of the templateGraphic to 0
         set the topLeft of the templateGraphic to the topLeft of tTarget
         create grc in group tGroupName
         reset the templateGraphic
         set the scroll of group tGroupName to 0
         set the scroll of tTarget to 0
         set the cREVGeneral["preInlineText"&the number of this cd] of tTarget to the text of tTarget
         set the itemDel to "/"
         
         local tSubtract
         put 0 into tSubtract
         
         local tFinalExit
         repeat
            if tFinalExit then exit repeat
            
            local tLineCount
            put 0 into tLineCount
            set the scroll of group tGroupName to 0
            set the scroll of tTarget to 0
            repeat for each line l in the text of tTarget
               put true into tFinalExit
               add 1 to tLineCount
               if item 2 of l is "*IMAGEFILE*" then
                  do "put empty into line tLineCount of" && tTarget
                  reset the templateImage
                  set the fileName of the templateImage to item 3 to -1 of l
                  
                  local tFieldName
                  put the short name of tTarget into tFieldName
                  
                  local tTop
                  put (the formattedHeight of line 1 to tLineCount of fld tFieldName + the top of tTarget) into tTop
                  set the width of the templateImage to the formattedWidth of the templateImage
                  
                  local tImageHeight
                  put the formattedHeight of the templateImage into tImageHeight
                  set the height of the templateImage to tImageHeight
                  set the lockLoc of the templateImage to true
                  set the topLeft of the templateImage to the left of tTarget+8,tTop-tSubtract
                  create image in group tGroupName
                  
                  local tNewLines
                  put 0 into tNewLines
                  repeat
                     add 1 to tNewLines
                     put cr after line tLineCount of the target
                     if the formattedHeight of line tLineCount to tLineCount+tNewLines of fld tFieldName >= tImageHeight then exit repeat
                  end repeat
                  put cr after line tLineCount of the target
                  put false into tFinalExit
                  exit repeat
               end if
               if item 2 of l is "*IMAGEID*" then
                  do "put empty into line tLineCount of" && tTarget
                  reset the templateButton
                  set the showName of the templateButton to false
                  set the showBorder of the templateButton to false
                  set the traversalOn of the templateButton to false
                  set the autoHilite of the templateButton to false
                  set icon of the templateButton to item 3 to -1 of l
                  put the short name of tTarget into tFieldName
                  put (the formattedHeight of line 1 to tLineCount of fld tFieldName + the top of tTarget) into tTop
                  set the width of the templateButton to the formattedWidth of the templateButton
                  put the formattedHeight of the templateButton into tImageHeight
                  set the height of the templateButton to tImageHeight
                  set the lockLoc of the templateButton to true
                  set the topLeft of the templateButton to the left of tTarget+8,tTop-tSubtract
                  create button in group tGroupName
                  put 0 into tNewLines
                  repeat
                     add 1 to tNewLines
                     put cr after line tLineCount of the target
                     if the formattedHeight of line tLineCount to tLineCount+tNewLines of fld tFieldName >= tImageHeight then exit repeat
                  end repeat
                  put cr after line tLineCount of the target
                  put false into tFinalExit
                  exit repeat
               end if
            end repeat
            put 30 into tSubtract
         end repeat
         reset the templateButton
         reset the templateImage
         --now pad the group so it can scroll
         
         local tFieldHeight
         put the formattedHeight of fld tFieldName into tFieldHeight
         reset the templateGraphic
         set the style of the templateGraphic to "line"
         set the lineSize of the templateGraphic to 0
         set the topLeft of the templateGraphic to the left of tTarget,tFieldHeight+the top of tTarget
         create grc in group tGroupName
         reset the templateGraphic
         set the scroll of group tGroupName to 0
         set the scroll of the target to 0
         unlock screen
         unlock messages
      else
         delete group (the short name of tTarget&"images"&the number of this cd)
         set the text of tTarget to the cREVGeneral["preInlineText"&the number of this cd] of tTarget
         set the cREVGeneral["preInlineText"&the number of this cd] of tTarget to empty
      end if
      set the cREVGEneral["inLineImages"&the number of this cd] of tTarget to pWhichProfile
      exit cREVGeneral
   end if --inLineImages
   
   -- pWhichProp is "profile"
   global gREVProfileReadOnly, gREVAutoCreateProfiles
   lock screen
   lock messages
   
   local tReturnSet
   put the customPropertySet of tTarget into tReturnSet
   set the cREVGeometryCache["order"] of this card to empty
   if the customkeys["cRevGeometry"] of tTarget is not empty then
      if "revUpdateGeometry" is in the pendingMessages then 
         cancel item 1 of line (lineOffset("revUpdateGeometry",the pendingMessages)) of the pendingMessages
      end if
      send "revUpdateGeometry" to stack revTargetStack(tTarget) in 250 milliseconds -- update geometry
   end if
   if pWhichProfile is not empty and pWhichprofile is not "master" and pWhichProfile is not the cREVGeneral["masterName"] of tTarget and pWhichProfile is not among the lines of the cREVGeneral["profileList"] of tTarget then
      if gREVAutoCreateProfiles then revNewProfile pWhichProfile, tTarget
      unlock screen
      unlock messages
      exit cREVGeneral
   end if
   if the cREVGeneral["profile"] of tTarget is "Master" or the cREVGeneral["profile"] of tTarget is empty or the cREVGeneral["profile"] of tTarget is the cREVGeneral["masterName"] of tTarget then
      --its in master, going out
      if not gREVProfileReadOnly then
         set the customPropertySet of tTarget to "cREVTempMaster"
         
         local tTempArray
         put the properties of tTarget into tTempArray
         set the customProperties of tTarget to tTempArray
      end if
   else
      --its another profile, going into or through master
      set the customPropertySet of tTarget to "cREVMaster"
      
      local tCurrentMasterArray
      if the customKeys["cREVMaster"] of tTarget is not empty then put the customProperties of tTarget into tCurrentMasterArray
      if not gREVProfileReadOnly then
         set the customPropertySet of tTarget to "cREVTempMaster"
         
         local tTempMasterArray
         put the customProperties of tTarget into tTempMasterArray
         
         local tCurrentPropertiesArray
         put the properties of tTarget into tCurrentPropertiesArray
         --compare the temporary master with the current properties
         --any changes:
         --the original tempMaster value gets added to the current master array
         --and the new value gets created in the current profile array
         
         local tCurrentPropertyKeys
         put keys(tCurrentPropertiesArray) into tCurrentPropertyKeys
         set the caseSensitive to true
         repeat for each line l in tCurrentPropertyKeys
            if tTempMasterArray[l] is not tCurrentPropertiesArray[l] then
               put tTempMasterArray[l] into tCurrentMasterArray[l]
               
               local tProfileArray
               put tCurrentPropertiesArray[l] into tProfileArray[l]
            end if
         end repeat
         --transfer the current profile array to the object
         set the customPropertySet of tTarget to "cREVDiverged" & the cREVGeneral["profile"] of tTarget
         set the customProperties of tTarget to tProfileArray
         --now transfer the current master array to the master profile
         set the customPropertySet of tTarget to "cREVMaster"
         set the customProperties of tTarget to tCurrentMasterArray
      end if
      
      # MW-2010-10-14: [[ Bug 9060 ]] In 4.5 the 'id' property of objects became mutable - we never
      #    want to set this property as part of a profile, so make sure its never in the array.
      delete variable tCurrentMasterArray["id"]
      set the properties of tTarget to tCurrentMasterArray
      set the cREVGeneral["profile"] of tTarget to "Master"
   end if
   if pWhichProfile is not empty and pWhichProfile is not "master" and pWhichProfile is not the cREVGeneral["masterName"] of tTarget then
      set the cREVGeneral["profile"] of tTarget to pWhichProfile
      set the customPropertySet of tTarget to "cREVDiverged"&pWhichProfile
      
      local tTempArray1
      if the customKeys of tTarget is not empty then put the customProperties of tTarget into tTempArray1
      
      # MW-2010-10-14: [[ Bug 9060 ]] In 4.5 the 'id' property of objects became mutable - we never
      #    want to set this property as part of a profile, so make sure its never in the array.
      delete variable tTempArray1["id"]
      set the properties of tTarget to tTempArray1
   end if
   set the customPropertySet of tTarget to tReturnSet
   unlock screen
   unlock messages
end cREVGeneral

--function revAppVersion

--function revLoadedStacks pWhich

--function revStackNameIsIDEStack pStackName

--function revFilterStacksList pStacks

--command revRotatePoly pGraphic, pAngle

#--command revRotatePolygonOld pGraphic, pAngle

--function revPoints pGraphic

#--function revUnixFromMacPath thePath

#--function revMacFromUnixPath thePath

#--function revWindowsFromUnixPath pUnixPath

--on revCopyFile pSrcFile, pDestFile

#--private command log pMessage

#--on mouseDoubleUp pButtonNo, pTarget

--on revCopyFolder pSrcFolder, pDestFolder

--on revCopyFolder__Standalone pSrcFolder, pDestFolder

#--on revCopyPackage pSrcFolder, pDestFolder

--on revDeleteFolder pSrcFolder

--on revDeleteFile pWhich

--on revMoveFolder pSrcFolder, pDestFolder

#--function revPathtoApplescript pPath

--private function createCopyFileResult pPath, pDestination

#--function revApplescriptFull pFunction, pSrc, pDest

#--private function buildCopyFileApplescript pSrc, pDest, pReplace

#--on revChangeWindowSize pWidth, pHeight, pSlide, pCard, pDelay

#--on revChangePage --empty handler

#--on revUpdateCellValue --empty handler

#--on revMoveCellDirection --empty handler

on revDatabaseError pType, pError, pDataLinkedObject
   local tResult
   put the cREVDatabaseQuery["sqlresult"] of pDataLinkedObject into tResult
   if tResult is a number then
      exit revDatabaseError
   end if
   if tResult is "empty" then 
      put empty into tResult
   end if
   
   local tErrorMessage
   switch pType
      case "Connect"
         put "There was an error in connecting to the database. Please check that the connection fields are correct." & cr & "Revdb error:" && tResult into tErrorMessage
         break
      case "ReadData"
         put "No such record found in the database:" && short name of pError & cr & "Revdb error:" && tResult into tErrorMessage
         break
      case "WriteData"
         put "Update failed on the SQL command:" && pError & cr & "Revdb error:" && tResult into tErrorMessage
         break
      case "NoKey"
         put "No primary key has been entered for the database:" && short name of pError & cr & "Revdb error:" && tResult into tErrorMessage
         break
      case "NoTable"
         put "No table has been selected for updating the database: " && short name of pError  & cr & "Revdb error:" && tResult into tErrorMessage
         break
      case "NoQuery"
         put "No SQL command set in the database:" && short name of pError into tErrorMessage
         break
      case "ExecuteQuery"
         put "An error resulted for the SQL command in the database:" && short name of pError & cr & "Revdb error:" && tResult into tErrorMessage
         break 
      case "EmptyView"
         put "No records returned in the database:" && short name of pError into tErrorMessage
         break
      default
         put "An error has occurred with the database:" && short name of pError & cr & "Revdb error:" && tResult into tErrorMessage
   end switch
   
   answer error tErrorMessage
end revDatabaseError

--function revAnswerFile pType, pPrompt

--function revAnswerFiles pType, pPrompt

--command scrollUp

--command scrollDown

--command scrollLeft

--command scrollRight

--command revFontApplySystemStyle pObject, pSize, pStyles

--function revFontGetSystemFont

--function revFontGetSystemFontSize

--function  revFontGetSystemFontStyles

--private command _revFontApplyStylesToObject pObject, pFont, pSize, pStyle

--private function _revFontGetPlatform

--private function _revEnvironmentPlatform

# Parameters
#   pPath : Any valid path that can be ensured
# Returns
#   empty if successful, an error string otherwise
# Description
#   Makes sure that a path exists by creating any folders that are required.
#   Will take a path including a filename, but will not create the file, only
#   the folders that contain it.
command revEnsurePath pPath
   if pPath is empty then
      exit revEnsurePath
   end if
   
   if there is a folder pPath or there is a file pPath then
      exit revEnsurePath
   end if
   
   local tPath, tPart
   set the itemDelimiter to slash
   repeat for each item tPart in pPath
      put tPart & "/" after tPath
      if there is no folder tPath then
         create folder tPath
      end if
   end repeat
end revEnsurePath

--function revLicenseType

#--function macVersionLessThan pLeft, pRight

# Parameters
#   pObject : either a long id or a valid reference to an object.
# Returns
#   The "rugged" id of the object. This can be used the same as a long id,
#   but is slightly more resistant to stuff like objects being grouped, renamed etc.
#   The script editor uses rugged ids to store object ids when there is a chance that the object
#   could be renamed or grouped etc. 
function revRuggedId pObject
   # First get the long id of our object. If pObject is a valid object reference we just get the 
   # object's long id. If its not a valid reference, this does not always mean the object doesn't
   # exist (because of edit group mode), in this case we assume that pObject is the long id of the object
   # we want, and parse it directly to obtain the rugged id, without needing to refer to the actual
   # object at all.
   local tObject
   if there is a pObject then
      put the long id of pObject into tObject
   else
      put pObject into tObject
      # MDW-2015-08-21: [[ bugfix_revRuggedId ]] pObject is empty when creating a new object
      if tObject is empty then
         put the long id of the target into tObject
      end if
   end if
   
   # Find out what the name of the stack owning the object is. We are only interested in the 
   # stack that immediately owns the object, which could be a substack. To find this we can
   # simply search from the front and find the first ocurrence of "of stack".
   local tSubStack, tMainstack
   local tStackFound
   local tWordNumber
   put 1 into tWordNumber
   repeat for each word tWord in tObject
      # The first match is always the substack, the second (and last) match is always the mainstack
      if tWord is "stack" then
         if tStackFound then
            put tMainStack into tSubStack
            put word (tWordNumber + 1) of tObject into tMainStack
            exit repeat
         else
            put word (tWordNumber + 1) of tObject into tMainStack
         end if
         put true into tStackFound
      end if
      add 1 to tWordNumber
   end repeat
   
   try
      local tStack
      if tSubStack is not empty then
         put "stack " & tSubStack & " of " & (the name of stack (char 2 to -2 of tMainStack)) into tStack
      else
         put (the name of stack (char 2 to -2 of tMainStack)) into tStack
      end if
   catch tError
      
   end try
   
   # MW-2008-09-08: [[ Bug 7142 ]] If the hcAddressing of the stack is true, then the long id
   #    is in a different form than this expects. Thus we temporarily fetch it while hcAddressing
   #    is false.
   if there is a tStack and the hcAddressing of tStack then
      set the hcAddressing of tStack to false
      put the long id of pObject into tObject
      set the hcAddressing of tStack to true
   end if
   
   local tType
   put word 1 of tObject into tType
   
   local tId
   if tType is "stack" then
      # With stacks, the name is the most robust way to refer to them. We assume that the stack exists...
      put tStack into tId
   else if tType is "audioclip" then
      put "audioclip id" && word 3 of tObject & " of " & tStack into tId
   else if tType is "videoclip" then
      put "videoclip id" && word 3 of tObject & " of " & tStack into tId
   else
      # With any other object, the safest thing is to return the object id and the name of its owning stack.
      # For cards we use "card id..." for other objects "control id..". This is significant because when in
      # edit group mode, the group being edited can be referred to as "control id.." but *not* "group id..."
      
      local tPrefix
      if tType is "card" then
         put "card" into tPrefix
      else
         put "control" into tPrefix
      end if
      put tPrefix & " id " & word 3 of tObject & " of " & tStack into tId
   end if
   
   return tId
end revRuggedId
