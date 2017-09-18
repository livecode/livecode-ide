script "ScriptEditorIndentation"
/*
Copyright (C) 2017 LiveCode Ltd.

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

local sStack

on TestSetup
   local tBehavior
   put TestGetIDERepositoryPath() & "/Toolset/palettes/script editor/behaviors/revsecommoneditorbehavior.livecodescript" into tBehavior
   put the name of stack tBehavior into sStack
end TestSetup

on TestIndents
   set the itemDelimiter to slash
   local tPath
   put item 1 to -2 of the effective filename of me & "/_indentation_tests" into tPath
   set the itemDelimiter to "."
   repeat for each line tFile in files(tPath)
      if tFile begins with "." then
         next repeat
      end if
      
      local tScript
      put textDecode(url ("binfile:" & tPath & "/" & tFile),"UTF8") into tScript
      -- normalise the snippet
      if the last char of tScript is not return then
         put return after tScript
      end if
      replace tab with "   " in tScript
      
      -- strip leading whitespace
      local tUnindented
      put replaceText(tScript, "\n +", return) into tUnindented
      put replaceText(tUnindented, "^ +", "") into tUnindented
      
      dispatch "scriptFormatSnippet" to sStack with tUnindented
      local tResult
      put the result into tResult
      if the last char of tResult is not return then
         put return after tResult
      end if
      TestAssert "script snippet indented correctly:" && item 1 of tFile, tResult is tScript
      if tResult is not tScript then
         repeat with tIndex=1 to the number of lines of tResult
            if line tIndex of tResult is not line tIndex of tScript then
               put "* " before line tIndex of tResult 
            else
               put "  " before line tIndex of tResult 
            end if
         end repeat
         TestDiagnostic tResult
      end if
   end repeat
end TestIndents
