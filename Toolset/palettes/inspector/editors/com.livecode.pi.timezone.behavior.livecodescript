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
   
   put "\(UTC -12) "&sTimezones["-12"]&"/|-12" & return \
         & "\(UTC -11) "&sTimezones["-11"]&"/|-11" & return \
         & "\(UTC -10) "&sTimezones["-10"]&"/|-10" & return \
         & "\(UTC -9) "&sTimezones["-9"]&"/|-9" & return \
         & "\(UTC -8) "&sTimezones["-8"]&"/|-8" & return \
         & "\(UTC -7) "&sTimezones["-7"]&"/|-7" & return \
         & "\(UTC -6) "&sTimezones["-6"]&"/|-6" & return \
         & "\(UTC -5) "&sTimezones["-5"]&"/|-5" & return \
         & "\(UTC -4) "&sTimezones["-4"]&"/|-4" & return \
         & "\(UTC -3) "&sTimezones["-3"]&"/|-3" & return \
         & "\(UTC -2) "&sTimezones["-2"]&"/|-2" & return \
         & "\(UTC -1) "&sTimezones["-1"]&"/|-1" & return \
         & "\(UTC +0) "&sTimezones["0"]&"/|0" & return \
         & "\(UTC +1) "&sTimezones["1"]&"/|1" & return \
         & "\(UTC +2) "&sTimezones["2"]&"/|2" & return \
         & "\(UTC +3) "&sTimezones["3"]&"/|3" & return \
         & "\(UTC +4) "&sTimezones["4"]&"/|4" & return \
         & "\(UTC +5) "&sTimezones["5"]&"/|5" & return \
         & "\(UTC +6) "&sTimezones["6"]&"/|6" & return \
         & "\(UTC +7) "&sTimezones["7"]&"/|7" & return \
         & "\(UTC +8) "&sTimezones["8"]&"/|8" & return \
         & "\(UTC +9) "&sTimezones["9"]&"/|9" & return \
         & "\(UTC +10) "&sTimezones["10"]&"/|10" & return \
         & "\(UTC +11) "&sTimezones["11"]&"/|11" & return \
         & "\(UTC +12) "&sTimezones["12"]&"/|12" \
         into sTimeZoneList
   
   set the text of button "pulldown" of me to sTimeZoneList
end editorInitialize

function UTCTimezoneToDescription pTimezone
   return sTimezones[pTimezone]
end UTCTimezoneToDescription

function valueToLabel pValue
   if pValue is not a number then return "(UTC +0)" && UTCTimezoneToDescription("0")
   else if pValue > 12 then return "(UTC +12)" && UTCTimezoneToDescription("+12")
   else if pValue < -12 then return "(UTC +12)" && UTCTimezoneToDescription("-12")
   else return "(UTC "&pValue&")" && UTCTimezoneToDescription(pValue)
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
   set the editorValue of me to pSelection
   updateProperty
end valueChanged
