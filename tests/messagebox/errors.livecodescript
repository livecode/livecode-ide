script "MessageBoxErrors"
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

local sSupportStack
on TestSetup   
   set the itemdelimiter to slash
   local tSupportStack
   put the filename of me into tSupportStack
   put "_support.livecodescript" into item -1 of tSupportStack
   put tSupportStack into sSupportStack
   start using stack sSupportStack
   
   put empty into msg
   MessageBoxSetEmpty
end TestSetup

on TestTeardown
   stop using stack sSupportStack
end TestTeardown

on TestBug17380
   revIDELaunchResource("sample stacks")
   MessageBoxIsEmpty
   
   TestAssert "message box is empty after opening revOnline stack", the result
end TestBug17380

on TestMessageBoxCompileError
   local tValidScript, tScript
   // Should be "if true then..."
   put "if true ten go home" into tScript
   
   ideExecuteScript tScript, empty, false, tValidScript
   TestAssert "execute script with compile error result", line 1 of the result is "189,2,4,ten"
   TestAssert "execute script with compile error script invalid", tValidScript is empty
end TestMessageBoxCompileError

on TestMessageBoxExecutionError
   local tValidScript, tScript
   put "edit the script of stack nonexistent" into tScript
   
   ideExecuteScript tScript, empty, false, tValidScript
   TestAssert "execute script with script error result", \
         matchText(line 1 of it, "^91,\d+,1$")
   TestAssert "execute script with script error script invalid", tValidScript is tScript
end TestMessageBoxExecutionError

on TestMessageBoxExecuteMultipleWithError
   local tValidScript, tScript
   put "put foo; throw bar" into tScript
   
   ideExecuteScript tScript, empty, false, tValidScript
   TestAssert "execute multiline script with script error result", msg is "foo"
   TestAssert "execute multiline script with compile error script invalid", tValidScript is tScript
end TestMessageBoxExecuteMultipleWithError

-- Bug 17863
on TestIntelligenceObjectGetNonExistentFunction
   local tStack
	create stack
	put it into tStack
	
   local tToExecute, tValidScript
	put "get aNonExistentFunction()" into tToExecute
	
	ideExecuteScript tToExecute, tStack, false, tValidScript
	
	TestAssert "intelligence object non-existent function result", \
         matchText(line 1 of it, "^219,\d+,\d+,aNonExistentFunction$")
	TestAssert "intelligence object non-existent function executed", tValidScript is tToExecute
end TestIntelligenceObjectGetNonExistentFunction

-- Bug 17241
on TestIntelligenceObjectPutFunctionWithParamError
	local tScript
	put "function valueFunction pParam; return pParam; end valueFunction" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript

	local tValidScript

	ideExecuteScript "put valueFunction(hello world)", tStack, false, tValidScript
	TestAssert "intelligence object put function with multi-segment param error", the result is "126,2,19,world"
	TestAssert "intelligence object put function with multi-segment param invalid", tValidScript is empty
end TestIntelligenceObjectPutFunctionWithParamError