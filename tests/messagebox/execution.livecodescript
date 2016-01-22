script "MessageBoxExecution"
/*
Copyright (C) 2015 LiveCode Ltd.

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

on TestSetup
   local tIDELibrary, tScript
   put TestGetIDERepositoryPath() & "/Toolset/libraries/revidelibrary.8.livecodescript" into tIDELibrary
   
   -- Work around the fact that the property listener is not available in standalone mode
   put the script of stack tIDELibrary into tScript
   replace "_internal" with "--_internal" in tScript
   replace "the revObjectListeners" with "empty" in tScript
   replace "the effective revAvailableHandlers of pObject" with "empty" in tScript
   set the script of stack tIDELibrary to tScript

   insert the script of stack "revIDELibrary" into back
end TestSetup

on TestBug16281
	local tValidScript, tButton
	create button
	put the long id of it into tButton
	
	ideExecuteScript "hilite" && tButton, empty, empty, false, tValidScript
	
	TestAssert "hilite command in msg box", the hilite of tButton
end TestBug16281

on TestBug15832
	local tStack
	create stack
	put the short name of it into tStack
	
	-- Create button and field on the stack
	set the defaultStack to tStack
	create button
	create field
	
	-- Change the defaultStack
	create stack
	set the defaultStack to the short name of it
	
	local tValidScript
	ideExecuteScript "put the name of button 1; put the name of control 2;", tStack, empty, false, tValidScript

	TestAssert "; in single line message box", word 1 of msg is "field"
end TestBug15832

on TestGlobalPropertyCompleted
	local tValidScript
	ideExecuteScript "backdrop", empty, empty, false, tValidScript
	
	TestAssert "global prop value with 'put the' prepended", msg is "none"
	TestAssert "global prop executed with 'put the' prepended", tValidScript is "put the backdrop"
	
	ideExecuteScript "the backdrop", empty, empty, false, tValidScript
	
	TestAssert "global prop value with 'put' prepended", msg is "none"
	TestAssert "global prop executed with 'put' prepended", tValidScript is "put the backdrop"
end TestGlobalPropertyCompleted

on TestIntelligenceObjectMultilineCommand
	local tScript
	put "on valueCommand; return" && quote & "value" & quote & "; end valueCommand" into tScript
	put return & "function valueFunction; return" && quote & "value" & quote & "; end valueFunction" after tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript
	ideExecuteScript "valueCommand; put the result", empty, tStack, false, tValidScript
	
	TestAssert "intelligence object multiple command result", msg is "value"
	TestAssert "intelligence object multiple command executed", tValidScript is "valueCommand; put the result"
	
	ideExecuteScript "put valueFunction(); put msg", empty, tStack, false, tValidScript
	
	TestAssert "intelligence object multiple function result", msg is "value"
	TestAssert "intelligence object multiple function executed", tValidScript is "put valueFunction(); put msg"
end TestIntelligenceObjectMultilineCommand

on TestIntelligenceObject
	local tScript
	put "on valueCommand; set the cValue of me to" && quote & "value" & quote & "; end valueCommand" into tScript
	put return & "function valueFunction; return" && quote & "value" & quote & "; end valueFunction" after tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript
	ideExecuteScript "valueCommand", empty, tStack, false, tValidScript
	
	TestAssert "intelligence object command result", the cValue of tStack is "value"
	TestAssert "intelligence object command executed", tValidScript is "valueCommand"
	
	ideExecuteScript "valueFunction()", empty, tStack, false, tValidScript
	
	TestAssert "intelligence object function in msg box", msg is "value"
	TestAssert "intelligence object function executed", tValidScript is "put valueFunction()"
end TestIntelligenceObject

on TestIntelligenceObjectMultipleCommand
	local tScript
	put "on firstCommand; ; end firstCommand" into tScript
	put return & "on secondCommand; set the cValue of me to" && quote & "value" & quote & "; end secondCommand" after tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript
	ideExecuteScript "firstCommand; secondCommand", empty, tStack, false, tValidScript
	
	TestAssertBroken "intelligence object mutiple commands", the cValue of tStack is "value", "Bug 16318"
end TestIntelligenceObjectMultipleCommand

on TestDefaultStackCardScript
	local tScript
	put "on preOpenCard; set the cValue of this stack to" && quote & "value" & quote && "; end preOpenCard" into tScript

	local tStack
	create stack
	put the long id of it into tStack
	set the script of card 1 of tStack to tScript
	
	local tValidScript
	ideExecuteScript "preOpenCard", tStack, empty, false, tValidScript
	
	TestAssert "intelligence object command result", the cValue of tStack is "value"
	TestAssert "intelligence object command executed", tValidScript is "preOpenCard"
end TestDefaultStackCardScript
