# DataGrid 2: Edit Mode and Swipe Actions

The DataGrid has been updated to to include an edit mode and swipe actions. This only applies to DataGrids in form mode.

When in edit mode, customizable action and reorder controls will be displayed for each row, allowing for action handling and dynamic reordering.

When enabled, swipe actions allow the user to drag rows left and right as well as swiping them.

## Edit Mode

A DataGrid can be put into edit mode by setting its *dgEditMode* property.

```
set the dgEditMode of group "DataGrid 1" to true
```

Only form DataGrids with fixed row height can be put into edit mode.

### Action Select and Reorder Controls

By default, when in edit mode, an action select control will appear on the right hand side of each row and a reorder control on the left.

You can customize the appearance of these controls in 3 ways:

The first method is to specify your own controls using the the properties *"edit mode action select control"* and *"edit mode reorder control"*.

```
set the dgProps["edit mode action select control"] of group "DataGrid 1" to group "my action select control"
set the dgProps["edit mode reorder control"] of group "DataGrid 1" to group empty
```

Setting either of these properties to empty will result in the given control not being displayed. This way you can turn reordering off, or have only the reordering controls visible.

The second method is to handle the messages *GetEditModeActionSelectControl* and *GetEditModeReorderControl* in your row behavior script.

```
on GetEditModeActionSelectControl
  return the long id of group "my action select control" of me
end GetEditModeActionSelectControl
```

You can also use this method to prevent the reordering of certain rows. For example:

```
on GetEditModeReorderControl
   if the dgIndex of me is 5 then
      return empty
   end if
   pass GetEditModeReorderControl
end GetEditModeReorderControl
```

This will mean the row with DataGrid index 5 cannot be reordered.

The third method is to directly edit the template controls, which are hidden groups your DataGrid template stack.

### Laying Out Rows

When positioning controls in your row behavior script, you can take into account any edit mode controls that have been overlaid onto the row by using the rows working rect. The working rect is passed as the second parameter to the LayoutControl message that is sent to your row behavior script.

```
on LayoutControl pControlRect, pWorkingRect
   ...
end LayoutControl
```

### Action Controls

By default, when an action select control is clicked, an action control will appear on the right hand side of the corresponding row. The default action control is a delete button.

The default behavior of a user click on the action select control can be overridden by handling the message *EditModeActionSelectControlClicked* in your row behavior. The default implementation is as follows:

```
on EditModeActionSelectControlClicked pTarget
   EditModeShowActionControlForIndex the dgIndex of me
end EditModeActionSelectControlClicked
```
The target of the click is passed as a parameter. The command *EditModeShowActionControlForIndex* can be used make the action control appear for the given row.

The appearance of the action control can be customized in the same way as the action select and reorder controls: By either setting the *dgProps["edit mode action  control"]* of the DataGrid, handling the message *GetActionControl* in your row behavior or editing the template control in the template stack. This allows you to potentially add multiple buttons to the action control or customize the action control for specific rows.

By default, when the action control is clicked, the given row will be deleted. This behavior can be overridden by handling the message *EditModeActionControlClicked*. For example, if you want to display a confirmation dialog, you would add the following to your row behavior script.

```
on EditModeActionControlClicked pTarget
   answer "Are you sure you want to delete?" with "Yes" and "No"
   if it is "Yes" then
      DeleteIndex the dgIndex of me
   else
      EditModeHideActionControl
   end if
end EditModeActionControlClicked
```

The target of the click is passed as a parameter to the message. Use this if you want to determine where the user clicked within the action control.

The command *EditModeHideActionControl* is used here to hide the action control and return things to the standard edit mode view.

### Reordering

When the user starts a dynamic reorder, the message *EditModeReorderStarted* is sent to the DataGrid.

```
on EditModeReorderStarted pIndex, pLineNo
   ...
end EditModeReorderStarted
```

The DataGrid index of the row being reordered is passed as the first parameter. The position of the row within the DataGrid is passed as the second parameter.

When a reorder has been completed, the message *EditModeReorderCompleted* is sent to the DataGrid.

```
on EditModeReorderCompleted pIndex, pStartLineNo, pEndLineNo
   ...
end EditModeReorderCompleted
```

The DataGrid index of the row reordered is passed as the first parameter. The original position of the row within the DataGrid is passed as the second parameter. The new position of the row within the DataGrid is passed as the third parameter.

## Swipe Actions

To turn on swipe actions, set the DataGrid property *"enable swipes"* to true.

```
set the dgProps["enable swipes"] of group "DataGrid 1" to true
```

When enabled, users can drag and swipe rows left and right.

By default, when a user drags a row left or right, a swipe control will be revealed. When a user swipes left or right, the right or left swipe control will be fully revealed. When a user clicks on the left or right swipe control, the row will be deleted.

The appearance of the left and right swipe controls can be customized in the same way as the edit mode controls, by either setting the DataGrid properties *"left swipe control"* or *"right swipe control"*, handling the messages *"GetLeftSwipeControl"* or "GetRightSwipeControl"* or editing the template swipe control in the template stack.

For example, if you only want the right hand side swipe control to appear, you can do the following:

```
set the dgProps["left swipe control"] of group "DataGrid 1" to empty
```

The default left and right swipe actions can be overridden by handling the messages *"RowSwipedLeft"* and *"RowSwipedRight"* in your row behavior.

For example, if you want left swipes to immediately delete the row rather than fully reveal the right swipe control, you can do the following:

```
on RowSwipedLeft
   DeleteIndex the dgIndex of me
end RowSwipedLeft
```

The command *RowSwipeShowControlForIndexAndSide* can be used to fully reveal a swipe control. For example:

```
dispatch "RowSwipeShowControlForIndexAndSide" to group "DataGrid 1" with 5, "left"
```

This will result in the left hand side swipe control being shown for the row with index 5.

Any visible swipe control can be dismissed using the command *RowSwipeHideControl*

```
dispatch "RowSwipeHideControl" to group "DataGrid 1" to group "DataGrid 1"
```

The default behavior for when a swipe control is clicked can be overridden by handling the messages *"RowLeftSwipeControlClicked"* and *"RowLeftRightControlClicked"* in your row behavior script.

For example:

```
on RowLeftRightControlClicked pTarget
   switch the name of pTarget
      case "archive"
         ...
         DeleteIndex the dgIndex of me
         break
      case "delete"
         ...
         DeleteIndex the dgIndex of me
         break
      default
         RowSwipeHideControl
         break
   end switch
end RowLeftRightControlClicked
```

The target of the click is passed as the first parameter, allowing you to determine where in the swipe control the user clicked.

## Enabling and Disabling Animations

By default, all of the edit mode and swipe actions will be animated. Animations can be turned off by setting the DataGrid property *"animate actions"* to false.

```
set the dgProps["animate actions"] of group "DataGrid 1" to false
```
