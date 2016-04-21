script "ProjectBrowserTestSupport"
/*
Copyright (C) 2016 LiveCode Ltd.

This file is part of LiveCode.

LiveCode is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation.

LiveCode is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with LiveCode.  If not see <http://www.gnu.org/licenses/>.  */

local sPBLongID
on libraryStack
   local tStackName
   put revIDEPaletteToStackName("project browser") into tStackName
   put the long id of stack tStackName into sPBLongID
end libraryStack

private function FetchPBDataRow pObjectLongID
	dispatch function "getRow" to sPBLongID with pObjectLongID
	return the result
end FetchPBDataRow

private function FetchPBRowGroupID pObjectLongID
   local tRow
   put FetchPBDataRow(pObjectLongID) into tRow
   
   if tRow is empty then
      return empty
   end if
   
   dispatch "scrollToRow" to sPBLongID with tRow
 	
   return the dvControlOfRow[tRow] of group "objectList" of sPBLongID
end FetchPBRowGroupID

private function CheckGroup pGroupID, pObjectID
   local tInfo
   put char 1 to -2 of the text of field "type" of pGroupID into tInfo["type"]
   put field "name" of pGroupID into tInfo["name"]
   put field "scriptLines" of pGroupID into tInfo["scriptLines"]
   
   local tBehaviorLines
   if the visible of field "behaviorScriptLines" of pGroupID then
	   put field "behaviorScriptLines" of pGroupID into tBehaviorLines
   end if
   put tBehaviorLines into tInfo["behaviorLines"]

   local tObjInfo
   put word 1 of pObjectID into tObjInfo["type"]
   put the short name of pObjectID into tObjInfo["name"]
   
   local tScript
   put the script of pObjectID into tScript
   put the number of lines in tScript into tObjInfo["scriptLines"]
   
   local tBehavior
   put the behavior of pObjectID into tBehavior
   if tBehavior is not empty then
      put the number of lines in the script of tBehavior \ 
         into tBehaviorLines
   end if
   put tBehaviorLines into tObjInfo["behaviorLines"]
	
   repeat for each key tKey in tInfo
      if tInfo[tKey] is not tObjInfo[tKey] then
         TestDiagnostic tKey && "data mismatch-" && "PB:" \ 
         	&& tInfo[tKey] && "Obj:" && tObjInfo[tKey]
         return false
      end if
   end repeat

   return true
end CheckGroup

private function DisclosureButton pObjectLongID
   local tGroup
   put FetchPBRowGroupID(pObjectLongID) into tGroup
   
   local tButton
   if tGroup is not empty then
      put the long id of button "disclosure" of tGroup into tButton
   end if
   
   return tButton
end DisclosureButton

-- Returns true if the object has a visible entry in the project browser
on ThereIsAnObject pObjectLongID
   local tGroup 
   put FetchPBRowGroupID(pObjectLongID) into tGroup
   return tGroup is not empty
end ThereIsAnObject

on ObjectDataMatches pObjectLongID
   local tGroup 
   put FetchPBRowGroupID(pObjectLongID) into tGroup
   if tGroup is empty then
      return false
   end if
   
   return CheckGroup(tGroup, pObjectLongID)
end ObjectDataMatches

-- Returns true if the object has an entry in the project browser's
-- underlying display data array
on ThereIsAnObjectData pObjectLongID
   local tRow
   put FetchPBDataRow(pObjectLongID) into tRow
   return tRow is not empty
end ThereIsAnObjectData

on ClickRowDisclosure pObjectLongID
   local tButton
   put DisclosureButton(pObjectLongID) into tButton
   
   if tButton is empty then
      return false
   end if
   
   local tDefaultStack
   put the defaultStack into tDefaultStack
   set the defaultStack to the short name of sPBLongID
   
   if the environment is "development" then
      local tLoc
      put the loc of tButton into tLoc
      click at tLoc
   else
      dispatch "mouseUp" to tButton
   end if
   
   set the defaultStack to tDefaultStack
end ClickRowDisclosure