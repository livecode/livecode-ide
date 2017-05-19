script "revStartCenterBehavior"
constant kAllSocialMedia = "facebook,twitter,github,linkedin,youtube,stackoverflow"
constant kSocialMedia = "github,stackoverflow,youtube,facebook,twitter,linkedin"

on openStack
   ## Set up the Start Center UI   
   
   ## Logo
   logoInitialise
   
   ## Social Media
   socialMediaInitialise
   socialMediaSet
   
   ## Recent Files
   recentFilesInitialise
   recentFilesSet
   set the dgHilitedLine of group "recentFiles"  of card "interface" of me to 1
   
   ## Tiles
   tilesInitialise
   
   ## First Run Controls
   set the backgroundColor of button "startTour"  of card "interface" of me to uiColor("edition")
   set the filename of image "firstRunImage" of group "firstRun"  of card "interface" of me to resourcesPath("images/firstRunImage.PNG")
   set the itemdelimiter to "."
   get item 1 to 2 of the version
   put merge("Welcome to LiveCode [[it]]!") into field "firstRunTitle"  of card "interface" of me
   
   ## Set folder icon
   set the foregroundColor of widget "openIcon"  of card "interface" of me to uiColor("dark grey")
   set the iconPresetName of widget "openIcon"  of card "interface" of me to "folder open alt"
   
   ## Tutorial Chooser
   tutorialChooserInitialise
   
   ## Show the banner
   --bannerInitialise
   
   ## Show at startup preference
   set the foregroundColor of widget "startupCheckbox"  of card "interface" of me to uiColor("dark grey")
   if revIDEGetPreference("cStartPageShow") is true then
      set the iconPresetName of widget "startupCheckbox"  of card "interface" of me to "lc-checkbox-checked"
   else
      set the iconPresetName of widget "startupCheckbox"  of card "interface" of me to "lc-checkbox-unchecked"
   end if
   
   ## First run
   if revIDEGetPreference("StartCenterClassic") is true then
      ## Not first run
      hide group "firstRun" of card "interface" of me
      show group"topPanel" of card "interface" of me
      --show group "tiles"
      set the top of group "recentFiles"  of card "interface" of me to 0
   else
      ## First run
      hide group "banner" of card "interface" of me
      hide group "topPanel" of card "interface" of me
      --hide group "tiles"
      
      set the top of group "recentFiles"  of card "interface" of me to 0
      
      set the layer of group "firstRun" of card "interface" of me  to top
      show group "firstRun" of card "interface" of me
   end if
   
   go to card "interface"
end openStack

on preOpenCard
   tutorialChooserInitialise
end preOpenCard

on desktopChanged
   set the loc of me to revIDEStackScreenLoc(the short name of me)
end desktopChanged

on ideNewStack
   startCenterClose
end ideNewStack

on ideOpenStack pTarget
   if not exists(pTarget) then
      exit ideOpenStack
   end if
   
   if the short name of ideStackOfObject(pTarget) is not the short name of me then
      startCenterClose
   end if
end ideOpenStack

command startCenterClose
   close me
end startCenterClose

command logoInitialise
   ## Set the logo to the correct logo for the version
   set the iconPresetName of widget "logo" of card "interface" of me to "lc-logo"
   set the foregroundColor of widget "logo" of card "interface" of me to uiColor("logo")
   
   ## Set the title to contain the correct version string
   local tMajorVersion
   set the itemDelimiter to "."
   put item 1 to 2 of the version into tMajorVersion
   put merge("Welcome to LiveCode [[tMajorVersion]]") into field "title" of card "interface" of me
end logoInitialise

command socialMediaInitialise   
   ## Set the images
   local tWidget
   repeat for each item tMedia in kAllSocialMedia
      put the long id of widget tMedia of group "socialMedia" of card "interface" of me into tWidget
      hide tWidget
      set the iconPresetName of tWidget to ("lc-" & tMedia)
      set the foregroundColor of tWidget to uiColor(tMedia)
      set the fillrule of tWidget to "even odd"
      set the blendLevel of tWidget to 50
      set the behavior of tWidget to the long id of button "socialBehavior" of card "interface" of me
   end repeat
end socialMediaInitialise

