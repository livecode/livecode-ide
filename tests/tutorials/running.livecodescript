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

private on TestLesson pCourse, pTutorial, pLesson
   dispatch "revTutorialRunTutorial" to stack "revTutorial" with pCourse, pTutorial, pLesson
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

