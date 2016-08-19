script "TestObjectsAreSelectable"
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

constant kStackName = "Selectable"

on TestSetup
   create stack kStackName
   set the defaultStack to kStackName
   create button "test"
   group button "test"
   create card
   go card 1 of stack kStackName
end TestSetup

on TestObjectsAreSelectable
   TestAssert "Objects on open stack are selectable", revIDEObjectsAreSelectable(the long id of group 1 of stack kStackName)

   set the selectGroupedControls to false
   TestAssert "Grouped objects when global selectGroupedControls is false are not selectable", not revIDEObjectsAreSelectable(the long id of button 1 of stack kStackName)

   set the selectGroupedControls to true
   set the selectGroupedControls of group 1 of stack kStackName to false
   TestAssert "Grouped objects when object selectGroupedControls is false are not selectable", not revIDEObjectsAreSelectable(the long id of button 1 of stack kStackName)

   set the selectGroupedControls of group 1 of stack kStackName to true
   TestAssert "Grouped objects when object selectGroupedControls is true are selectable", revIDEObjectsAreSelectable(the long id of button 1 of stack kStackName)

   go card 2 of stack kStackName
   TestAssert "Controls on a closed card are not selectable", not revIDEObjectsAreSelectable(the long id of button 1 of card 1 of stack kStackName)

   go card 1 of stack kStackName
   close stack kStackName
   TestAssert "Controls on a closed stack are not selectable", not revIDEObjectsAreSelectable(the long id of button 1 of card 1 of stack kStackName)
end TestObjectsAreSelectable

on TestTeardown
   delete stack kStackName
end TestTeardown