command socialMediaSet
   local tCenterLoc, tMediaCount, tPadding, tWidth, tTotalWidth, tLeft
   
   ## Show the chosen social media
   put item 1 of the loc of group "socialMedia" of card "interface" into tCenterLoc
   put the number of items in kSocialMedia into tMediaCount
   put 20 into tPadding
   put 20 into tWidth
   
   put (tWidth * tMediaCount) + (tMediaCount - 1) * tPadding into tTotalWidth
   put tCenterLoc - round(tTotalWidth / 2) into tLeft
   
   repeat with x = 1 to tMediaCount
      show widget (item x of kSocialMedia) of card "interface" of me
      set the left of widget (item x of kSocialMedia) of card "interface" of me to tLeft
      add tWidth + tPadding to tLeft
   end repeat
end socialMediaSet

command socialMediaHilite pName, pValue
   if pValue is true then
      set the blendLevel of widget pName of group "socialMedia" of card "interface" of me to 0
   else
      set the blendLevel of widget pName of group "socialMedia" of card "interface" of me to 50
   end if
end socialMediaHilite

command socialMediaUnhiliteAll
   repeat with x = 1 to the number of widgets of group "socialMedia" of card "interface" of me
      set the blendLevel of widget x of group "socialMedia" of card "interface" of me to 50
   end repeat
end socialMediaUnhiliteAll

command recentFilesInitialise
   set the dgProps["hilite color"] of group "recentFiles" of card "interface" of me to uiColor("edition")
   set the linkColor to uiColor("edition")
   set the underlineLinks to false
end recentFilesInitialise

command recentFilesSet
   local tRecentStacks
   put revIDERecentStacks() into tRecentStacks
   set the dgData of group "recentFiles" of card "interface" of me to tRecentStacks
end recentFilesSet

command recentFileOpen
   local tLine, tFileData
   put the dgHilitedLine of group "recentFiles" of card "interface" of me into tLine
   put the dgDataOfLine[tLine] of group "recentFiles" of card "interface" of me into tFileData
   revIDEOpenStack tFileData["filename"]
end recentFileOpen

command tilesInitialise
   local tArray, tSourceColor, tEdition, tColorStep, tTileNumber
   
   ## Set the colors of the tiles
   put uiColor("edition") into tSourceColor
   put revLicenseType() into tEdition
   
   ## The Start Color depends on the edition
   if tEdition is "commercial" or tEdition is "professional" then
      put 0 into tColorStep
   else
      put -9 into tColorStep
   end if
   
   repeat with tTileNumber = 1 to 8
      add 1 to tColorStep      
      set the bgColor of widget ("tile" & tTileNumber) of card "interface" of me to tileColor(tSourceColor,tColorStep)
      set the bgHoverColor of widget ("tile" & tTileNumber) of card "interface" of me to uiColor("tileBGHover")
      
      set the fgColor of widget ("tile" & tTileNumber) of card "interface" of me to uiColor("tileFG")
      set the fgHoverColor of widget ("tile" & tTileNumber) of card "interface" of me to uiColor("tileFGHover")
      
      set the hoverState of widget ("tile" & tTileNumber) of card "interface" of me to false
      set the behavior of widget ("tile" & tTileNumber) of card "interface" of me to the long id of button "tileBehavior" of card "interface" of me
   end repeat
   
   ## Breadcrumb
   put empty into field "breadcrumb" of card "interface" of me
   set the textStyle of word 1 of field "breadcrumb" of card "interface" of me to empty
   
   put tilesArray("home") into tArray
   repeat with x = 1 to 8
      show widget ("tile" & x) of card "interface" of me
   end repeat
   tilesSet tArray
end tilesInitialise

command tilesSet pArray
   local tArray
   put pArray into tArray
   
   repeat with x = 1 to 8
      if tArray[x]["tag"] is not empty then
         set the tileLabel of widget ("tile" & x) of card "interface" of me to tArray[x]["label"]
         set the iconName of widget ("tile" & x) of card "interface" of me to tArray[x]["icon"]
         set the hoverIconName of widget ("tile" & x) of card "interface" of me to tArray[x]["hoverIcon"]
         set the cTag of widget ("tile" & x) of card "interface" of me to tArray[x]["tag"]
         set the hoverState of widget ("tile" & x) of card "interface" of me to false
      else
         set the tileLabel of widget ("tile" & x) of card "interface" of me to empty
         set the tileIcon of widget ("tile" & x) of card "interface" of me to empty
         set the cTag of widget ("tile" & x) of card "interface" of me to empty
      end if
   end repeat
end tilesSet

function resourcesPath pFileName
   return revIDEPaletteResourcePath(pFileName)
end resourcesPath

