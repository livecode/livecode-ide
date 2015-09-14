script "revSEVariablesCheckboxBehavior"

/*
When the checkbox is clicked, a message is sent immediately.
The following custom properties are used to configure how the
message is sent:

   cCallback       -- the message to send
   cCallbackTarget -- the long ID of the object that the message
                      should be sent to
*/

-- This sends the registered callback message.
on update
   dispatch the cCallback of me to the cCallbackTarget of me \
         with the hilite of me
end update

--
-- Mouse event handlers
--
on mouseUp
   send "update" to me
end mouseUp
