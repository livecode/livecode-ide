script "IDEObjectProperties"
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

on TestIssue595
   local tPropInfo
   put revIDEPropertyInfo("borderWidth") into tPropInfo
   TestAssert "borderWidth minimum", tPropInfo["min"] is 0
end TestIssue595

on TestObjectTypes
   local tArray
   put true into tArray["com.livecode.interface.classic.Group"]
   put true into tArray["com.livecode.interface.classic.TableField"]
   put true into tArray["com.livecode.interface.classic.ListField"]
   put true into tArray["com.livecode.interface.classic.TextArea"]
   put true into tArray["com.livecode.interface.classic.Field"]
   put true into tArray["com.livecode.interface.classic.RadioButton"]
   put true into tArray["com.livecode.interface.classic.Checkbox"]
   put true into tArray["com.livecode.interface.classic.ComboBox"]
   put true into tArray["com.livecode.interface.classic.OptionMenu"]
   put true into tArray["com.livecode.interface.classic.PulldownMenu"]
   put true into tArray["com.livecode.interface.classic.PopupMenu"]
   put true into tArray["com.livecode.interface.classic.TabPanel"]
   put true into tArray["com.livecode.interface.classic.RectangleButton"]
   put true into tArray["com.livecode.interface.classic.DefaultButton"]
   put true into tArray["com.livecode.interface.classic.Button"]
   put true into tArray["com.livecode.interface.classic.Slider"]
   put true into tArray["com.livecode.interface.classic.ProgressBar"]
   put true into tArray["com.livecode.interface.classic.LittleArrows"]
   put true into tArray["com.livecode.interface.classic.Scrollbar"]
   put true into tArray["com.livecode.interface.classic.Image"]
   put true into tArray["com.livecode.interface.classic.Player"]
   put true into tArray["com.livecode.interface.classic.RectangleGraphic"]
   put true into tArray["com.livecode.interface.classic.RoundRectGraphic"]
   put true into tArray["com.livecode.interface.classic.LineGraphic"]
   put true into tArray["com.livecode.interface.classic.OvalGraphic"]
   put true into tArray["com.livecode.interface.classic.CurveGraphic"]
   put true into tArray["com.livecode.interface.classic.PolygonGraphic"]
   put true into tArray["com.livecode.interface.classic.RegularGraphic"]

   repeat for each key tKey in tArray
      if tKey is "com.livecode.interface.classic.Player" and \ 
      	the platform is "linux" then
      	TestSkip tKey && "object", "Bug 18618"
      	next repeat
      end if
   
      TestDiagnostic tKey
      revIDEActionCreateObject tKey
      TestAssert tKey && "object", ideObjectTypeFromObject(the result) is tKey
   end repeat
end TestObjectTypes