function tilesArray pState
   local tArray
   
   switch pState
      case "home"
         put "Interactive Welcome" into tArray[1]["label"]
         put "interactive_welcome" into tArray[1]["tag"]
         put "lc-location" into tArray[1]["icon"]
         put "lc-location-filled" into tArray[1]["hoverIcon"]
         put "New" into tArray[2]["label"]
         put "new" into tArray[2]["tag"]
         put "lc-add" into tArray[2]["icon"]
         put "lc-add-filled" into tArray[2]["hoverIcon"]
         put "Sample Projects" into tArray[3]["label"]
         put "samples" into tArray[3]["tag"]   
         put "lc-window" into tArray[3]["icon"]
         put "lc-window-filled" into tArray[3]["hoverIcon"]
         put "Tutorials" into tArray[4]["label"]
         put "tutorials" into tArray[4]["tag"]
         put "lc-book" into tArray[4]["icon"]
         put "lc-book-filled" into tArray[4]["hoverIcon"]
         put "In Depth Guides" into tArray[5]["label"]
         put "guides" into tArray[5]["tag"]
         put "lc-learner" into tArray[5]["icon"]
         put "lc-learner-filled" into tArray[5]["hoverIcon"]
         put "Forums" into tArray[6]["label"]
         put "forum" into tArray[6]["tag"]
         put "lc-talk" into tArray[6]["icon"]
         put "lc-talk-filled" into tArray[6]["hoverIcon"]
         put "Blog" into tArray[7]["label"]
         put "blog" into tArray[7]["tag"]
         put "lc-microphone" into tArray[7]["icon"]
         put "lc-microphone-filled" into tArray[7]["hoverIcon"]
         put "Account" into tArray[8]["label"]
         put "account" into tArray[8]["tag"]
         put "lc-person" into tArray[8]["icon"]
         put "lc-person-filled" into tArray[8]["hoverIcon"]
         break
      case "new"
         put "New Stack" into tArray[1]["label"]
         put "newStackDefault" into tArray[1]["tag"]
         put "lc-window" into tArray[1]["icon"]
         put "lc-window-filled" into tArray[1]["hoverIcon"]
         
         put "Script Only Stack" into tArray[2]["label"]
         put "newScriptOnlyStack" into tArray[2]["tag"]
         put "lc-filetype-lcs" into tArray[2]["icon"]
         put "lc-filetype-lcs-filled" into tArray[2]["hoverIcon"]
         
         put "Tablet Portrait" into tArray[3]["label"]
         put "newTabletPortrait" into tArray[3]["tag"]
         put "lc-ipad-portrait" into tArray[3]["icon"]
         put "lc-ipad-portrait-filled" into tArray[3]["hoverIcon"]
         
         put "Tablet Landscape" into tArray[4]["label"]
         put "newTabletPortrait" into tArray[4]["tag"]
         put "lc-ipad-landscape" into tArray[4]["icon"]
         put "lc-ipad-landscape-filled" into tArray[4]["hoverIcon"]
         
         put "iPhone 6" into tArray[5]["label"]
         put "newIphone6" into tArray[5]["tag"]
         put "lc-iphone" into tArray[5]["icon"]
         put "lc-iphone-filled" into tArray[5]["hoverIcon"]
         
         put "iPhone 5" into tArray[6]["label"]
         put "newIphone5" into tArray[6]["tag"]
         put "lc-iphone" into tArray[6]["icon"]
         put "lc-iphone-filled" into tArray[6]["hoverIcon"]
         
         put "iPhone 4" into tArray[7]["label"]
         put "newIphone4" into tArray[7]["tag"]
         put "lc-iphone" into tArray[7]["icon"]
         put "lc-iphone-filled" into tArray[7]["hoverIcon"]
         
         break
   end switch
   return tArray
end tilesArray

