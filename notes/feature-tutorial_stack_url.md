# Tutorial stack browser display

The tutorial system can now display a browser widget set to a url given
in its specification. In order to do so, simply include the url as a 
section of the step in question. For example:

	step "Instructions With Browser"
		Please watch the following video with detailed instructions on how
		to proceed.
	url
		<url of video>
	action
		interlude
		go to step "Create New Mainstack"
	end step