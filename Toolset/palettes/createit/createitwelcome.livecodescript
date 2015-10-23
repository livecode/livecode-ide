script "createitwelcome"
local sAppCount, sSelectedAppNumber, sHoverAppNumber
constant WINDOW_MARGIN = 40
constant CONTENT_PADDING = 20

on preOpenStack
   put 1 into sSelectedAppNumber
   stackGenerate
end preOpenStack

on openStack
   set the decorations of me to empty
   show me
end openStack

on stackGenerate
   lock screen
   lock messages
   
   repeat while the number of controls of card 1 of me > 0
      delete control 1 of card 1 of me
   end repeat
   
   # Stack properties
   set the backgroundcolor of card 1 of me to "59,165,196"
   
   # Stack width determined by screen size. If the user is on a smaller screen trim a 150 pixels off the width
   # When the stack is wider than 800 it looks/feels a little sparce. When under 650, it gets tall and therefor
   # Might not fit that well on small notebooks whose vertical res could be 768.
   local tStackWidth
   put ((item 3 of line 1 of the screenrect - item 1 of line 1 of the screenrect) / 2) into tStackWidth
   put 600 into tStackWidth
   if tStackWidth > 950 then put 950 into tStackWidth
   else if tStackWidth < 850 then put 850 into tStackWidth
   set the width of this stack to tStackWidth
   
   # Create the images for the close button
   set the filename of the templateimage to "images/close.png"
   set the visible of the templateimage to false
   create image "close"
   
   set the filename of the templateimage to "images/close-hover.png"
   create image "close-hover"
   
   set the visible of the templateimage to true
   set the filename of the templateimage to "images/createit.png"
   create image "createit"
   
   # Create the close button
   set the style of the templatebutton to "transparent"
   set the showname of the templatebutton to false
   set the icon of the templatebutton to the ID of image "close"
   set the hovericon of the templatebutton to the ID of image "close-hover"
   set the hilite of the templatebutton to false
   set the threed of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the showborder of the templatebutton to false
   create button "close"
   set the width of button "close" to 34
   set the height of button "close" to 34
   
   # Create the title
   set the showfocusborder of the templatefield to false
   set the textsize of the templatefield to 50
   set the forecolor of the templatefield to "255,255,255"
   set the textstyle of the templatefield to "bold"
   set the textalign of the templatefield to "center"
   set the showborder of the templatefield to false
   set the showfocusborder of the templatefield to false
   set the locktext of the templatefield to true
   set the autohilight of the templatefield to false
   set the text of the templatefield to "Create It Course" 
   set the opaque of the templatefield to false
   set the dontwrap of the templatefield to true
   create field "title"
   set the height of field "title" to the formattedheight of field "title"
   set the width of field "title" to the formattedwidth of field "title"
   
   # Create the intro text
   set the textsize of the templatefield to 14
   set the textalign of the templatefield to "left"
   set the dontwrap of the templatefield to false
   set the text of the templatefield to "If you are new to LiveCode we suggest following the Create It course to develop all the skills you need to build your own app idea. If you’re a coder, why not use the final apps below as a starting point for learning." 
   create field "intro"
   
   # Create the intro text
   set the textsize of the templatefield to 14
   set the textstyle of the templatefield to empty
   set the dontwrap of the templatefield to true
   set the text of the templatefield to "App Name"
   set the textalign of the templatefield to "center"
   create field "app name"
   
   # Create the line
   set the backcolor of the templategraphic to empty
   set the bordercolor of the templategraphic to "255,255,255"
   set the height of the templategraphic to 1
   set the width of the templategraphic to 500
   set the blendlevel of the templategraphic to 85
   set the showborder of the templategraphic to true
   set the linesize of the templategraphic to 1
   set the visible of the templategraphic to true
   set the threed of the templategraphic to false
   create graphic "line"
   
   # Repeat through the course contents directory to generate the images and text 
   # for the accordion.
   
   local tCourseAppFolder
   set the itemdel to "/"
   put item 1 to -2 of the filename of me & "/course apps/" into tCourseAppFolder
   revIDEPushDefaultFolder tCourseAppFolder
   
   local tApps, tAppFolder
   put the folders into tApps
   sort tApps numeric
   repeat for each line tCourseAppNumber in tApps
      if char 1 of tCourseAppNumber is "." then next repeat
      
      put tCourseAppFolder & "/" & tCourseAppNumber into tAppFolder
      
      if there is not a file tAppFolder & "/app.png" then next repeat
      if there is not a file tAppFolder & "/info.txt" then next repeat
      
      # Create the lesson app image
      set the filename of the templateimage to "course apps/"&tCourseAppNumber&"/app.png"
      set the dropshadow["color"] of the templateimage to "0,0,0"
      set the dropshadow["opacity"] of the templateimage to 30
      set the dropshadow["angle"] of the templateimage to 100
      create image ("app" & tCourseAppNumber)
      
      # Create info
      local tAppInfo, tAppName, tAppLearningOutcomes, tAppWebLink
      put textdecode(URL ("binfile:" & tAppFolder & "/info.txt"), "UTF-8") into tAppInfo
      put line 1 of tAppInfo into tAppName
      put line 2 of tAppInfo into tAppLearningOutcomes
      put line 3 of tAppInfo into tAppWebLink
      replace "\n" with return in tAppLearningOutcomes
      
      # Create the info box
      set the text of the templatefield to tAppName & return & return & "Learning Outcomes" & return & tAppLearningOutcomes
      set the visible of the templatefield to false
      set the textsize of the templatefield to 11
      set the textfont of the templatefield to empty
      set the opaque of the templatefield to false
      set the textalign of the templatefield to "left"
      set the dontwrap of the templatefield to false
      create field ("info" & tCourseAppNumber)
      set the textsize of line 1 of field ("info" & tCourseAppNumber) to 14
      set the textcolor of line 4 to -1 of field ("info" & tCourseAppNumber) to "187,219,231"
      
      # Create the start lesson button
      set the text of the templatefield to "Open Tutorial"
      set the visible of the templatefield to false
      set the textsize of the templatefield to 12
      set the textfont of the templatefield to "bold"
      set the backgroundcolor of the templatefield to "79,196,216"
      set the opaque of the templatefield to true
      create field ("startlesson" & tCourseAppNumber)
      set the width of field ("startlesson" & tCourseAppNumber) to the formattedwidth of field ("startlesson" & tCourseAppNumber)
      set the height of field ("startlesson" & tCourseAppNumber) to the formattedheight of field ("startlesson" & tCourseAppNumber) - the margins of  field ("startlesson" & tCourseAppNumber)
      
      set the text of the templatefield to "Open App"
      create field ("openapp" & tCourseAppNumber)
      set the width of field ("openapp" & tCourseAppNumber) to the formattedwidth of field ("openapp" & tCourseAppNumber)
      set the height of field ("openapp" & tCourseAppNumber) to the formattedheight of field ("openapp" & tCourseAppNumber) - the margins of  field ("openapp" & tCourseAppNumber)
      
      if tCourseAppNumber > sAppCount then put tCourseAppNumber into sAppCount
   end repeat
   
   revIDEPopDefaultFolder
   
   # Reset all the templates we've used as they are global
   reset the templatefield
   reset the templategraphic
   reset the templatebutton
   reset the templateimage
   
   stackLayout
   
   unlock messages
   unlock screen
