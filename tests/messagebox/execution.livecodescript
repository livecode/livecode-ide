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

on TestBug16281
	local tValidScript, tButton
	create button
	put the long id of it into tButton
	
	ideExecuteScript "hilite" && tButton, empty, false, tValidScript
	
	TestAssert "hilite command in msg box", the hilite of tButton
end TestBug16281

on TestBug15832
	local tStack, tStackName
	create stack
	put it into tStack
	put the short name of tStack into tStackName
	
	-- Create button and field on the stack
	set the defaultStack to tStackName
	create button
	create field
	
	-- Change the defaultStack
	create stack
	set the defaultStack to the short name of it
	
	local tValidScript
	ideExecuteScript "put the name of button 1; put the name of control 2;", tStack, false, tValidScript

	TestAssert "; in single line message box", word 1 of msg is "field"
end TestBug15832

on TestBug16863
   local tStack
   create stack
   put it into tStack
   set the defaultStack to the short name of it
   
   create button
   set the name of it to "test"
   
   local tValidScript, tScript
   put "there is a button" && quote & "test" & quote into tScript
   
   ideExecuteScript tScript, tStack, false, tValidScript
   TestAssert "boolean expression value with 'put' prepended", msg is "true"
   TestAssert "boolean expression executed with 'put' prepended", tValidScript is ("put" && tScript)
end TestBug16863

on TestGlobalPropertyCompleted
	local tValidScript
	ideExecuteScript "backdrop", empty, false, tValidScript

	TestAssert "global prop value with 'put the' prepended", msg is the backdrop
	TestAssert "global prop executed with 'put the' prepended", tValidScript is "put the backdrop"

	put empty into msg

	ideExecuteScript "the backdrop", empty, false, tValidScript

	TestAssert "global prop value with 'put' prepended", msg is the backdrop
	TestAssert "global prop executed with 'put' prepended", tValidScript is "put the backdrop"
end TestGlobalPropertyCompleted

on TestIntelligenceObjectMultilineCommand
	local tScript
	put "on valueCommand; return" && quote & "value" & quote & "; end valueCommand" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript
	ideExecuteScript "valueCommand; put the result", tStack, false, tValidScript
	
	TestDiagnostic "msg" && msg
	TestDiagnostic "valid script:" && tValidScript
	
	TestAssert "intelligence object multiple command result", msg is "value"
	TestAssert "intelligence object multiple command executed", tValidScript is "valueCommand; put the result"
end TestIntelligenceObjectMultilineCommand

on TestIntelligenceObjectMultilineFunction
	local tScript
	put "function valueFunction; return" && quote & "value" & quote & "; end valueFunction" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript	
	ideExecuteScript "put valueFunction(); put msg", tStack, false, tValidScript

	TestAssert "intelligence object multiple function result", msg is "value"
	TestAssert "intelligence object multiple function executed", tValidScript is "put valueFunction(); put msg"
end TestIntelligenceObjectMultilineFunction

on TestIntelligenceObject
	local tScript
	put "on valueCommand; set the cValue of me to" && quote & "value" & quote & "; end valueCommand" into tScript
	put return & "function valueFunction; return" && quote & "value" & quote & "; end valueFunction" after tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript
	ideExecuteScript "valueCommand", tStack, false, tValidScript
	
	TestDiagnostic "cValue:" && the cValue of tStack
	TestDiagnostic "valid script:" && tValidScript
	
	TestAssert "intelligence object command result", the cValue of tStack is "value"
	TestAssert "intelligence object command executed", tValidScript is "valueCommand"
	
	put empty into msg
	
	ideExecuteScript "valueFunction()", tStack, false, tValidScript
	
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
	ideExecuteScript "firstCommand; secondCommand", tStack, false, tValidScript
	
	TestAssert "intelligence object mutiple commands", the cValue of tStack is "value"
end TestIntelligenceObjectMultipleCommand

on TestDefaultStackCardScript
	local tScript
	put "on preOpenCard; set the cValue of this stack to" && quote & "value" & quote && "; end preOpenCard" into tScript

	local tStack
	create stack
	put the long id of it into tStack
	set the script of card 1 of tStack to tScript
	
	local tValidScript
	ideExecuteScript "preOpenCard", tStack, false, tValidScript
	
	TestAssert "intelligence object command result", the cValue of tStack is "value"
	TestAssert "intelligence object command executed", tValidScript is "preOpenCard"
end TestDefaultStackCardScript