command startCenterSetState pStateID, pArray
   switch pStateID
      case 1
         hide widget "tile8" of card "interface" of me
         break
      case 2
         hide widget "tile7" of card "interface" of me
         break
      case 3
         hide widget "tile6" of card "interface" of me
         break
      case 4
         hide widget "tile5" of card "interface" of me
         break
      case 5
         hide widget "tile4" of card "interface" of me
         break
      case 6
         hide widget "tile3" of card "interface" of me
         break
      case 7
         hide widget "tile2" of card "interface" of me
         break
      case 8
         hide widget "tile1" of card "interface" of me
         break
      case 9
         tilesSet pArray
         break
      case 10
         if 1 is among the keys of pArray then
            show widget "tile1" of card "interface" of me
         end if
         break
      case 11
         if 2 is among the keys of pArray then
            show widget "tile2" of card "interface" of me
         end if
         break
      case 12
         if 3 is among the keys of pArray then
            show widget "tile3" of card "interface" of me
         end if
         break
      case 13
         if 4 is among the keys of pArray then
            show widget "tile4" of card "interface" of me
         end if
         break
      case 14
         if 5 is among the keys of pArray then
            show widget "tile5" of card "interface" of me
         end if
         break
      case 15
         if 6 is among the keys of pArray then
            show widget "tile6" of card "interface" of me
         end if
         break
      case 16
         if 7 is among the keys of pArray then
            show widget "tile7" of card "interface" of me
         end if
         break
      case 17
         if 8 is among the keys of pArray then
            show widget "tile8" of card "interface" of me
         end if
         break
   end switch
   if pStateID < 17 then
      send "startCenterSetState pStateID+1, pArray" to me in 25 milliseconds
   end if
end startCenterSetState

command tilesUpdate pArray
   send "startCenterSetState 1, pArray" to me in 0 milliseconds
end tilesUpdate

on startCenterAction pAction
   local tStackName, tArray
   switch pAction
      case "interactive_welcome" 
         --tourStart
         goToTutorialChoose
         break
      case "interactive_tutorial_select"
         local tCourse, tTutorial, tLesson
         put the selectedText of field "course" of card "tutorialChooser" into tCourse
         put the selectedText of field "tutorial" of card "tutorialChooser" into tTutorial
         put the selectedText of field "lesson" of card "tutorialChooser" into tLesson
         
         revIDEStartTutorial tCourse, tTutorial, tLesson
         revIDESetPreference "StartCenterClassic", "true"
         startCenterClose
         break
      case "new"
         put "Home / New" into field "breadcrumb"
         set the textStyle of word 1 of field "breadcrumb" to "link"
         put tilesArray(pAction) into tArray
         tilesUpdate tArray
         break
      case "samples"
         revIDELaunchResource "sample stacks"
         break
      case "guides"
         revIDEDocumentationLoad "API", "LiveCode Script"
         break
      case "tutorials"
         launch url "http://livecode.com/links/livecode/tutorials"
         break
      case "forum"
         launch url "http://livecode.com/links/livecode/forum"
         break
      case "dictionary"
         revIDEDocumentationLoad "API", "Guide"
         break
      case "blog"
         launch url "http://livecode.com/links/livecode/blog"
         break
      case "upgrade"
         --launch url "https://livecode.com/about/contact/"
         break
      case "account"
         launch url "http://livecode.com/links/livecode/account"
         break
      case "contact"
         --launch url "https://livecode.com/about/contact/"
         break
      case "website"
         launch url "http://livecode.com"
         break
      case "facebook"
         launch url "http://livecode.com/links/livecode/facebook"
         break
      case "twitter"
         launch url "http://livecode.com/links/livecode/twitter"
         break
      case "github"
         launch url "http://livecode.com/links/livecode/github"
         break
      case "linkedin"
         launch url "http://livecode.com/links/livecode/linkedin"
         break
      case "youtube"
         launch url "http://livecode.com/links/livecode/youtube"
         break
      case "stackoverflow"
         launch url "http://livecode.com/links/livecode/stackoverflow"
         break
      case "newStackDefault"
         revIDEActionNewMainstack "default"
         break
      case "newScriptOnlyStack"
         revIDEActionNewScriptOnlyStack
         break
      case "newTabletPortrait"
         revIDEActionNewMainstack "iPad/Tablet Portrait (768x1024)"
         break
      case "newTabletLandscape"
         revIDEActionNewMainstack "iPad/Tablet Lanscape (1024x768)"
         break
      case "newIphone6"
         revIDEActionNewMainstack "iPhone 6 (375x667)"
         break
      case "newIphone5"
         revIDEActionNewMainstack "iPhone 5 (320x568)"
         break
      case "newIphone4"
         revIDEActionNewMainstack "iPhone 4 (320x480)"
         break
   end switch
end startCenterAction

command setStateHome
   local tArray
   put tilesArray("home") into tArray
   
   put empty into field "breadcrumb" of card "interface" of me
   set the textStyle of word 1 of field "breadcrumb" of card "interface" of me to empty
   
   tilesUpdate tArray
end setStateHome

