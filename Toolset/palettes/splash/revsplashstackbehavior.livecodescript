script "revSplashStackBehavior"
on preOpenStack
   local tSplashPath
   
   lock messages
   put revEnvironmentEditionProperty("skin") & "/splash.png" into tSplashPath
   set the textColor of this card to revEnvironmentEditionProperty("revsplash_text_color")
   set the textAlign of field "status" to "center"
   set the top of field "status" to 270
   set the width of field "status" to the width of card 1 of me * 0.8
   set the left of field "status" of me to the width of card 1 of me * 0.1
   set the filename of image "Splash" to tSplashPath
   set the id of image "Splash" to the id of stack "revIcons"
   set the location of me to the screenLoc
   
   set the htmlText of field "License" to revEnvironmentEditionProperty("splash_strap")
   
   unlock messages
end preOpenStack

setProp statusMessage pMessage
   put pMessage into field "status" of me
end statusMessage
