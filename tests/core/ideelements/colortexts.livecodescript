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

on TestGrayNamesToColors
   local tColorNames
   local tGrayValue
   local tRGB
   local tColorRGBValue
   
   put the colornames into tColorNames
   filter tColorNames with "Gray*"
   TestAssert "Gray colors are among color names", tColorNames is not empty
   repeat for each line tColor in tColorNames
      put tColor into tGrayValue
      replace "Gray" with empty in tGrayValue
      put revIDENamedColorToRGB(tColor) into tRGB
      if tGrayValue is not empty then
				 # use the engine to convert from colorname to rgb value
      	 put round(tGrayValue*255/100) into tColorRGBValue
      else
      	 # special case "Gray" is 190,190,190
      	 put 190 into tColorRGBValue
      end if
      TestAssert tColor && "is a valid Gray shade", item 1 of tRGB is item 2 of tRGB and item 2 of tRGB is item 3 of tRGB
      TestAssert tColor && "is" && tColorRGBValue && "but should be" && tRGB, item 1 of tRGB is tColorRGBValue
   end repeat
end TestGrayNamesToColors

on TestGrayColorsToNames
   local tColorNames
   local tGrayValue
   local tColorName
   local tRGB
   local tGrayRGB
   
   put the colornames into tColorNames
   filter tColorNames with "Gray*"
   TestAssert "Gray colors are among color names", tColorNames is not empty
   repeat for each line tColor in tColorNames
      put tColor into tGrayValue
      replace "Gray" with empty in tGrayValue
      if tGrayValue is not empty then
      	 put round(tGrayValue*255/100) into tRGB
      else
      	 put 190 into tRGB
      end if
      # the next line looks up the value in colorsToNames.txt
      put tRGB,tRGB,tRGB into tGrayRGB
      put revIDERGBToNamedColor(tGrayRGB) into tColorName
      # Gray100 is 255,255,255 which is a alias for White
      if tColor is "Gray100" then
         put "White" into tColor
      end if
      TestAssert tColor && "is" && tColorName && "but should be" && tColor, tColor is tColorName
      TestAssert tColor && "rgb value is" && tGrayRGB, tColor is tColorName
   end repeat
end TestGrayColorsToNames

on TestNamesToColors
   local tColorRGBValue
   local tRGB
   
   repeat for each line tColor in the colornames
      # get the RGB value from the engine
      put revIDENamedColorToRGB(tColor) into tColorRGBValue
      # get the actual RGB value
      put revIDENamedColorToRGB(tColor) into tRGB
      TestAssert tColor && "rgb value is" && tColorRGBValue && "but should be" && tRGB, tRGB is tColorRGBValue
   end repeat
end TestNamesToColors

# handle the aliased colors
private function DisambiguateColorName pColorName
	switch pColorName
		case "MediumAquamarine"
			return "Aquamarine3"
		case "Azure1"
			return "Azure"
		case "Gray0"
			return "Black"
		case "Red4"
		case "OrangeRed4"
		case "Firebrick4"
			return "Brown4"
		case "Chartreuse1"
			return "Chartreuse"
		case "DarkOrange1"
			return "Chocolate1"
		case "DarkOrange2"
			return "Chocolate2"
		case "DarkOrange3"
			return "Chocolate3"
		case "DarkOrange4"
		case "SaddleBrown"
			return "Chocolate4"
		case "Coral1"
			return "Coral"
		case "CornSilk1"
			return "CornSilk"
		case "Magenta4"
			return "DarkOrchid"
		case "Salmon"
			return "DarkSalmon"
		case "Red3"
			return "Firebrick3"
		case "Gray100"
			return "White"
		case "Tomato4"
			return "IndianRed4"
		case "Ivory1"
			return "Ivory"
		case "LightCyan1"
			return "LightCyan"
		case "LightGreen"
			return "PaleGreen2"
		case "NavyBlue"
			return "Navy"
		case "Tan4"
			return "Orange4"
		case "Tan3"
			return "Peru"
		case "SeaGreen4"
			return "SeaGreen"
		case "Yellow1"
			return "Yellow"
	end switch
	return pColorName
end DisambiguateColorName

on TestColorsToNames
   local tColorName
   local tRGB
   
   repeat for each line tColor in the colornames
      # get the RGB value from the engine
      put revIDENamedColorToRGB(tColor) into tRGB
      # get the colorname from our array
      put DisambiguateColorName(revIDERGBToNamedColor(tRGB)) into tColorName
      TestAssert tColor && "is the correct color name for" && tRGB && "got" && tColorName, DisambiguateColorName(tColor) is tColorName
   end repeat
end TestColorsToNames