command firstRunVisible pValue
   lock screen
   
   if pValue is true then
      show group "firstRun" of card "interface" of me
      hide group"topPanel" of card "interface" of me
      --hide group "tiles"
   else if pValue is false then
      hide group "firstRun" of card "interface" of me
      show group"topPanel" of card "interface" of me
      repeat with x = 1 to 8
         set the hoverState of widget ("tile" & x)  of card "interface" of me to false
      end repeat
      --show group "tiles"
      
      revIDESetPreference "StartCenterClassic", "true"
   end if
   
   unlock screen
end firstRunVisible

command tourStart
   lock screen
   revIDEStartTutorial "First Run", "To Do List", "App Lesson"
   revIDESetPreference "StartCenterClassic", "true"
   startCenterClose
   unlock screen
end tourStart

## Banner 
command bannerInitialise
   set the top of group "recentFiles"  of card "interface" of me to 0 
   hide group "banner"
   --load url "http://elanorb.on-rev.com/startcenter/banner2.txt" with message "bannerComplete"
end bannerInitialise

## Tutorial Choose
command tutorialChooserInitialise
   local tCourses, tTutorials, tLessons
   
   set the dgProps["hilite color"] of group "course" of card "tutorialChooser" to uiColor("edition")
   set the dgProps["hilite color"] of group "tutorial" of card "tutorialChooser" to uiColor("edition")
   set the dgProps["hilite color"] of group "lesson" of card "tutorialChooser" to uiColor("edition")
   
   put  getTutorialArray("course") into tCourses
   
   set the dgData of group "course" of card "tutorialChooser" to tCourses
   set the height of group "course" of card "tutorialChooser" to the dgFormattedheight of group "course" of card "tutorialChooser"
   set the topLeft of group "course" of card "tutorialChooser" to 0,48
   
   set the dgHilitedLine of group "course" of card "tutorialChooser" to 1
   tutorialSelectCourse      
end tutorialChooserInitialise

command tutorialSelectCourse 
   local tTutorials
   
   lock screen
   put getTutorialArray("tutorial",selectedCourse()) into tTutorials
   
   set the dgData of group "tutorial" of card "tutorialChooser" to tTutorials
   set the height of group "tutorial" of card "tutorialChooser" to the dgFormattedheight of group "tutorial" of card "tutorialChooser"
   set the top of group "tutorial" of card "tutorialChooser" to 48
   
   set the dgHilitedLine of group "tutorial" of card "tutorialChooser" to 1   
   tutorialSelectTutorial
   
   unlock screen
end tutorialSelectCourse

command tutorialSelectTutorial
   local tLessons
   
   lock screen   
   put getTutorialArray("lesson",selectedCourse(),selectedTutorial()) into tLessons
   set the dgData of group "lesson" of card "tutorialChooser" to tLessons
   set the height of group "lesson" of card "tutorialChooser" to the dgFormattedheight of group "lesson" of card "tutorialChooser"
   set the top of group "lesson" of card "tutorialChooser" to 48
   set the dgHilitedLine of group "lesson" of card "tutorialChooser" to 1  
   unlock screen
end tutorialSelectTutorial

command tutorialSelectLesson   
   if the short name of the target is "start" then      
      lock screen
      revIDEStartTutorial selectedCourse(),selectedTutorial(),selectedLesson()
      revIDESetPreference "StartCenterClassic", "true"
      startCenterClose
   end if
end tutorialSelectLesson

function getTutorialArray pType, pCourse, pTutorial
   local tList, tArray, tProgress, tProgressPercent
   local tCourseName, tTutorialName, tLessonName
   
   put revIDETutorialListCourses() into tList
   repeat for each line tCourseName in tList
      put revIDETutorialSavedCourseProgress(tCourseName) into tProgress
      repeat for each line tTutorialName in the keys of tProgress
         repeat for each line tLessonName in the keys of tProgress[tTutorialName]
            put tProgress[tTutorialName][tLessonName]["progress"] into tProgressPercent[tCourseName][tTutorialName][tLessonName]["progress"]
            add tProgress[tTutorialName][tLessonName]["progress"] to tProgressPercent[tCourseName][tTutorialName]["progress"]
            add tProgress[tTutorialName][tLessonName]["progress"] to tProgressPercent[tCourseName]["progress"]
         end repeat
      end repeat
   end repeat
   
   if pType is "course" then
      put revIDETutorialListCourses() into tList
      repeat with x = 1 to the number of lines in tList
         put line x of tList into tCourseName
         put tCourseName into tArray[x]["name"]
         put round(tProgressPercent[tCourseName]["progress"]) into tArray[x]["progress"]
      end repeat
   else if pType is "tutorial" then
      put revIDETutorialListTutorials(pCourse) into tList
      repeat with x = 1 to the number of lines in tList
         put line x of tList into tArray[x]["name"]
         put round(tProgressPercent[pCourse][line x of tList]["progress"]) into tArray[x]["progress"]
      end repeat
   else if pType is "lesson" then
      put revIDETutorialListLessons(pCourse,pTutorial,revIDESpecialFolderPath("tutorial")) into tList
      repeat with x = 1 to the number of lines in tList
         put line x of tList into tArray[x]["name"]
         put round(tProgressPercent[pCourse][pTutorial][line x of tList]["progress"]) into tArray[x]["progress"]
      end repeat
   end if
   
   return tArray
