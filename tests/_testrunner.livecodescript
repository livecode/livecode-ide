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

-- FIXME provide this on the command line
constant kLogFilename = "_test_suite.log"

local sTestsRun = false

on startup
   local tTarget
   if the target begins with "card" then
      put the long id of the owner of the target into tTarget
   else
      put the long id of the target into tTarget
   end if
   
   if tTarget is the long id of me then 
      if the environment begins with "development" then
         if not sTestsRun then
            send "TestRunnerInvokeAll" to me in 0
         end if
         put true into sTestsRun
      else
         send "TestRunnerMain" to me in 0
      end if
   end if
end startup 

on openStack
   if the long id of the target is the long id of this card of me then
      if not sTestsRun then
         send "TestRunnerInvokeAll" to me in 0
      end if
      put true into sTestsRun
   end if
end openStack

----------------------------------------------------------------
-- Command-line processing
----------------------------------------------------------------

private function getCommandLineInfo
   local tRawArg, tSelfCommand, tSelfScript, tInArgs, tArgs

   put false into tInArgs

   -- Treat everything up to & including the first
   -- ".livecodescript" file as the command for running the test
   -- runner, and everything after it as test runner arguments
   put the commandName into tSelfCommand[1]
   repeat for each element tRawArg in the commandArguments

      if tInArgs then
         put tRawArg into tArgs[1 + the number of elements in tArgs]
      else
         put tRawArg into tSelfCommand[1 + the number of elements in tSelfCommand]
         if tRawArg ends with ".livecodescript" then
            put tRawArg into tSelfScript
            put true into tInArgs
         end if
      end if

   end repeat

   local tInfo
   put tSelfCommand into tInfo["self-command"]
   put tSelfScript into tInfo["self-script"]
   put tArgs into tInfo["args"]

   return tInfo
end getCommandLineInfo

----------------------------------------------------------------
-- Top-level actions
----------------------------------------------------------------

command TestRunnerMain
   local tInfo
   put getCommandLineInfo() into tInfo
   logInit

   switch tInfo["args"][1]
      case "run"
         doRun tInfo
         break
      case "--help"
      case "-h"
      case "help"
         doUsage 0
         break
      default
         doUsage 1
         break
   end switch
   quit 0
end TestRunnerMain

command TestRunnerInvokeAll
   invokeAllTests
end TestRunnerInvokeAll

private command doRun pInfo
   if pInfo["args"][2] is empty then
      doUsage 1
   end if

   runLoadLibrary pInfo
   
   local tAnalysis
   runAllTests pInfo
   put the result into tAnalysis
   
   -- Save the log to file.
   -- We process to binary data ourselves to ensure encoding and
   -- line endings are appropriate.
   local tLogForWriting
   put textEncode(tAnalysis["log"], "utf8") into tLogForWriting
   if the platform is "win32" then
      replace return with numToChar(13) & numToChar(10) in tLogForWriting
   end if
   put tLogForWriting into url ("binfile:" & kLogFilename)
   
   if TesterTapGetWorstResult(tAnalysis) is "FAIL" then
      quit 1
   end if
end doRun

private command doUsage pStatus
   write "Usage: _testrunner.livecodescript run DEV-ENGINE" & return to stderr
   quit pStatus
end doUsage

on ErrorDialog pExecutionError
   write "ERROR:" && pExecutionError & return to stderr
   quit 1
end ErrorDialog

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
	put the name of stack tFilename into tStackName
	
	insert the script of tStackName into back
	
	dispatch "startup" to tStackName
	open tStackName
	
	-- Set the 'test environment' to true
	revSetTestEnvironment true
end invokeLoadIDE

private command TestUpdateAnalysis pFilename, pTestCommand, @xAnalysis
   local tOutput   
   put TestFetchAndClearOutput() into tOutput
   write textEncode(tOutput,"utf-8") to stdout
   runTestProcessOutput pFilename, \
	   pTestCommand, tOutput
   put TesterTapCombine(xAnalysis, the result) into xAnalysis
end TestUpdateAnalysis

