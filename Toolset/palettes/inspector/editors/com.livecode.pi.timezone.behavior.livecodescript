script "com.livecode.pi.timezone.behavior"
local sTimezones, sTimeZoneList
on editorInitialize
   set the editorMinWidth of me to 40
   set the editorMaxWidth of me to 0
   
   put "United States Minor Outlying Islands" into sTimezones["-12"]
   put "Hawaii" into sTimezones["-11"]
   put "Papeete, Honolulu" into sTimezones["-10"]
   put "Anchorage" into sTimezones["-9"]
   put "Los Angeles, Vancouver, Tijuana" into sTimezones["-8"]
   put "Phoenix, Denver, Calgary, Ciudad Juárez" into sTimezones["-7"]
   put "Chicago, Guatemala City, Mexico City, San José, San Salvador, Winnipeg" into sTimezones["-6"]
   put "New York, Lima, Toronto, Bogotá, Havana, Kingston" into sTimezones["-5"]
   put "Santiago, La Paz, San Juan de Puerto Rico, Manaus, Halifax" into sTimezones["-4"]
   put "Buenos Aires, Montevideo, São Paulo" into sTimezones["-3"]
   put "" into sTimezones["-2"]
   put "Cape Verde" into sTimezones["-1"]
   put "London, Casablanca, Dakar, Dublin, Lisbon" into sTimezones["0"]
   put "Paris, Berlin, Kinshasa, Lagos, Madrid, Rome" into sTimezones["1"]
   put "Athens, Cairo, Istanbul, Beirut, Helsinki, Jerusalem, Johannesburg" into sTimezones["2"]
   put "Moscow, Nairobi, Baghdad" into sTimezones["3"]
   put "Dubai, Baku" into sTimezones["4"]
   put "Karachi, Tashkent, Yekaterinburg" into sTimezones["5"]
   put "Dhaka, Almaty, Novosibirsk" into sTimezones["6"]
   put "Jakarta, Bangkok, Krasnoyarsk, Hanoi" into sTimezones["7"]
   put "Beijing, Shanghai, Hong Kong, Taipei, Singapore, Kuala Lumpur, Perth, Manila, Denpasar, Irkutsk" into sTimezones["8"]
   put "Seoul, Tokyo, Pyongyang, Ambon, Yakutsk" into sTimezones["9"]
   put "Canberra, Vladivostok, Port Moresby" into sTimezones["10"]
   put "Buka, Honiara, Noumea" into sTimezones["11"]
   put "Auckland, Suva" into sTimezones["12"]
   
   local tHourOffset, tSecondOffset, tLabel
   put "Local Time/|local" & return into sTimeZoneList
   repeat with tHourOffset = -12 to 12
      put tHourOffset * 3600 into tSecondOffset
      put valueToLabel(tSecondOffset) into tLabel
      
      -- The space in the menu string is _important_.  On Linux and Windows,
      -- if the first character in the menu tag is '-' it's treated as a
      -- separator.  However, numbers in LiveCode are allowed to start with
      -- a space.
      put merge("\[[tLabel]]/| [[tSecondOffset]]") & return after sTimeZoneList
   end repeat
   delete char -1 of sTimeZoneList
   
   set the text of button "pulldown" of me to sTimeZoneList
end editorInitialize

function UTCTimezoneToDescription pTimezone
   if pTimezone is a number then
      return sTimezones[pTimezone/3600]
   end if
   return empty
end UTCTimezoneToDescription

function valueToLabel pValue
   if pValue is empty then return "Local Time"
   
   if pValue is not a number then put 0 into pValue
   
   local tHourOffset, tMinuteOffset, tSign, tDescription
   put UTCTimeZoneToDescription(pValue) into tDescription
   if pValue < 0 then
      put -pValue into pValue
      put "-" into tSign
   else
      put "+" into tSign
   end if
   put floor(pValue/3600) into tHourOffset
   put floor(pValue/60 - tHourOffset * 60) into tMinuteOffset
   repeat while length(tHourOffset) < 2
      put 0 before tHourOffset
   end repeat
   repeat while length(tMinuteOffset) < 2
      put 0 before tMinuteOffset
   end repeat
   
   return merge("(UTC [[tSign]][[tHourOffset]]:[[tMinuteOffset]]) [[tDescription]]") 
end valueToLabel

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   if tValue is empty then
      set the label of button "pulldown" of me to " "
      else
      set the label of button "pulldown" of me to valueToLabel(tValue)
   end if
   set the enabled of me to tEnabled
   if tEffective is true then
      set the textcolor of button "pulldown" of me to "150,150,150"
   else
      set the textcolor of button "pulldown" of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of button "pulldown" of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged pSelection
   if pSelection is "local" then
      set the editorValue of me to empty
   else
      set the editorValue of me to pSelection
   end if
   updateProperty
end valueChanged
