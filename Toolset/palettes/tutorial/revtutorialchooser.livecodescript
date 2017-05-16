script "revTutorialChooser"
on preOpenStack
   lock screen
   __clearUI
  __generateUI
  __initialiseUI
  show me
  resizeStack
  revIDESubscribe "ideTutorialProgressChanged"
  unlock screen
end preOpenStack

on __clearUI
   repeat while the number of controls of card 1 of me > 0
      delete control 1 of card 1 of me
   end repeat
end __clearUI

private on __generateUI
   lock screen
   lock messages
   create widget "courses" as "com.livecode.widget.progressList"
   create widget "tutorials" as "com.livecode.widget.progressList"
   create widget "lessons" as "com.livecode.widget.progressList"
   
   set the borders of widget "courses" to "right"
   set the showButton of widget "courses" to false
   set the showNextIcon of widget "courses" to true
   
   set the borders of widget "tutorials" to "right"
   set the showButton of widget "tutorials" to false
   set the showNextIcon of widget "tutorials" to true
   
   set the borders of widget "lessons" to empty
   set the showNextIcon of widget "lessons" to false
   unlock messages
   unlock screen
end __generateUI

local sTutorialData, sCourseID, sTutorialID, sLessonID
private on __initialiseUI
   lock screen
   set the showNextIcon of widget "courses" to true
   set the showButton of widget "courses" to false
   put 1 into sCourseID
   put 1 into sTutorialID
   __refreshUI
   unlock screen
end __initialiseUI

private on __refreshUI
   lock screen
   # Get the course data
   put revIDETutorialCourseInfo() into sTutorialData
   
   # Get the courses data and set on courses widget
   set the lineData of widget "courses" of me to __getCourseData()
   set the lineData of widget "tutorials" of me to __getTutorialData(sCourseID)
   set the lineData of widget "lessons" of me to __getLessonData(sCourseID, sTutorialID)
   
   set the lineSelected of widget "courses" of me to sCourseID
   set the lineSelected of widget "tutorials" of me to sTutorialID
   
   unlock screen
end __refreshUI

private function __getCourseData
   local tListData
   repeat with x = 1 to the number of elements of sTutorialData
      put sTutorialData[x]["name"] into tListData[x]["title"]
      put false into tListData[x]["showProgress"]
      put __getProgressString(__getProgress(sTutorialData[x]["tutorials"])) into tListData[x]["hinttext"]
      put "" into tListData[x]["subtitle"]
   end repeat
   return tListData
end __getCourseData

private function __getTutorialData pCourseID
   if pCourseID is not a number then exit __getTutorialData
   if pCourseID is not among the lines of the keys of sTutorialData then exit __getTutorialData
   
   local tListData
   repeat with x = 1 to the number of elements of sTutorialData[pCourseID]["tutorials"]
      put sTutorialData[pCourseID]["tutorials"][x]["name"] into tListData[x]["title"]
      put false into tListData[x]["showProgress"]
      put __getProgressString(__getProgress(sTutorialData[pCourseID]["tutorials"][x]["lessons"])) into tListData[x]["hinttext"]
      put "" into tListData[x]["subtitle"]
   end repeat
   return tListData
end __getTutorialData

private function __getLessonData pCourseID, pTutorialID
   if pCourseID is not a number or pTutorialID is not a number then exit __getLessonData
   
   local tListData
   repeat with x = 1 to the number of elements of sTutorialData[pCourseID]["tutorials"][pTutorialID]["lessons"]
      local tLessonObject
      put sTutorialData[pCourseID]["tutorials"][pTutorialID]["lessons"][x] into tLessonObject
      put tLessonObject["name"] into tListData[x]["title"]
      put true into tListData[x]["showProgress"]
      put "" into tListData[x]["hintText"]
      local tProgress
      put tLessonObject["progress"] into tProgress
      if tProgress is 0 then
         put "Start" into tListData[x]["buttonLabel"]
      else if tProgress is 100 then
         put "Restart" into tListData[x]["buttonLabel"]
      else
         put "Resume" into tListData[x]["buttonLabel"]
      end if
      --put __getProgressString(tProgress) && "(0/10 Steps)" into tListData[x]["subtitle"]
      put __getProgressString(tProgress) into tListData[x]["subtitle"]
      put tProgress/100 into tListData[x]["progressRatio"]
   end repeat
   return tListData
end __getLessonData

private function __getProgress pData
   if the number of elements in pData is 0 then
      return 0
   end if
   
   local tProgress, tTotalPercentage
   repeat for each element tElement in pData
      add tElement["progress"] to tProgress
   end repeat
   divide tProgress by the number of elements in pData
   
   if tProgress is 0 then return 0
   if tProgress is tTotalPercentage then return 100
   return tProgress
end __getProgress

private function __getProgressString pProgress
   if pProgress is 0 then return "not started" 
   else if pProgress >= 100 then return "completed"
   else 
      set the itemdel to "."
      if the number of items of pProgress is 1 then
         return pProgress & "%"
      else
         return (((item 1 of pProgress) + 1) & "%")
      end if
   end if
end __getProgressString

on ideTutorialProgressChanged
   __refreshUI
end ideTutorialProgressChanged

on resizeStack
   lock screen
   lock messages
   
   local tWidth, tHeight
   put the width of this stack into tWidth
   put the height of this stack into tHeight
   
   set the rect of widget "courses" of me to 0,0,tWidth * 0.25, tHeight
   set the rect of widget "tutorials" of me to tWidth * 0.25,0,tWidth * 0.5, tHeight
   set the rect of widget "lessons" of me to tWidth * 0.5,0,tWidth, tHeight
   
   unlock messages
   unlock screen
end resizeStack

on lineSelected pID
   lock screen
   local tTarget
   put the short name of the target into tTarget
   switch tTarget
      case "courses"
         put pID into sCourseID
         set the lineData of widget "tutorials" of me to __getTutorialData(sCourseID)
         set the lineData of widget "lessons" of me to __getLessonData(sCourseID, 1)
         lock messages
         set the lineSelected of widget "tutorials" of me to 1
         unlock messages
         break
      case "tutorials"
         put pID into sTutorialID
         set the lineData of widget "lessons" of me to __getLessonData(sCourseID, sTutorialID)
         break
      case "lessons"
         //set the lineData of widget "tutorials" of me to __getLessonData(pID)
         put pID into sLessonID
         break
   end switch
   unlock screen
end lineSelected

on lineActionClicked pLine, pLabel
   local tCourse, tTutorial, tLesson
   put sTutorialData[sCourseID]["name"] into tCourse
   put sTutorialData[sCourseID]["tutorials"][sTutorialID]["name"] into tTutorial
   put sTutorialData[sCourseID]["tutorials"][sTutorialID]["lessons"][pLine]["name"] into tLesson
   if pLabel is "Start" or pLabel is "Restart" then
      revIDEStartTutorial tCourse, tTutorial, tLesson
   else
      revIDETutorialLoad tCourse, tTutorial, tLesson
   end if
end lineActionClicked