private command TestLoadIDE
   local tDefaultFolder
   put the defaultFolder into tDefaultFolder
   
   local tLoadResult
   if there is not a stack "home" then
	   invokeLoadIDE
	   put the result into tLoadResult
   end if

   -- gRevDevelopment should be true by default
   global gRevDevelopment
   put true into gRevDevelopment

   invokeLoadLibrary
   
   -- Don't output to stdout
   TestOutputToVariable

   TestAssert "IDE loads without error", tLoadResult is empty

   TestAssert "IDE load preserves defaultFolder", \
   	  the defaultFolder is tDefaultFolder

   TestDiagnostic "original default folder:" && tDefaultFolder
   TestDiagnostic "new default folder:" && the defaultFolder
   
   local tAnalysis
   TestUpdateAnalysis the effective filename of me, \
	   "TestLoadIDE", tAnalysis
   return tAnalysis
end TestLoadIDE

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
   
   runPrintSummary tAnalysis
   quit 0
end invokeAllTests

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
   
   local tStackName, tResult
   
   -- This should auto-load the test script
   put the name of stack pScriptFile into tStackName
   
   -- Check that the stack script actually compiles
   lock messages
   set the script of tStackname to the script of tStackname
   put the result into tResult
   unlock messages
   if tResult is not empty then
      TestDiagnostic tResult
   end if
   TestAssert "script compiles", tResult is empty
   
   --Make sure this is not the default stack
   create stack
   set the defaultStack to the short name of it
   
   -- Dispatch the test setup command, and check if skipping was requested
   dispatch "TestSetup" to tStackName
   put the result into tResult
   if word 1 of tResult is "SKIP" then
      TestSkip pCommand, word 2 to -1 of tResult
   else
	   -- Run the actual test itself
	   try
	      dispatch pCommand to tStackName
	   catch tError
	      TestAssert "execution failure:" && tError, false
	   end try
   
	   -- Do common cleanup tasks
	   dispatch "TestTearDown" to tStackName
   end if
   
   global gRevStackStatus
   repeat for each line tStack in the openstacks
      if tStack is not among the lines of tStacks then
         -- Ensure IDE doesn't prompt for save
         put empty into gRevStackStatus[tStack]
         delete stack tStack
      end if
   end repeat
end invokeTestCommand

-- Add the unit test library stack and the input library to the backscripts
private command invokeLoadLibrary
   local tLibrary, tStackName, tStackFile, tRepoPath
   put revEnvironmentRepositoryPath() into tRepoPath
   repeat for each item tLibrary in "_testlib,_inputlib,_testerlib"
      -- Compute the filename of the library stack and load it
      put tRepoPath & slash & "tests" & slash & tLibrary & ".livecodescript" into tStackFile
      put the name of stack tStackFile into tStackName
      
      send "revLoadLibrary" to stack tStackname
   end repeat
end invokeLoadLibrary


----------------------------------------------------------------
-- Support for running tests
----------------------------------------------------------------

-- Add the test runner library stack to the backscripts
private command runLoadLibrary pInfo
   -- Compute the filename of the library stack
   local tFilename
   put the effective filename of me into tFileName
   set the itemDelimiter to slash
   put "tests/_testerlib.livecodescript" into item -3 to -1 of tFilename
   -- Load the library
   local tStackname
   put the name of stack tFilename into tStackname
   
   send "revLoadLibrary" to stack tStackname
end runLoadLibrary

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
   put tCommand && pInfo["self-script"] into tCommand
   
   -- Execute the shell command   
   open process tCommand for text read
   set the itemDelimiter to ":"
   repeat
      if tCommand is not among the lines of the openProcesses then
         exit repeat
      end if
      
      read from process tCommand for 1 line
      local tOutput
      -- The output from the subprocesses will be native encoded utf-8.
      put textDecode(it, "utf8") into tOutput
      
      if item 1 of tOutput is "PASS" or \
            item 1 of tOutput is "XPASS" or \
            item 1 of tOutput is "FAIL" or \
            item 1 of tOutput is "XFAIL" then
         write logHighlight(item 1 of tOutput) & ":" & item 2 to -1 of tOutput to stdout
      else if tOutput begins with "not ok" then
         write tOutput to stdout
      end if
      
      put tOutput after tTestOutput
      if the result is not empty then
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
   
   runTestProcessOutput "IDE", "All IDE tests", tTestOutput
   
   put TesterTapCombine(tAnalysis, the result) into tAnalysis
   runPrintSummary(tAnalysis)
   return tAnalysis