end stackGenerate

on stackLayout
   lock screen
   lock messages
   
   # Layout is performed once on startup
   # Layout is done control by control from top left to bottom right of card
   # A variable tTop holds the current top position which is updated after controls
   # at that top position are placed.
   # The constant WINDOW_MARGIN is the space between the edge of the frame and contents
   # The constant CONTENT_PADDING is a space between content elements
   # The stack width is set on stackGenerate and the height is set at the end of this handler based on the contents height
   
   local tTop
   
   # Place the close button
   set the topright of button "close" to the width of me - (WINDOW_MARGIN/2), (WINDOW_MARGIN/2)
   
   # Place Create It Brand
   set the topleft of image "createit" to WINDOW_MARGIN,WINDOW_MARGIN + the margins of field "title"
   
   # Place Title
   set the topleft of field "title" to the right of image "createit" - 95,WINDOW_MARGIN
   put the bottom of field "title" + CONTENT_PADDING - the margins of field "title" into tTop
   
   # Place intro
   set the width of field "intro" to the width of me - (WINDOW_MARGIN * 2)
   set the loc of field "intro" to the loc of card 1 of me
   set the height of field "intro" to the formattedheight of field "intro"
   set the top of field "intro" to tTop
   put the bottom of field "intro" + CONTENT_PADDING into tTop
   
   # Place the line
   set the width of graphic "line" to the width of me - (WINDOW_MARGIN * 2)
   set the loc of graphic "line" to the loc of card 1 of me
   set the top of graphic "line" to tTop
   put the bottom of graphic "line" + (CONTENT_PADDING * 2) into tTop
   
   # Layout the accordion
   if there is an image "app1" then
      local x, tLeft, tOpenAppNumber, tTotalWidth, tOpenWidthRatio, tAccordionWidthRatio, tAccordionItemWidth
      put 0.35 into tOpenWidthRatio
      put 0.65 into tAccordionWidthRatio
      put the width of me - (WINDOW_MARGIN * 2) into tTotalWidth
      if sHoverAppNumber is a number then
         put ((tTotalWidth * tAccordionWidthRatio) - the width of image "app1") / (sAppCount) into tAccordionItemWidth
      else
         put ((tTotalWidth * tAccordionWidthRatio) - the width of image "app1") / (sAppCount-2) into tAccordionItemWidth
      end if
      put WINDOW_MARGIN into tLeft
      
      repeat with x = 1 to sAppCount
         set the topleft of image ("app" & x) to tLeft, tTop
         if x is sSelectedAppNumber then
            show field ("info" & x) 
            show field ("startlesson" & x) 
            set the width of field ("info" & x) to (tTotalWidth * tOpenWidthRatio) - the width of image ("app" & x)
            set the height of field ("info" & x) to the formattedheight of field ("info" & x)
            set the topleft of field ("info" & x) to the right image ("app" & x), the top of image ("app" & x) + 15
            set the topleft of field ("startlesson" & x) to the left field ("info" & x)+the margins of field ("info" & x), the bottom of field ("info" & x) 
            set the topleft of field ("openapp" & x) to the left field ("startlesson" & x), the bottom of field ("startlesson" & x) 
            add tTotalWidth * tOpenWidthRatio to tLeft
         else if x is sHoverAppNumber then
            add tAccordionItemWidth * 3 to tLeft
            put line 1 of field ("info" & sHoverAppNumber) into field "app name"
            show field "app name"
            set the loc of field "app name" to the loc of image ("app" & x)
            set the top of field "app name" to the bottom of image ("app" & x) + 5
         else
            add tAccordionItemWidth to tLeft
         end if
      end repeat
      put the bottom of image "app1" + CONTENT_PADDING into tTop
   end if
   
   # Set the stack hight and position based on space taken up
   set the height of this stack to tTop + WINDOW_MARGIN
   set the loc of me to the screenloc
   //set the left of me to 150
   
   unlock messages
   unlock screen