end getTutorialArray

function selectedCourse
   local tSelectedLine, tData
   
   put the dgHilitedLine of group "course" of card "tutorialChooser" into tSelectedLine
   put the dgDataOfLine[tSelectedLine] of group "course" of card "tutorialChooser" into tData
   return tData["name"]
end selectedCourse

function selectedTutorial
   local tSelectedLine, tData
   
   put the dgHilitedLine of group "tutorial" of card "tutorialChooser" into tSelectedLine
   put the dgDataOfLine[tSelectedLine] of group "tutorial" of card "tutorialChooser" into tData
   return tData["name"]
end selectedTutorial

function selectedLesson
   local tSelectedLine, tData
   
   put the dgHilitedLine of group "lesson" of card "tutorialChooser" into tSelectedLine
   put the dgDataOfLine[tSelectedLine] of group "lesson" of card "tutorialChooser" into tData
   return tData["name"]
end selectedLesson

## Social Media 


command startupPreferenceSet
   if the iconPresetName of widget "startupCheckbox" is "lc-checkbox-unchecked" then
      set the iconPresetName of widget "startupCheckbox" to "lc-checkbox-checked"
      revIDESetPreference "cStartPageShow", true
   else
      set the iconPresetName of widget "startupCheckbox" to "lc-checkbox-unchecked"
      revIDESetPreference "cStartPageShow", false
   end if
end startupPreferenceSet

function uiColor pColor
   local tEdition
   put revLicenseType() into tEdition
   
   switch pColor
      case "edition"
         return revIDEColor("edition_color")
         --return 82,82,82
         break
      case "dark grey"
         return 128,128,128
         break
      case "mid grey"
         return "150,150,150"
         break
      case "logo"
         return revIDEColor("edition_color")
         break
      case "facebook"
         return "58,88,155"
         break
      case "twitter"
         return "0,122,185"
         break
      case "linkedin"
         return "0,122,185"
         break
      case "youtube"
         return "207,52,39"sa
         break
      case "stackoverflow"
         return "206,111,45"
         break
      case "github"
         return "0,0,0"
         break
      case "folder"
         return "128,128,128"
         break
      case "recentFilesBackground"
         return "247,247,247"
         break
      case "recentFilesHover"
         return "222,222,222"
         break
      case "tileBGHover"
         return "255,255,255"
         break
      case "tileFG"
         return "255,255,255"
         break
      case "tileFGHover"
         --return "128,128,128"
         if tEdition is "commercial" or tEdition is "professional" then
            return revIDEColor("edition_color")
         else
            return tileColor(revIDEColor("edition_color"), -8)
         end if
         break
   end switch   
end uiColor

function tileColor pSourceColor, pTileNumber
   local tRed, tGreen, tBlue, tColor
   
   put item 1 of pSourceColor into tRed
   put item 2 of pSourceColor into tGreen
   put item 3 of pSourceColor into tBlue
   
   put tRed + (pTileNumber*5), tGreen+(pTileNumber*5), tBlue+(pTileNumber*5) into tColor
   return tColor
end tileColor

function textProperty pType, pStyle
   switch pType
      case "title"
         if pStyle is "font" then
            
         else if pStyle is "size" then 
            
         end if
         break
      case "tile"
         if pStyle is "font" then
            
         else if pStyle is "size" then 
            
         end if
         break
      case "stackLabel"
             if pStyle is "font" then
            
         else if pStyle is "size" then 
            
         end if
         break
      case "stackPath"
         
         break
      case "option"
         
         break
   end switch
   
end textProperty

## Navigation
command goToMenu
   visual effect "push right" very fast
   go to card "interface"
end goToMenu

command goToTutorialChoose
   visual effect "push left" very fast
   go to card "tutorialChooser"
end goToTutorialChoose
