script "revwelcome"
constant WINDOW_MARGIN = 40
constant CONTENT_PADDING = 20

on preOpenStack
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
   local tStackWidth, tScreenRect
   put revIDEStackScreenRect(the short name of this stack) into tScreenRect
   put ((item 3 of line 1 of tScreenRect - item 1 of line 1 of tScreenRect) / 2) into tStackWidth
   if tStackWidth > 750 then put 750 into tStackWidth
   else if tStackWidth < 650 then put 650 into tStackWidth
   set the width of this stack to tStackWidth
   
   # Create the images for the close button
   set the filename of the templateimage to "images/close.png"
   set the visible of the templateimage to false
   create image "close"
   
   set the filename of the templateimage to "images/close-hover.png"
   create image "close-hover"
   
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
   set the text of the templatefield to "Welcome" 
   create field "title"
   set the height of field "title" to the formattedheight of field "title"
   set the width of field "title" to the formattedwidth of field "title"
   
   # Create the intro text
   set the textsize of the templatefield to 14
   set the textalign of the templatefield to "left"
   set the text of the templatefield to "Thank you for downloading LiveCode. To help you get stated we’ve created an interactive tutorial that will guide you through our tool and help you build your first LiveCode app." 
   create field "intro"
   
   # Create highlight graphics
   set the opaque of the templategraphic to true
   set the backcolor of the templategraphic to "0,0,0"
   set the blendlevel of the templategraphic to 90
   set the linesize of the templategraphic to 0
   set the width of the templategraphic to (the width of me - (WINDOW_MARGIN*2)) /2
   set the height of the templategraphic to 200
   set the visible of the templategraphic to false
   set the showborder of the templategraphic to false
   create graphic "nonprogrammer-hover"
   create graphic "programmer-hover"
   
   # Create the non-programmer
   set the visible of the templateimage to true
   set the filename of the templateimage to "images/nonprogrammer.png"
   create image "nonprogrammer"
   
   # Create the programmer
   set the filename of the templateimage to "images/programmer.png"
   create image "programmer"
   
   # Create the non-programmer
   set the backgroundcolor of the templatefield to "212,0,23"
   set the dontwrap of the templatefield to true
   set the fixedlineheight of the templatefield to false
   set the textalign of the templatefield to "center"
   set the text of the templatefield to "I'm new to coding. Teach me!" 
   create field "nonprogrammer-badge"
   set the width of field "nonprogrammer-badge" to the formattedwidth of field "nonprogrammer-badge"
   set the height of field "nonprogrammer-badge" to the formattedheight of field "nonprogrammer-badge" - the margins of field "nonprogrammer-badge" + 1
   
   # Create the programmer badge
   set the backgroundcolor of the templatefield to "179,151,71"
   set the text of the templatefield to "I'm a seasoned coder" 
   create field "programmer-badge"
   set the width of field "programmer-badge" to the formattedwidth of field "programmer-badge"
   set the height of field "programmer-badge" to the formattedheight of field "programmer-badge" - the margins of field "nonprogrammer-badge" + 1
   
   # Create the non-programmer blurb
   set the textsize of the templatefield to 11
   set the backgroundcolor of the templatefield to empty
   set the opaque of the templatefield to false
   set the forecolor of the templatefield to "179,215,228"
   set the width of the templatefield to the width of me / 3
   set the dontwrap of the templatefield to false
   set the text of the templatefield to "Try our interactive Create It Course. Build the 20 most popular iOS apps step by step and learn to code along the way." 
   create field "nonprogrammer-blurb"
   set the height of field "nonprogrammer-blurb" to the formattedheight of field "nonprogrammer-blurb"
   
   # Create the programmer blurb
   set the text of the templatefield to "A tour of the IDE, documentation and hello world example." 
   create field "programmer-blurb"
   set the height of field "programmer-blurb" to the formattedheight of field "programmer-blurb"
   
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
   
   # Create the analytics check box
   set the style of the templatebutton to "checkbox"
   if revIDEGetPreference("optedInToAnalytics") is false then
      set the hilite of the templatebutton to false
   else
      set the hilite of the templatebutton to true
   end if
   set the showborder of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the threed of the templatebutton to false
   set the margins of the templatebutton to 0
   set the width of the templatebutton to 18
   set the icon of the templatebutton to empty
   set the hovericon of the templatebutton to empty
   create button "allow-analytics"
   
   # Create the analytics blurb
   set the text of the templatefield to "We want to build a product that helps absolutely anyone build apps. You can help us by letting us collect data on how you use LiveCode. All data is sent securely and is completely anonymous. We use the data to improve the interactive tutorials you are about to try out. If you would prefer to opt out please untick this box." 
   set the forecolor of the templatefield to "255,255,255"
   set the blendlevel of the templatefield to 50
   set the textsize of the templatefield to 10
   set the fixedlineheight of the templatefield to true
   set the textheight of the templatefield to 13
   set the textalign of the templatefield to "left"
   create field "analytics-blurb"
   
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
   
   # Place teh close button
   set the topright of button "close" to the width of me - (WINDOW_MARGIN/2), (WINDOW_MARGIN/2)
   
   # Place Title
   set the loc of field "title" to the loc of card 1 of me
   set the top of field "title" to WINDOW_MARGIN
   put the bottom of field "title" + CONTENT_PADDING - the margins of field "title" into tTop
   
   # Place intro
   set the width of field "intro" to the width of me - (WINDOW_MARGIN * 2)
   set the loc of field "intro" to the loc of card 1 of me
   set the height of field "intro" to the formattedheight of field "intro"
   set the top of field "intro" to tTop
   put the bottom of field "intro" + CONTENT_PADDING into tTop
   
   # Place Non programmer
   local tQuarter
   put (the width of me - (WINDOW_MARGIN * 2)) / 4 into tQuarter
   set the loc of image "nonprogrammer" to WINDOW_MARGIN+tQuarter,0
   set the top of image "nonprogrammer" to tTop
   
   set the loc of image "programmer" to WINDOW_MARGIN+tQuarter*3,0
   set the top of image "programmer" to tTop
   
   put the bottom of image "programmer" into tTop
   
   # Place the badges
   set the loc of field "nonprogrammer-badge" to the loc of image "nonprogrammer"
   set the top of field "nonprogrammer-badge" to tTop
   set the loc of field "programmer-badge" to the loc of image "programmer"
   set the top of field "programmer-badge" to tTop
   put the bottom of field "programmer-badge" + CONTENT_PADDING into tTop
   
   # Place the blurbs
   set the loc of field "nonprogrammer-blurb" to the loc of image "nonprogrammer"
   set the top of field "nonprogrammer-blurb" to tTop
   set the loc of field "programmer-blurb" to the loc of image "programmer"
   set the top of field "programmer-blurb" to tTop
   put max(the bottom of field "nonprogrammer-blurb", the bottom of field "programmer-blurb") + CONTENT_PADDING into tTop
   
   # Place the hover highlights
   local tHeight
   put max(the bottom of field "programmer-blurb" - the top of image "programmer", the bottom of field "nonprogrammer-blurb" - the top of image "nonprogrammer") - the margins of field "nonprogrammer-blurb" + CONTENT_PADDING into tHeight
   set the height of graphic "programmer-hover" to tHeight
   set the loc of graphic "programmer-hover" to the loc of image "programmer"
   set the top of graphic "programmer-hover" to the top of image "programmer" - (CONTENT_PADDING / 2)
   
   set the height of graphic "nonprogrammer-hover" to tHeight
   set the loc of graphic "nonprogrammer-hover" to the loc of image "nonprogrammer"
   set the top of graphic "nonprogrammer-hover" to the top of image "nonprogrammer" - (CONTENT_PADDING / 2)
   
   # Place the line
   set the width of graphic "line" to the width of me - (WINDOW_MARGIN * 2)
   set the loc of graphic "line" to the loc of card 1 of me
   set the top of graphic "line" to tTop
   put the bottom of graphic "line" + CONTENT_PADDING into tTop
   
   # place the analytics text and
   set the topleft of button "allow-analytics" to WINDOW_MARGIN, tTop
   set the width of field "analytics-blurb" to the width of me - WINDOW_MARGIN - the right of button "allow-analytics"
   set the height of field "analytics-blurb" to the formattedheight of field "analytics-blurb"
   set the topleft of field "analytics-blurb" to the right of button "allow-analytics", tTop
   put the bottom of field "analytics-blurb" - the margins of field "analytics-blurb" into tTop
   
   # Set the stack hight and position based on space taken up
   set the height of this stack to tTop + WINDOW_MARGIN
   set the loc of me to revIDEStackScreenLoc(the short name of this stack)
   
   unlock messages
   unlock screen
