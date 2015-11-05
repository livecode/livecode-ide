script "IDEElements"
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
   set the script of stack tIDELibrary to tScript

   insert the script of stack "revIDELibrary" into back
end TestSetup

on TestIDEStacks
   local tIDEStacks
   put "revStack,com.livecode.stack,answer dialog,ask dialog,home,message box" into tIDEStacks

   repeat for each item tItem in tIDEStacks
      create stack tItem
      TestAssert tItem && "is ide stack", revIDEStackIsIDEStack(the long id of stack tItem)
      TestAssert tItem && "is ide stack name", revIDEStackNameIsIDEStack(tItem)
      TestAssert tItem && "is not in ideUserMainStacks", tItem is not in ideUserMainStacks()
   end repeat
end TestIDEStacks

on TestUserStack
   create stack "user stack"
   TestAssert "user stack is in ideUserMainStacks", "user stack" is among the lines of ideUserMainStacks()
end TestUserStack

on TestIDESubstack
   create stack "revStack"
   create stack "substack"
   set the mainstack of stack "substack" to "revStack"

   TestAssert "substacks of IDE stack are IDE stacks", revIDEObjectIsOnIDEStack(the long id of stack "substack")
end TestIDESubstack

on TestNonIDESubstack
   create stack "user stack"
   create stack "revSubstack"
   set the mainstack of stack "revSubstack" to "user stack"

   TestAssert "substacks of user stacks are not IDE stacks", not revIDEObjectIsOnIDEStack(the long id of stack "revSubstack")
end TestNonIDESubstack
