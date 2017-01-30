script "TutorialRunningTests"
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
   if the environment is "development command line" then
      return "SKIP GUI-only tests"
   end if
   TestLoadAllExtensions
end TestSetup

private on TestLesson pCourse, pTutorial, pLesson, pLocation
   dispatch "revTutorialRunTutorial" to stack "revTutorial" with pCourse, pTutorial, pLesson, pLocation
   TestAssert "run" && pCourse && "-" && pTutorial && "-" && pLesson, true
end TestLesson

private on TestTutorial pCourse, pTutorial, pLocation
   repeat for each line tLesson in revIDETutorialListLessons(pCourse, pTutorial, pLocation)
      TestLesson pCourse, pTutorial, tLesson, pLocation
   end repeat
end TestTutorial

private on TestCourse pCourse, pLocation
   repeat for each line tTutorial in revIDETutorialListTutorials(pCourse)
      TestTutorial pCourse, tTutorial, pLocation
   end repeat
end TestCourse

on TestAllTutorials pLocation
   set the itemdelimiter to slash
   local tLocation
   put item 1 to -2 of the effective filename of stack "revTutorial" into tLocation

   repeat for each line tCourse in revIDETutorialListCourses()
      TestCourse tCourse, tLocation
   end repeat
end TestAllTutorials