end stackLayout

on mouseMove
   if the mouseloc is within the rect of graphic "nonprogrammer-hover" and the visible of graphic "nonprogrammer-hover" is false then
      show graphic "nonprogrammer-hover"
      revIDESetCursor "hand"
   else if the mouseloc is not within the rect of graphic "nonprogrammer-hover" and the visible of graphic "nonprogrammer-hover" is true then
      hide graphic "nonprogrammer-hover"
      unlock cursor
   else if the mouseloc is within the rect of graphic "programmer-hover" and the visible of graphic "programmer-hover" is false then
      show graphic "programmer-hover"
      revIDESetCursor "hand"
   else if the mouseloc is not within the rect of graphic "programmer-hover" and the visible of graphic "programmer-hover" is true then
      hide graphic "programmer-hover"
      unlock cursor
   end if
end mouseMove

on mouseUp
   if the mouseloc is within the rect of button "close" then
      stackClose
      if revIDEGetPreference("cStartPageShow") is not "false" then
         revIDEOpenPalette "Start Center"
      end if
   else if the mouseloc is within the rect of graphic "nonprogrammer-hover" then
      stackClose
      revIDEStartTutorial "My First App"
   else if the mouseloc is within the rect of graphic "programmer-hover" then
      answer "closing this stack and starting programmer walkthrough"
      stackClose
   end if
end mouseUp

on stackClose
   if the hilite of button "allow-analytics" is true then
      revIDESetPreference "optedInToAnalytics", true
   else
      revIDESetPreference "optedInToAnalytics", false
   end if
   revIDESetPreference "welcomeScreenShown", true
   close me
end stackClose