on TestIntelligenceObjectPutFunction
	local tScript
	put "function valueFunction; return" && quote & "value" & quote & "; end valueFunction" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript

	local tValidScript
	ideExecuteScript "put valueFunction()", tStack, false, tValidScript
	
	TestAssert "intelligence object put function", msg is "value"
end TestIntelligenceObjectPutFunction

on TestIntelligenceObjectGetFunction
	local tScript
	put "function valueFunction; return" && quote & "value" & quote & "; end valueFunction" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript

	local tValidScript

	ideExecuteScript "get valueFunction(); put it", tStack, false, tValidScript
	TestAssert "intelligence object get function result", msg is "value"
end TestIntelligenceObjectGetFunction

on TestCustomCommandWithStringLiteral
	local tScript
	put "on valueCommand pValue; set the cValue of me to pValue; end valueCommand" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript, tToExecute
	put "valueCommand" && quote & "value" & quote into tToExecute
	ideExecuteScript tToExecute, tStack, false, tValidScript
	
	TestAssert "command with string literal result", the cValue of tStack is "value"
	TestAssert "command with string literal executed", tValidScript is tToExecute
end TestCustomCommandWithStringLiteral

-- Bug 17240
on TestIntelligenceObjectPutFunctionWithParam
	local tScript
	put "function valueFunction pParam; return pParam; end valueFunction" into tScript

	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript

	local tValidScript

	ideExecuteScript "put valueFunction(" & quote & "hello world" & quote & ")", tStack, false, tValidScript
	TestAssert "intelligence object put function with single segment param with spaces", msg is "hello world"
end TestIntelligenceObjectPutFunctionWithParam

on TestIntelligenceObjectPropertyCompleted
	local tButton, tButtonName
	create button
	put it into tButton
	put the name of tButton into tButtonName
	
	local tValidScript
	ideExecuteScript "width", tButton, false, tValidScript
	TestAssert "intelligence object property autocomplete result", msg is the width of tButton
	TestAssert "intelligence object property autocomplete executed", tValidScript is "put the width of" && tButtonName
end TestIntelligenceObjectPropertyCompleted

-- Bug 17549
on TestIntelligenceObjectFunctionNotFirstLine
	local tScript
	put "function incr x; return x+1; end incr" into tScript
	
	local tStack
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tValidScript, tToExecute
	put "global z" into tToExecute
	put return & "put 1 into z" after tToExecute
	put return & "put incr(z)" after tToExecute
	
	ideExecuteScript tToExecute, tStack, false, tValidScript
	
	TestAssert "intelligence object command result", msg is 2
	TestAssert "intelligence object command executed", tValidScript is tToExecute
end TestIntelligenceObjectFunctionNotFirstLine

-- Bug 17800 
on TestIntelligenceObjectCommandWithTwoParams
	local tScript, tStack
	put "on testParameters p1, p2; put p2; end testParameters" \
		into tScript
	create stack
	put it into tStack
	set the script of tStack to tScript
	
	local tToExecute, tValidScript
	put "testParameters 1, 2" into tToExecute
	
	ideExecuteScript tToExecute, tStack, false, tValidScript
	
	TestAssert "intelligence object command two params result", msg is 2
	TestAssert "intelligence object command two params executed", tValidScript is tToExecute
end TestIntelligenceObjectCommandWithTwoParams

on TestReferenceControlOnActiveStack
	local tStack, tField
	create stack
	put it into tStack

	set the defaultStack to the short name of tStack
	
	create field
	put it into tField
	
	-- change the default stack
	create stack
	set the defaultStack to the short name of it
	
	local tToExecute, tValidScript
	put "put bar into field 1" into tToExecute
	ideExecuteScript tToExecute, tStack, false, tValidScript
	
	TestAssert "intelligence object command two params result", the text of tField is "bar"
	TestAssert "intelligence object command two params executed", tValidScript is tToExecute
end TestReferenceControlOnActiveStack

-- bug 20084
on TestMutilineWithCommentOnFirstLine
	local tStack, tField
	create stack
	put it into tStack

	set the defaultStack to the short name of tStack
	
	create field
	put it into tField
	
	local tToExecute, tValidScript
	put "-- foo" & return & "put bar into field 1" into tToExecute
	ideExecuteScript tToExecute, tStack, false, tValidScript
	
	TestAssert "multiline script with comment on first line executes", the text of tField is "bar"
end TestMutilineWithCommentOnFirstLine
