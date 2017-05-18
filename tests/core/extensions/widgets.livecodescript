script "IDEWidgets"
/*
Copyright (C) 2017 LiveCode Ltd.

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

on TestIDEWidgets
    local tStack
    create stack
    put it into tStack

	local tWidgets
	put revIDEExtensions("widget") into tWidgets
	
	local tCreated
	repeat for each key tWidgetKind in tWidgets
		revIDECreateObject tWidgetKind, tStack
		put the result into tCreated
		TestAssert "create a" && tWidgetKind, there is a tCreated
	end repeat
end TestIDEWidgets