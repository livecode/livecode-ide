script "IDETestRunner"
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

private function getTestRunnerBehavior
   -- Compute the filename of the test runner
   local tRepoPath, tStack
   set the itemdelimiter to "/"
   put item 1 to -4 of the effective filename of me into tRepoPath
   put tRepoPath & "/tests/_testrunnerbehavior.livecodescript" into tStack
   return the long id of stack tStack
end getTestRunnerBehavior

local sStarted
local sTestsRun = false
private command startTestRunner
   if sStarted then
      exit startTestRunner
   end if
   put true into sStarted

   local tTestRunner
   put getTestRunnerBehavior() into tTestRunner
   set the behavior of me to tTestRunner
   if the environment begins with "development" then
      if not sTestsRun then
	     send "TestRunnerImpl_DoInvoke" to me in 0
	  end if  
	  put true into sTestsRun
   else
	  send "TestRunnerMain" to me in 0
   end if
end startTestRunner

on startup
   local tTarget
   if the target begins with "card" then
      put the long id of the owner of the target into tTarget
   else
      put the long id of the target into tTarget
   end if
   
   if tTarget is the long id of me then 
      startTestRunner
   end if
end startup 

on openStack
   if the long id of the target is the long id of this card of me then
      startTestRunner
   end if
end openStack

----------------------------------------------------------------
-- Top-level actions
----------------------------------------------------------------

command TestRunnerImpl_DoInvoke pInfo
   TestRunnerRunLoadLibraries
   TestRunnerInvokeLoadLibraries
    
   -- Don't output to stdout
   TestOutputToVariable
   
   if pInfo["invoke"]["script"] is not empty then
      invokeTest pInfo
   else
      invokeAllTests
   end if
end TestRunnerImpl_DoInvoke

command TestRunnerImpl_DoRun pInfo
	runAllTests pInfo
	return the result for value
end TestRunnerImpl_DoRun

private command TestRunnerImpl_DoUsage pStatus
   write "Usage: _testrunner.livecodescript run DEV-ENGINE" & return to stderr
   quit pStatus
end TestRunnerImpl_DoUsage

----------------------------------------------------------------
-- Support for invoking test commands
----------------------------------------------------------------

private command invokeLoadIDE
	-- Compute the filename of the home stack
	local tFilename
	put the filename of me into tFilename

	set the itemDelimiter to slash
	put "Toolset/home.livecodescript" into item -2 to -1 of tFilename

	local tStackName
	-- load home stack
	put the name of stack tFilename into tStackName

	-- Set the 'test environment' to true
	dispatch "revSetTestEnvironment" to stack tStackName with true
	
	insert the script of tStackName into back
	
	dispatch "startup" to tStackName	
	TestAssert "IDE startup without error", the result is empty
	
	open tStackName
end invokeLoadIDE

private command TestLoadIDE   
   if there is not a stack "home" then
      local tDefaultFolder
      put the defaultFolder into tDefaultFolder
	  
	  try
	     invokeLoadIDE
	  catch tError
	  end try
	  
	  TestAssert "Home stack opens without error", tError is empty
	  TestDiagnostic tError
	  
	  TestAssert "IDE load preserves defaultFolder", \
   	     the defaultFolder is tDefaultFolder

      TestDiagnostic "original default folder:" && tDefaultFolder
      TestDiagnostic "new default folder:" && the defaultFolder
   end if

   -- gRevDevelopment should be true by default
   global gRevDevelopment
   put true into gRevDevelopment

   local tStartupError
   put revEnvironmentGetStartupLog("Error") into tStartupError
   TestAssert "Home stack opens without error", tStartupError is empty
	
   if tStartupError is not empty then
      TestDiagnostic revEnvironmentGetStartupLog("Message")
   end if
   
   local tAnalysis
   TestUpdateAnalysis the effective filename of me, \
	   "TestLoadIDE", tAnalysis
   return tAnalysis
end TestLoadIDE

private command TestUpdateAnalysis pFilename, pTestCommand, @xAnalysis
   local tOutput   
   put TestFetchAndClearOutput() into tOutput
   write textEncode(tOutput,"utf-8") to stdout
   TestRunnerProcessOutput pFilename, pTestCommand, tOutput
   put TesterTapCombine(xAnalysis, the result) into xAnalysis
end TestUpdateAnalysis

private command appendToList pElt, @xList
   put pElt into xList[the number of elements in xList + 1]
end appendToList

