script "TestProjectBrowser"
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
   if the environment is "development command line" then
      return "SKIP GUI-only tests"
   end if

   revIDEOpenPalette "project browser"
   
   set the itemdelimiter to slash
   local tSupportStack
   put the filename of me into tSupportStack
   put "_support.livecodescript" into item -1 of tSupportStack
   put tSupportStack into sSupportStack
   start using stack sSupportStack
end TestSetup

on TestTeardown
   stop using stack sSupportStack
end TestTeardown

on TestNewStack
	local tParams
	create stack "NewStack"
 	put it into tParams[1]
	
	TestRepeat "new stack is added to project browser data", \ 
		"ThereIsAnObjectData", the long id of me, 500, tParams
		
	ClickRowDisclosure it	
	ThereIsAnObject the long id of card 1 of it
	TestAssert "clicking stack disclosure reveals card", the result
	
	ClickRowDisclosure it	
	ThereIsAnObject the long id of card 1 of it
	TestAssert "clicking stack disclosure again hides card", the result is false
end TestNewStack

on TestNewStackIsVisible
	local tParams
	create stack "NewStack"
 	put it into tParams[1]
	
	TestRepeat "new stack is visible in project browser", \ 
		"ThereIsAnObject", the long id of me, 500, tParams
end TestNewStackIsVisible

on TestIDEStackProps
	repeat for each line tStack in the openStacks
	   ObjectDataMatches the long id of stack tStack
	   TestAssert "project browser data correct" && tStack, the result
	end repeat
end TestIDEStackProps