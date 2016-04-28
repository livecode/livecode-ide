script "PropertyInspectorCustomProps"
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

on TestBug16429
   local tCustomPropsArray
   put "cProp-empty" into tCustomPropsArray[""]["cProp"]
   put "cProp-customPropSet" into tCustomPropsArray["customPropSet"]["cProp"]
   
   local tButtonID
   create button
   put the long id of it into tButtonID
   
   revIDECustomPropertiesSet tButtonID, "", tCustomPropsArray
   
   TestAssert "custom props set", the cProp of tButtonID is "cProp-empty"
   
   set the customPropertySet of tButtonID to "customPropSet"
   
   TestAssert "custom props set in custom property set", the cProp of tButtonID is "cProp-customPropSet"
   
   set the cProp2 of tButtonID to "cProp2-customPropSet"
   
   set the customPropertySet of tButtonID to empty
   
   set the cProp2 of tButtonID to "cProp2-empty"
   
   local tArray
   put revIDECustomPropertiesGet(tButtonID) into tArray
   
   put "cProp2-customPropSet" into tCustomPropsArray["customPropSet"]["cProp2"]
   put "cProp2-empty" into tCustomPropsArray[""]["cProp2"]
   
   TestAssert "custom props round trip", tArray is tCustomPropsArray
   
end TestBug16429