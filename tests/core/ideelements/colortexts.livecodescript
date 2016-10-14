script "CoreGraphics"
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

on TestNamesToColors
	 local tColorNames
   local tName
   local tValue
   
   # for some reason the defaultFolder in here is ide/tests/core/idelibrary
   put url("file:" & "../../../Toolset/resources/supporting_files/colors/namesToColors.txt") into tColorNames
   filter tColorNames with "Gray*"
   TestAssert "NamesToColors is not empty", tColorNames is not empty
   repeat for each line tColor in tColorNames
      put item 1 of tColor into tName
      replace "Gray" with empty in tName
      if tName is not empty then
      	put round(tName*255/100) into tValue
	    	TestAssert item 1 of tColor && "is a valid Gray shade", item 2 of tColor is item 3 of tColor and item 2 of tColor is item 4 of tColor
      	TestAssert item 1 of tColor && "is the correct color", item 2 of tColor is tValue
      end if
   end repeat
end TestNamesToColors

on TestColorsToNames
	 local tColorNames
   local tName
   local tValue
   
   put url("file:" & "../../../Toolset/resources/supporting_files/colors/colorsToNames.txt") into tColorNames
   TestAssert "ColorsToNames is not empty after reading", tColorNames is not empty
   filter tColorNames with "*,Gray*"
   TestAssert "ColorsToNames is not empty after filtering", tColorNames is not empty
   repeat for each line tColor in tColorNames
      put item 4 of tColor into tName
      replace "Gray" with empty in tName
      if tName is not empty then
      	put round(tName*255/100) into tValue
      	TestAssert item 4 of tColor && "is a valid Gray shade", item 1 of tColor is item 2 of tColor and item 1 of tColor is item 3 of tColor
      	TestAssert item 4 of tColor && "is the correct color", item 2 of tColor is tValue
      end if
   end repeat
end TestColorsToNames

