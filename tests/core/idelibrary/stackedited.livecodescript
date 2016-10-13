script "TestStackEdited"
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

on __TestEdited pStackName
   return revIDEStackIsEdited(pStackName)
end __TestEdited

on TestStackNewControlEdited
   local tStackName, tStackID
   create stack
   put it into tStackID
   put the short name of tStackID into tStackName
   set the defaultStack to tStackName
   
   revIDECreateObject "com.livecode.interface.classic.Button", tStackID, "0,0"
   
   TestAssert "Stack with new control is marked edited", revIDEStackIsEdited(tStackName)
end TestStackNewControlEdited

on TestStackPropertyChangedEdited
   local tStackName, tStackID
   create stack
   put it into tStackID
   put the short name of tStackID into tStackName
   revIDEPropertySet tStackID, "formatForPrinting", not the formatForPrinting of tStackID
   
   TestAssert "Stack with property change is marked edited", revIDEStackIsEdited(tStackName)
end TestStackPropertyChangedEdited

on TestStackControlPropertyChangedEdited
   local tStackName
   create stack
   put the short name of it into tStackName
   set the defaultStack to tStackName
   
   local tButtonID
   create button
   put it into tButtonID
   
   revIDESetUnedited(tStackName)
   
   revIDEPropertySet tButtonID, "visible", false
   
   TestAssert "Stack with control property change is marked edited", revIDEStackIsEdited(tStackName)
end TestStackControlPropertyChangedEdited

on TestStackNameChangedEdited
   local tStackName
   create stack
   revIDEPropertySet it, "name", "TestStackNewName"
   
   TestAssert "Stack with name change is marked edited", revIDEStackIsEdited("TestStackNewName")
end TestStackNameChangedEdited

on TestStackOpenFieldEdited   
   local tStackName
   create stack
   put the short name of it into tStackName
   set the defaultStack to tStackName
      
   local tFieldID
   create field
   put it into tFieldID
   revIDESetUnedited tStackName
   
   dispatch "openField" to tFieldID
    
   TestAssert "Stack with opened field is marked edited", revIDEStackIsEdited(tStackName)
end TestStackOpenFieldEdited

on TestStackSavedNotEdited
   local tDir
   set the itemdelimiter to slash
   set the defaultfolder to item 1 to -2 of the filename of me

   put "_TestStackEdited" into tDir
   
   create folder tDir
   
   local tStackName, tStackID
   create stack
   put it into tStackID
   put the short name of tStackID into tStackName
      
   revIDESetEdited tStackName
   
   set the filename of tStackID to the folder & "/" & tDir & "/stack.livecode"

   revIDESaveStack tStackID
   
   TestAssert "Saved stack is marked unedited", not revIDEStackIsEdited(tStackName)
   
   revDeleteFolder tDir
end TestStackSavedNotEdited
