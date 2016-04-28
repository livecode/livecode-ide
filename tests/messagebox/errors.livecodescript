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
   // An error is thrown when running this test due to bug 17465
   /*
   revIDELaunchResource("sample stacks")
   MessageBoxIsEmpty
   
   TestAssert "message box is empty after opening revOnline stack", the result
   */
end TestBug17380