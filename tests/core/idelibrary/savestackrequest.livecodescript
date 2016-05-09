script "TestSaveStackRequest"
/*
Copyright (C) 2016 LiveCode Ltd.

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

constant kFilename = "TestSaveStackRequest.livecode"

-- Test that handling saveStackRequest cancels saving a stack
on TestSaveStackRequest
   local tStack

   create invisible stack "SaveTest"
   put it into tStack

   set the script of tStack to "on saveStackRequest; end saveStackRequest"
   set the filename of tStack to kFileName

   revIDESaveStack tStack

   TestAssert "Handling saveStackRequest cancels save", there is not a file kFileName
end TestSaveStackRequest