script "TutorialTesting"
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

private function SanitiseForTests pScript
   replace "_internal" with "--_internal" in pScript
   replace "the revObjectListeners" with "empty" in pScript
   replace "the effective revAvailableHandlers of pObject" with "empty" in pScript
   return pScript
end SanitiseForTests

on TestSetup
   local tIDELibrary, tScript
   put TestGetIDERepositoryPath() & "/Toolset/libraries/revidelibrary.8.livecodescript" into tIDELibrary
   
   -- Work around the fact that the property listener is not available in standalone mode
   put the script of stack tIDELibrary into tScript
   put SanitiseForTests(tScript) into tScript
   
   -- Fix revIDESpecialFolderPath
   local tReplace, tReplacement
   put "the filename of stack" && quote & "home" & quote into tReplace
   put quote & TestGetIDERepositoryPath() & "/Toolset/home.livecodescript" & quote into tReplacement
   replace tReplace with tReplacement in tScript
   
   put "stack" && quote & "revpreferences" & quote into tReplace
   put "me" into tReplacement
   replace tReplace with tReplacement in tScript
   
   set the script of stack tIDELibrary to tScript

   insert the script of stack tIDELibrary into back
   
   local tTutorial
   put TestGetIDERepositoryPath() & "/Toolset/palettes/tutorial/revtutorial.livecodescript" into tTutorial
   put the script of stack tTutorial into tScript
   put SanitiseForTests(tScript) into tScript
   set the script of stack tTutorial to tScript
   insert the script of stack tTutorial into back
   
   TestLoadAllExtensions
	
end TestSetup

private on TestLesson pCourse, pTutorial, pLesson
	revTutorialLoadData pCourse, pTutorial, pLesson
	TestAssert "load" && pCourse && "-" && pTutorial && "-" && pLesson, true
	
	revTutorialRunTutorial pCourse, pTutorial, pLesson
	TestAssert "run" && pCourse && "-" && pTutorial && "-" && pLesson, true
end TestLesson

private on TestTutorial pCourse, pTutorial
   repeat for each line tLesson in revIDETutorialListLessons(pCourse, pTutorial)
      TestLesson pCourse, pTutorial, tLesson
   end repeat
end TestTutorial

private on TestCourse pCourse
   repeat for each line tTutorial in revIDETutorialListTutorials(pCourse)
      TestTutorial pCourse, tTutorial
   end repeat
end TestCourse

on TestAllTutorials
   repeat for each line tCourse in revIDETutorialListCourses()
      TestCourse tCourse
   end repeat
end TestAllTutorials