end stackLayout

on mouseUp
   if the mouseloc is within the rect of button "close" then
      stackClose
      if revIDEPrefGet("StartPageShow") is not "false" then
         revIDEOpenPalette "Start Center"
      end if
   else if the short name of the target begins with "app" then
      local tTarget
      put the short name of the target into tTarget
      replace "app" with empty in tTarget
      
      lock screen
      set the coloroverlay of the target to empty
      if exists(field ("info" & sSelectedAppNumber)) then
         hide field ("info" & sSelectedAppNumber)
         hide field ("startlesson" & sSelectedAppNumber)
         
      end if
      put tTarget into sSelectedAppNumber
      put empty into sHoverAppNumber
      hide field "app name"
      stackLayout
      unlock screen
   end if
end mouseUp

on mouseEnter
   if the short name of the target begins with "app" and the short name of the target is not ("app" & sSelectedAppNumber) then
      lock screen
      lock messages
      local tTarget
      put the short name of the target into tTarget
      delete char 1 to 3 of tTarget
      put tTarget into sHoverAppNumber
      
      --set the coloroverlay["color"] of the target to "0,0,0"
      --set the coloroverlay["opacity"] of the target to 25
      stackLayout
      unlock messages
      unlock screen
      end if
end mouseEnter

on mouseLeave
   if the short name of the target begins with "app" then
      lock messages
      set the coloroverlay of the target to empty
      --put empty into sHoverAppNumber
      --stackLayout
      local tFoundAppTarget
      repeat with x = 1 to sAppCount
         if the mouseloc is within the rect of image ("app" & x) then
            put true into tFoundAppTarget
            exit repeat
         end if
      end repeat
      
      if tFoundAppTarget is not true then
         put empty into sHoverAppNumber
         stackLayout
      end if
      unlock messages
   end if
end mouseLeave

on stackClose
   close me
end stackClose