end runAllTests

private command runTestProcessOutput pScriptfile, pCommand, pOutput
   -- Create test log
   local tTestLog
   put "###" && TesterGetPrettyTestName(pScriptFile) && pCommand \
         & return & return into tTestLog
   put pOutput & return after tTestLog

   -- Analyse the results and print a summary line
   local tTapResults
   put TesterTapAnalyse(tTestLog) into tTapResults

   logSummaryLine tTapResults, (TesterGetPrettyTestName(pScriptFile) & ":" && pCommand)

   return tTapResults
end runTestProcessOutput


-- Print out a table of statistics
private command runPrintSummary pAnalysis
   local tSummaryString, tTotal, tDecoration

   put TesterTapGetTestCount(pAnalysis) into tTotal

   -- Format basic summary information
   if pAnalysis["xfail"] is 0 and pAnalysis["fail"] is 0 then
      put "All" && tTotal && "tests passed" into tSummaryString

   else if pAnalysis["fail"] is 0 then
      put "All" && tTotal && "tests behaved as expected" into tSummaryString

   else
      put pAnalysis["fail"] && "OF" && tTotal && "TESTS FAILED" into tSummaryString
   end if

   put return after tSummaryString

   -- Add extra summary info from expected failure & skip directives
   if pAnalysis["xpass"] > 0 then
      put tab & pAnalysis["xpass"] && "unexpected passes" & return after tSummaryString
   end if
   if pAnalysis["xfail"] > 0 then
      put tab & pAnalysis["xfail"] && "expected failures" & return after tSummaryString
   end if
   if pAnalysis["skip"] > 0 then
      put tab & pAnalysis["skip"] && "skipped" & return after tSummaryString
   end if

   put "================================================================" into tDecoration
   put tDecoration & return before tSummaryString
   put tDecoration & return after tSummaryString

   write tSummaryString to stdout
end runPrintSummary

----------------------------------------------------------------
-- Logging helpers
----------------------------------------------------------------

local sLogInfo

-- Figure out what the highlighting escape codes are for the terminal
--
-- FIXME this really doesn't work properly if LiveCode's stdout
-- *isn't* a TTY.
private command logInit
   -- We can only do colour on Linux and OS X
   if the platform is not "Linux" and the platform is not "MacOS" then
      put false into sLogInfo
   end if

   -- Check if colouring is possible
   local tTput
   put shell("tput colors") into tTput
   if the result is not empty or tTput <= 8 then
      put false into sLogInfo
   end if

   -- Get colours
   put shell("tput sgr0") into sLogInfo["normal"]
   put shell("tput bold") into sLogInfo["bold"]
   put shell("tput setaf 1") into sLogInfo["red"]
   put shell("tput setaf 2") into sLogInfo["green"]
   put shell("tput setaf 3") into sLogInfo["yellow"]
   put shell("tput setaf 6") into sLogInfo["cyan"]
end logInit

private function logHighlight pString
  if pString is "fail" then
     return sLogInfo["red"] & sLogInfo["bold"] & pString & sLogInfo["normal"]
  else if pString is "xfail" or pString is "xpass" then
     return sLogInfo["yellow"] & pString & sLogInfo["normal"]
  else if pString is "pass" then
     return sLogInfo["green"] & pString & sLogInfo["normal"]
  else if pString is "skip" then
     return sLogInfo["cyan"] & pString & sLogInfo["normal"]
  else
     return pString
  end if
end logHighlight

private command logSummaryLine pTapResults, pTestName
   local tTotal, tPassed, tWorst, tMessage

   put pTapResults["xpass"] + pTapResults["pass"] + pTapResults["skip"] into tPassed
   put TesterTapGetTestCount(pTapResults) into tTotal

   put TesterTapGetWorstResult(pTapResults) into tWorst
   put logHighLight(the toUpper of tWorst) into tMessage
   put ":" after tMessage
   if the number of chars in tWorst < 5 then
      put space after tMessage
   end if

   put space & pTestName after tMessage

   put space & "[" & tPassed & "/" & tTotal & "]" after tMessage
   write tMessage & return to stdout
end logSummaryLine
