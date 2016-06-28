	var tRepoFolder, tIDEFolder;
	
	function guideExists(pGuideName){
		$.each(tUserGuideData.guides, function( index, value ) {
			if(index == pGuideName) return true;
		});
		return false;
	}
	
	function guideFirst(){
		for (first in tUserGuideData.guides) break;
		return first;
	}

	function renderMarkdown(pGuideIndex){
		var renderer = new marked.Renderer();		
		var current_level = 1;
	
		var navigation_html = '';	
		renderer.heading = function (text, level) 
		{
		  	var escapedText = text.toLowerCase().replace(/[^\w]+/g, '-');
	
			if (level < 3)
			{
				if (level <= current_level && navigation_html != '')
					navigation_html += '</li>';
			
				if (level == current_level)
				{
					// We are on the same level so just create another li
					navigation_html += '<li><a href="#'+escapedText+'">'+text+'</a>';	
				} 
				else if (level < current_level)
				{
					for (i = level; i < current_level; i++)
						navigation_html += '</ul>';
						
					// we've gone up a level so just close sub uls and add an li
					navigation_html += '<li><a href="#'+escapedText+'">'+text+'</a>';
					current_level = level;
				} 
				else if (level > current_level)
				{
					for (i = current_level; i < level; i++)
						navigation_html += '<ul class="nav">';
				
					// we've gone down at least one level so create sub uls
					navigation_html += '<li><a href="#'+escapedText+'">'+text+'</a>';
					current_level = level;
				}
			}
			return '<h' + level + ' id="' + escapedText + '">' +text + '</h' + level + '>';
		
		},
		
		renderer.image = function (href, title, text) 
		{
			var tGuideLocation = tUserGuideData.guides[pGuideIndex].location;
			
			var image_parts;
			image_parts = href.split("/");
			var image_file;
			image_file = image_parts[image_parts.length - 1];
			
			if (tGuideLocation == 'repo')
			{
				return '<img src="' + tRepoFolder + '/images/' + image_file + '" />';
			}
			else
			{
				return '<img src="' + tIDEFolder + '/images/' + image_file + '" />';
			}
		},
	
		renderer.link = function(href, title, text)
		{
			var tLink;
			tLink = '<a class="external_link" href="' + href + '"';
			tLink += ' title="' + title + '"';
			tLink += ' target="_blank"';
			tLink += '>'+text+'</a>';
			return tLink;
		},
	
		// Set the core markdown
		$("#documentation").html(marked(tUserGuideData.guides[pGuideIndex].data, { renderer: renderer }));

		// Close all 'ul's
		for (i = current_level; i > 1; i--)
			navigation_html += '</ul>';

		var navigation_contents_html = '<ul class="nav bs-docs-sidenav lc_docs_nav">';		
		$.each(tUserGuideData.guides, function( index, value ) {
			if (index == pGuideIndex)
				navigation_contents_html += '<li role="presentation" class="guide_list_item">' + navigation_html;
			else
				navigation_contents_html += '<li role="presentation" class="guide_list_item"><a role="menuitem" tabindex="-1" guide="'+index+'" guide_name="'+value.name+'">'+value["display name"]+'</a>';
			navigation_contents_html += '</li>';
		});
		navigation_contents_html += '</ul>';
		
		$("#guide_name").html(tUserGuideData.guides[pGuideIndex]["display name"]);
		$("#nav_holder").html(navigation_contents_html);
		$(window).scrollTop(0);
		$("#documentation").scrollspy('refresh');
		$("#documentation img").addClass("img-responsive");
	
		$('pre code').each(function(i, block) {
		//console.log(block);
		hljs.highlightBlock(block);
	});	
	}
	
	function showLandingPage(pNavList)
	{
		$("#guide_name").html('Choose Guide:');
		$("#lcdoc_landing_list").html(pNavList);
		$("#lcdoc_guide_landing").css('display', '');
	}
	
	function guideLinkClicked(pEvent, pWhich)
	{
		pEvent.preventDefault();
		loadGuide(pWhich);
		$(this).html(tUserGuideData.guides[pWhich]["display name"]);
	}
	
	function loadGuide(pGuideName){
		renderMarkdown(pGuideName);
	}
   	
   	function initializeGuides(pRepoFolder, pIDEFolder)
   	{
   		tRepoFolder = pRepoFolder;
   		tIDEFolder = pIDEFolder
   	
   		var navigation_chooser_html = '';
		$.each(tUserGuideData.guides, function( index, value ) {
			navigation_chooser_html += '<li role="presentation" class="guide_list_item"><a role="menuitem" tabindex="-1" guide="'+index+'" guide_name="'+value.name+'">'+value["display name"]+'</a></li>';
		});
		
		$("#guide_chooser_list").html(navigation_chooser_html);
		
   		var tLastLoadedGuide;
   		if (guideExists(tLastLoadedGuide))
			loadGuide(tLastLoadedGuide);
		else
			showLandingPage(navigation_chooser_html);
   	
   		$('#nav_holder').on("click","a",function(e) {
   			var tGuide;
   			tGuide = $(this).attr("guide");
   			
   			if (typeof tGuide != 'undefined')
   				guideLinkClicked(e, tGuide);
		});
		
   		$('#lcdoc_landing_list').on("click","a",function(e) {
   			guideLinkClicked(e, $(this).attr("guide"));
		});
		
		$("#lc_userguide_nav").bind('mousewheel', function(e, d) {
			var t = $("#nav_holder");
			if (d > 0 && t.scrollTop() === 0) {
				e.preventDefault();
			}
			else {
				if (d < 0 && (t.scrollTop() == t.get(0).scrollHeight - t.innerHeight())) {
					e.preventDefault();
				}
			}
		});
   		
   		$("body").on( "click", ".external_link", function(e) {
			if (isRunningInLiveCodeBrowser())
			{
				e.preventDefault();
				var tTarget = $(this).attr("href");
				liveCode.linkClicked(tTarget);
			}
		});
   	}