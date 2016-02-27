script "TestSaveStackRequest"
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

private function SanitiseForTests pScript
   replace "_internal" with "--_internal" in pScript
   replace "the revObjectListeners" with "empty" in pScript
   replace "the effective revAvailableHandlers of pObject" with "empty" in pScript
   return pScript
end SanitiseForTests

on TestSetup
   local tIDELibrary, tScript
   put TestGetIDERepositoryPath() & "/Toolset/libraries/revidelibrary.8.livecodescript" into tIDELibrary

   -- Work around the fact that the property listener is not available in standalone mode
   put the script of stack tIDELibrary into tScript
   put SanitiseForTests(tScript) into tScript

   -- Fix revIDESpecialFolderPath
   local tReplace, tReplacement
   put "the filename of stack" && quote & "home" & quote into tReplace
   put quote & TestGetIDERepositoryPath() & "/Toolset/home.livecodescript" & quote into tReplacement
   replace tReplace with tReplacement in tScript

   put "stack" && quote & "revpreferences" & quote into tReplace
   put "me" into tReplacement
   replace tReplace with tReplacement in tScript

   set the script of stack tIDELibrary to tScript

   insert the script of stack tIDELibrary into back

   -- Load the revSaving stack
   local tSavingStack
   put TestGetIDERepositoryPath() & "/Toolset/palettes/revsaving.livecode" into tSavingStack
   go invisible tSavingStack

   set the defaultStack to me
end TestSetup

constant kFilename = "TestSaveStackRequest.livecode"

-- Test that handling saveStackRequest cancels saving a stack
on TestSaveStackRequest
   local tStack

   create invisible stack "SaveTest"
   put it into tStack

   set the script of tStack to "on saveStackRequest; end saveStackRequest"
   set the filename of tStack to kFileName

   revIDESaveStack tStack

   TestAssert "Handling saveStackRequest cancels save", there is not a file kFileName
end TestSaveStackRequest