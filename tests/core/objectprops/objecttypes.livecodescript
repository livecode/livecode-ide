script "IDEObjectTypes"
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

on TestButtonStyles
	local tButtonID
	create button
	put the long id of it into tButtonID
	
	repeat for each item tItem in ",standard,menu,popup,checkbox,radiobutton,roundrect,rectangle,oval,transparent,shadow,opaque"
		set the style of tButtonID to tItem
		TestAssert "button style" && quote & tItem & quote && "has corresponding type", ideObjectTypeFromObject(tButtonID) is not empty
	end repeat
end TestButtonStyles

on TestFieldStyles
	local tFieldID
	create field
	put the long id of it into tFieldID
	
	repeat for each item tItem in "scrolling,rectangle,transparent,shadow,opaque"
		set the style of tFieldID to tItem
		TestAssert "field style" && quote & tItem & quote && "has corresponding type", ideObjectTypeFromObject(tFieldID) is not empty
	end repeat
end TestFieldStyles

on TestGraphicStyles
	local tGraphicID
	create graphic
	put the long id of it into tGraphicID
	
	repeat for each item tItem in "rectangle,roundrect,polygon,curve,oval,regular,line,text,arc"
		set the style of tGraphicID to tItem
		TestAssert "graphic style" && quote & tItem & quote && "has corresponding type", ideObjectTypeFromObject(tGraphicID) is not empty
	end repeat
end TestGraphicStyles

on TestScrollbarStyles
	local tScrollbarID
	create scrollbar
	put the long id of it into tScrollbarID
	
	repeat for each item tItem in "scrollbar,scale,progress"
		set the style of tScrollbarID to tItem
		TestAssert "scrollbar style" && quote & tItem & quote && "has corresponding type", ideObjectTypeFromObject(tScrollbarID) is not empty
	end repeat
end TestScrollbarStyles