private function getAllTestFileNames
   local tIDETests, tIDESupportTests
   put TestGetIDERepositoryPath() & "/tests" into tIDETests
   put TestGetEngineRepositoryPath() & "/tests/ide-support" into tIDESupportTests
   
   local tFiles
   repeat for each element tFile in TesterGetTestFileNames(tIDETests)
      appendToList tIDETests & slash & tFile, tFiles
   end repeat
   
   repeat for each element tFile in TesterGetTestFileNames(tIDESupportTests)
      appendToList tIDESupportTests & slash & tFile, tFiles
   end repeat

   return tFiles
end getAllTestFileNames

private command invokeAllTests      
   local tAnalysis   
   TestLoadIDE
   put the result into tAnalysis

   repeat for each element tFile in getAllTestFileNames()
      invokeTestScript tFile
      put TesterTapCombine(tAnalysis, the result) into tAnalysis
   end repeat
   
   TesterRunPrintSummary tAnalysis
   quit 0
end invokeAllTests

private command invokeTest pInfo
   local tScriptFile, tCommand

   -- This should auto-load the test script
   put pInfo["invoke"]["script"] into tScriptFile
   put pInfo["invoke"]["command"] into tCommand
   TestRunnerInvokeTestCommand tScriptFile, tCommand
end invokeTest

-- Run the tests found in one specific script file
private command invokeTestScript pScriptFile
   -- Don't output to stdout
   TestOutputToVariable
   
   local tCommand, tAnalysis, tOutput
   repeat for each element tCommand in TesterParseTestCommandNames(pScriptFile)
      invokeTestCommand pScriptFile, tCommand
      TestUpdateAnalysis pScriptFile, tCommand, tAnalysis
   end repeat
   return tAnalysis
end invokeTestScript

-- Execute a test
private command invokeTestCommand pScriptFile, pCommand
   -- Try and remove any stacks that have been opened
   local tStacks
   put the openstacks into tStacks
   
   --Make sure this is not the default stack
   create stack
   set the defaultStack to the short name of it

   TestRunnerInvokeTestCommand pScriptFile, pCommand
   
   -- Attempt to restore IDE to its pre-test state
   global gRevStackStatus
   repeat for each line tStack in the openstacks
      if tStack is not among the lines of tStacks then
         -- Ensure IDE doesn't prompt for save
         put empty into gRevStackStatus[tStack]
         delete stack tStack
      end if
   end repeat
end invokeTestCommand

----------------------------------------------------------------
-- Support for running tests
----------------------------------------------------------------

-- Launch this stack in the IDE
private command runAllTests pInfo
   local tAnalysis
   	
   -- Invoke the test in a subprocess.  This ensures that we can detect
   -- if a crash occurs
   local tTestOutput, tTestExitStatus, tCommand
   
   -- First put the target engine into the command to run
   put pInfo["args"][2] into tCommand
   
   -- Add the command line args
   repeat with x = 3 to the number of elements in pInfo["args"]
      put tCommand && pInfo["args"][x] into tCommand
   end repeat
   
   -- Add the target stack (this one)
   put tCommand && pInfo["self-script"] && "2>/dev/null" into tCommand

   -- Execute the shell command   
   open process tCommand for text read
   set the itemDelimiter to ":"
   repeat
      if tCommand is not among the lines of the openProcesses then
         exit repeat
      end if
      
      local tResult
      read from process tCommand for 1 line
      put the result into tResult
      
      local tOutput
      -- The output from the subprocesses will be native encoded utf-8.
      put textDecode(it, "utf8") into tOutput
      
      if item 1 of tOutput is "PASS" or \
            item 1 of tOutput is "XPASS" or \
            item 1 of tOutput is "FAIL" or \
            item 1 of tOutput is "XFAIL" then
         TesterLog item 1 of tOutput, item 2 to -1 of line 1 of tOutput
      else if tOutput begins with "not ok" then
         write tOutput to stdout
      end if
      
      put tOutput after tTestOutput
      if tResult is not empty then
         exit repeat
      end if
   end repeat
   set the itemDelimiter to comma
   close process tCommand
   
   -- Check the exit status.  If it suggests failure, add a "not ok" stanza
   -- to the tail of the TAP output
   --!TODO Can't get exit status from open process
   if tTestExitStatus is not empty then
      put return after tTestOutput
      put "not ok # Subprocess exited with status" && \
            tTestExitStatus & return after tTestOutput
   end if
      
   TestRunnerProcessOutput "IDE", "All IDE tests", tTestOutput
   
   put TesterTapCombine(tAnalysis, the result) into tAnalysis
   TesterRunPrintSummary tAnalysis
   return tAnalysis
end runAllTests
