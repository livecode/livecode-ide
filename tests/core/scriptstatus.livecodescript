script "TestIDEScriptStatus"
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

local sTestStack

on TestSetup
   create stack uuid()
   put it into sTestStack
end TestSetup

on TestExplicitVariables
   local tStackFiles
   put the stackFiles of stack "home" into tStackFiles
   split tStackFiles by comma and return
   repeat for each element tStackName in tStackFiles
      if there is a stack tStackName then
         __RecursiveTest the long id of stack tStackName
      end if
   end repeat
end TestExplicitVariables

private command __RecursiveTest pObject
   if the script of pObject is not empty then
      lock messages
      local tStatus
      put the scriptStatus of pObject into tStatus
      switch tStatus
         case "uncompiled"
            set the script of sTestStack to the script of pObject
            if the scriptStatus of sTestStack is "compiled" then
               put "compiled" into tStatus
               break
            end if
         case "error"
            TestAssert "compiles" && the long name of pObject, false
            break
      end switch
      
      if tStatus is "compiled" then
         set the explicitVariables to true
         set the script of sTestStack to the script of pObject
         set the explicitVariables to false
         if the scriptStatus of sTestStack is not "compiled" then
            TestAssertBroken "explicit variables" && the long name of pObject, false, "Bug 20356"
         else
            TestAssert "explicit variables" && the long name of pObject, true
         end if
      end if
      unlock messages
   end if
   switch word 1 of pObject
      case "stack"
         repeat for each line tStack in the substacks of pObject
            __RecursiveTest the long id of stack tStack
         end repeat
         repeat for each line tID in the cardIDs of pObject
            __RecursiveTest the long id of card id tID of pObject
         end repeat
         repeat for each line tID in the sharedGroupIDs of pObject
            __RecursiveTest the long id of control id tID of pObject
         end repeat
         break
      case "card"
         repeat for each line tID in the childControlIDs of pObject
            if word 1 of the name of control id tID of pObject is "group" and \
                  the sharedBehavior of control id tID of pObject then
               next repeat
            end if
            __RecursiveTest the long id of control id tID of pObject
         end repeat
         break
      case "group"
      case "background"
      case "bkgnd"
         repeat for each line tID in the childControlIDs of pObject
            __RecursiveTest the long id of control id tID of pObject
         end repeat
         break
      default
   end switch
end __RecursiveTest

on TestTeardown
   delete stack sTestStack
end TestTeardown
