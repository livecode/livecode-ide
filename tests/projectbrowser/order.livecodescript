script "ProjectBrowserOrder"
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

constant kSortPrefs = "stack,card,control"
local sShowPref, sSortPrefs
on TestSetup
	local tShowPref
	put revIDEGetPreference("cShowRevolutionStacks") into sShowPref
	revIDESetPreference "cShowRevolutionStacks", false
	StoreSortPrefs
	CreateObjects
end TestSetup

on TestTeardown
	revIDESetPreference "cShowRevolutionStacks", sShowPref
	RestoreSortPrefs
end TestTeardown

private command StoreSortPrefs
	repeat for each item tWhich in kSortPrefs
		put revIDEGetPreference("pb_" & tWhich & "Sort") into \
			sSortPrefs[tWhich]
	end repeat
end StoreSortPrefs

private command RestoreSortPrefs
	repeat for each item tWhich in kSortPrefs
		revIDESetPreference "pb_" & tWhich & "Sort", sSortPrefs[tWhich]
	end repeat
end RestoreSortPrefs

private command SetOrderPref pWhich, pType, pOrder
	revIDESetPBSortPreferences "pb_" & pWhich & "Sort", pType, pOrder
end SetOrderPref

local sCardsStack, sButtonsCard	
private command CreateObjects
	create stack "A"
	create stack "C"
	create stack "B"
	put it into sCardsStack
	set the defaultStack to "B"
	
	set the name of this card of stack "B" to "A"
	create card "C"
	create card "B"
	put it into sButtonsCard
	
	create button "A"
	create button "C"
	create button "B"
end CreateObjects

private function ExpectedNames pType, pOrder
	if pType is "name" then
		if pOrder is "ascending" then
			return "A,B,C"
		else
			return "C,B,A"
		end if
	else
		if pOrder is "ascending" then
			return "A,C,B"
		else
			return "B,C,A"
		end if
	end if
end ExpectedNames

private function ObservedNames pArray
	local tNames
	repeat with x = 1 to the number of elements in pArray
		local tName
		put pArray[x]["name"] into tName
		if tName is not among the items of "A,B,C" then
			next repeat
		end if
		
		if tNames is empty then
			put tName into tNames
		else
			put comma & tName after tNames
		end if
	end repeat
	
	return tNames
end ObservedNames

private command _TestOrderPref pWhich, pType, pOrder
	SetOrderPref pWhich, pType, pOrder
	
	local tArray
	switch pWhich
		case "stack"
			put revIDEStacksForDataView(0) into tArray
			break
		case "card"
			put revIDECardPropertiesOfStack(sCardsStack, 0) into tArray
			break
		case "control"
			put revIDEControlPropertiesOfCard(sButtonsCard, 0) into tArray
			break
	end switch
	
	local tDesc, tResult
	put "PB" && pWhich && "order" && pType && "-" && pOrder into tDesc
	put ObservedNames(tArray) is ExpectedNames(pType, pOrder) \ 
		into tResult
	
	TestDiagnostic tDesc
	TestDiagnostic ObservedNames(tArray)
	TestDiagnostic ExpectedNames(pType, pOrder)
	TestDiagnostic tResult
	
	TestAssert tDesc, tResult
end _TestOrderPref

on TestOrder	
	repeat for each item tWhich in kSortPrefs
		repeat for each item tType in "name,layer"
			repeat for each item tOrder in "ascending,descending"
				_TestOrderPref tWhich, tType, tOrder
			end repeat
		end repeat
	end repeat
end TestOrder