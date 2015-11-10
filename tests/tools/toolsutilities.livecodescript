script "IDEToolsUtilities"
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
   local tIDELibrary, tScript
   put TestGetIDERepositoryPath() & "/Toolset/libraries/revidelibrary.8.livecodescript" into tIDELibrary

   -- Work around the fact that the property listener is not available in standalone mode
   put the script of stack tIDELibrary into tScript
   replace "_internal" with "--_internal" in tScript
   replace "the revObjectListeners" with "empty" in tScript
   set the script of stack tIDELibrary to tScript

   insert the script of stack "revIDELibrary" into back

   -- Need the home stack for some paths
   get the name of stack (TestGetIDERepositoryPath() & "/Toolset/home.livecodescript")
end TestSetup

on _TestIcons pArray
   local tThemePath
   put revIDEThemePath() into tThemePath

   repeat for each key tKey in pArray
      TestAssert tKey & "icon file exists", there is a file (tThemePath & slash & tKey & ".icon.png")
   end repeat
end _TestIcons

on TestGraphicsIcons
   _TestIcons revIDEGraphics()
end TestGraphicsIcons

on TestGraphicToolsIcons
   _TestIcons revIDEGraphicTools()
end TestGraphicToolsIcons

on TestPaintToolsIcons
   _TestIcons revIDEPaintTools()
end TestPaintToolsIcons

on TestRunEditIcons
   _TestIcons revIDERunEditTools()
end TestRunEditIcons

on TestClassicControlsIcons
   _TestIcons revIDEClassicControls()
end TestClassicControlsIcons
