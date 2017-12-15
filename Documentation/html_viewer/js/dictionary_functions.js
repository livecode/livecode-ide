	var tState = { 	
		selected_api_id:"",
		selected_entry_index:{},
		history:{
			list:[],
			selected_index:-1
		},	
		cached_search_data:{},
		filters:{},
		filtered_data:[],
		data:"",
		sort_type:"",
		edition: ""
	};
	
	if ($.session.get("selected_api_id")) {
		tState.selected_api_id = $.session.get("selected_api_id");
	} else {
		tState.selected_api_id = 0;
	}

	if ($.session.get("selected_entry_index")) {
		var tIndexArray = $.session.get("selected_entry_index");
		tState.selected_entry_index[tState.selected_api_id] = tIndexArray[tState.selected_api_id];
	} else { 
		tState.selected_entry_index[tState.selected_api_id] = 0;
	}

	library_set(tState.selected_api_id);	

	function dataGet(){
		if(!dictionary_data.docs.hasOwnProperty(tState.selected_api_id)){
			$.each(dictionary_data.docs, function(index, libraryData) {
				tState.selected_api_id = index;
				return false;
			});
		}
		
		if (tState.dirtyData == true || tState.data == ""){
			tState.data = dictionary_data.docs[tState.selected_api_id].doc.sort(compareEntryObject);
			tState.dirtyData = false;
		}
		
		return tState.data;
	}

	// Return all the syntax and synonyms associated with an entry
	// as a (matchable) string
	function collectSyntax(pEntry)
	{
		var tSyntax = pEntry["display name"];
		$.each(pEntry["display syntax"], function (index, value) 
		{
			tSyntax += ' ' + value;
		});
		if(pEntry.hasOwnProperty("synonyms"))
		{
			$.each(pEntry["synonyms"], function (index, value) 
			{
				tSyntax += ' ' + value;
			});
		}
		tSyntax = removeHtmlEntityEscapes(tSyntax);
		return tSyntax;
	}
	
	// Replace HTML entity escape sequences with native characters for
	// searching and highlighting syntax and synonyms.
	function removeHtmlEntityEscapes(pTerm)
	{
		var tTerm = pTerm;
		tTerm = tTerm.replace(/&amp;/g,"&");
		tTerm = tTerm.replace(/&lt;/g,"<");
		tTerm = tTerm.replace(/&gt;/g,">");
		tTerm = tTerm.replace(/&quot;/g,'"');
		return tTerm;
	}
	
	// Replace characters with their HTML entity escape sequences after
	// processing is completed.
	function addHtmlEntityEscapes(pTerm)
	{
		var tTerm = pTerm;
		tTerm = tTerm.replace(/&/g,"&amp;");
		tTerm = tTerm.replace(/\</g,"&lt;");
		tTerm = tTerm.replace(/\>/g,"&gt;");
		tTerm = tTerm.replace(/\"/g,"&quot;");
		return tTerm;
	}
	
	// Escape RegExp special characters for use in searching
	var kSpecialCharacters = /[.*+?|()\[\]{}\\$^]/g; // .*+?|()[]{}\$^
	RegExp.escape = function(pText)
	{
		return pText.replace(kSpecialCharacters, "\\$&");
	}
	
	// Return a list of matched search terms
	function dataSearch(pTerm)
	{
		// Check the cached search data
		if (tState.cached_search_data.hasOwnProperty("term") && tState.cached_search_data.term == pTerm) 
			return tState.cached_search_data.data;
			
		tState.cached_search_data.term = pTerm;
		tState.cached_search_data.data = [];
		
		// Escape RegExp special characters:  \ ^ $ [
		// A leading space will enable full RegExp support
		var tTerm = '';
		if(pTerm.charAt(0) == ' ')
			tTerm = pTerm.trim();
		else
			tTerm = RegExp.escape(pTerm);

		// Get a list of space-delimited search terms
		var tokensOfTerm = tTerm.match(/\S+/g);
		
		// Generate three regexes - one that matches all syntax that 
		// contains each search term, and one that matches all syntax that
		// contains a word beginning with each search term, one that will
		// match full words of each search term. This way we can prioritize
		// full word matches and matches that start with the search terms.
		var matchExp = '';
		var priorityMatch = '';
		var wordMatch = '';
		$.each(tokensOfTerm, function(index, matchToken)
		{
			matchExp += '(?=.*' + matchToken + ')';
			priorityMatch += '(?=.*\\b' + matchToken + ')';
			wordMatch += '(?=.*\\b' + matchToken + '\\b)';
		});

		// Special case sorting for terms considered word break
		// characters that would not get sorted properly.
		switch(pTerm){
			case '-':
			case '/':
			case ';':
			case '[':
			case '(':
			case '()':
				wordMatch = '(^' + tTerm + ')';
				break;
		}

		var regex = new RegExp(matchExp, "i");
		var priorityRegex = new RegExp(priorityMatch, "i");
		var wordRegex = new RegExp(wordMatch, "i");
		
		// Grep for the general search term
		tState . cached_search_data . data = $.grep(tState.filtered_data, function (e) 
		{
			var tToMatch = collectSyntax(e);
			var tMatched = regex.test(tToMatch);
			return tMatched;
		});

        // Sort the priority matches to the top
		tState . cached_search_data . data . sort(function(a, b) 
        {
			var tNameA, tNameB, tMatchA, tMatchB

			tNameA = a["display name"].toLowerCase();
			if(a.hasOwnProperty("synonyms"))
			{
				$.each(a["synonyms"], function (index, value) 
				{
					tNameA += ' ' + value.toLowerCase();
				});
			}

			tNameB = b["display name"].toLowerCase();
			if(b.hasOwnProperty("synonyms"))
			{
				$.each(b["synonyms"], function (index, value) 
				{
					tNameB += ' ' + value.toLowerCase();
				});
			}

			// full word matches in display name sort to the top
			tMatchA = wordRegex.test(tNameA);
			tMatchB = wordRegex.test(tNameB);
			if (tMatchA && !tMatchB)
				return -1;
			if (tMatchB && !tMatchA)
				return 1;

			// display names with words that start with terms next
			tMatchA = priorityRegex.test(tNameA);
			tMatchB = priorityRegex.test(tNameB);
			if (tMatchA && !tMatchB)
				return -1;
			if (tMatchB && !tMatchA)
				return 1;

			// display name contains search terms next
			tMatchA = regex.test(tNameA);
			tMatchB = regex.test(tNameB);
			if (tMatchA && !tMatchB)
				return -1;
			if (tMatchB && !tMatchA)
				return 1;

			// alphabetical sort by display name for everything else
			if (tNameA < tNameB)
				return -1;
			if (tNameA > tNameB)
				return 1;
			return 0;
		});
		//console.timeEnd("Search");
	
		return tState . cached_search_data . data;
	}
	
	// Return the data of the current API subject to the applied filters
	function dataFilter() {
		var filtered_data = [];
		var tFound_data = []
		
		if (jQuery.isEmptyObject(tState.filters))
		{
		 	tState.filtered_data = dataGet();
		} 
		else 
		{		
			// Iterate over the current data to find entries that match
			// the current filter options
			$.each(dataGet(), function(index, entryData)
			{
				$.each(tState.filters, function(category, values)
				{
					tFound_data[category] = 0;
					$.each(values, function(tag, tag_value){
					
						switch(category){
							case "type":
								if(entryData[category] == tag){
									tFound_data[category]++;
								 }
								break;
							case "platforms":
							case "OS":
							case "tags":
							case "associations":
								if(entryData.hasOwnProperty(category)){
									$.each(entryData[category], function(item_index, entry_item_value){
										if(tag == entry_item_value){
											tFound_data[category]++;
										}
									});
								}
								break;
						}
					});
				});
			
				var tMatch = true;
				$.each(tState.filters, function(category, values) {
					if (tFound_data[category] == 0) {
						tMatch = false;
					}
				});
			
				if (tMatch == true) {
					filtered_data.push(entryData);
				}
			});
			
			tState.filtered_data = filtered_data;
		}
		displayFilters();
		
		tState.cached_search_data = {};
		displayEntryListGrep($("#ui_filer").val());	
	}
	
	function compareEntryObject(entryObject1,entryObject2) {
		if(entryObject1["display name"].toLowerCase() < entryObject2["display name"].toLowerCase())
			return -1;
		if (entryObject1["display name"].toLowerCase() > entryObject2["display name"].toLowerCase())
			return 1;
		return 0;
	}


	function filterOptions(pCategories)
	{
		var tFilterOptionWithCount = {}
		var tShowCategories = pCategories.split(',');
		$.each(tShowCategories, function(index, category_name) 
		{
			tFilterOptionWithCount[category_name] = {}
		});
		
		$.each(tState.filtered_data, function(entry_index, entry_data) 
		{
			$.each(tShowCategories, function(category_index, category_name) 
			{
				// If the category is already being filtered on then don't count
				if (!tState.filters.hasOwnProperty(category_name))
				{
					if (entry_data[category_name])
					{
						var tTagData = entry_data[category_name];
						if (!Array.isArray(tTagData))
						{
							tTagData = {1: tTagData};
						}

						// Iterate through the values of this category and accumulate data
						$.each(tTagData, function(tag, tag_value) 
						{
							if (tFilterOptionWithCount[category_name].hasOwnProperty(tag_value))
							{
								tFilterOptionWithCount[category_name][tag_value]["count"]++;
							} 
							else 
							{	
								tFilterOptionWithCount[category_name][tag_value] = {};
								tFilterOptionWithCount[category_name][tag_value]["count"] = 1;
							}
							tFilterOptionWithCount[category_name][tag_value]["name"] = tag_value;
						});
					}
				}
			});
		});

		// Use association display name as displayed tag value
		$.each(tFilterOptionWithCount["associations"], function(tag_value, tag_data)
		{
			var tEntryIndex = resolve_association_index(tag_value, '');
			if (!isDefined(tEntryIndex))
				return true;
	
			var tEntryObject = tState.data[tEntryIndex];			
			var tDisplayName = tag_data["value"]
			if (tEntryObject.hasOwnProperty("display name"))
			{
				tDisplayName = tEntryObject["display name"];
			}
			tFilterOptionWithCount["associations"][tag_value]["name"] = tDisplayName
		});
		
		return tFilterOptionWithCount;
	}
	
	function filter_remove(pTag,pValue,pName){
		if (tState.filters.hasOwnProperty(pTag) &&
			tState.filters[pTag].hasOwnProperty(pValue))
		{
			delete tState.filters[pTag][pValue];
			if (jQuery.isEmptyObject(tState.filters[pTag]))
			{
				delete tState.filters[pTag];
			}
		}
		dataFilter();
	}
	
	function filter_add(pTag,pValue,pName){
		if(!tState.filters.hasOwnProperty(pTag)) tState.filters[pTag] = {};
		
		if(!tState.filters[pTag].hasOwnProperty(pValue)){
			tState.filters[pTag][pValue] = pName
			dataFilter();
		}
	}
	
	function sortedKeys(obj)
	{
		return Object.keys(obj).sort();
	}
	
	function filter_cell(pCategory, pValue, pSpan)
	{
		var tHTML = '';
		tHTML += '<td';
		if (pSpan)
			tHTML += ' colspan="2"';
		tHTML += '><a href="#" class="apply_filter" ';
		tHTML += 'filter_category="'+pCategory+'" ';
		tHTML += 'filter_name="'+pValue["name"]+'" ';		
		tHTML += 'filter_value="'+pValue["value"]+'">';
		tHTML += pValue["name"].toLowerCase();
		//tHTML += '<span class="badge">'+pFilterData[tFilter]+'</span>';
		tHTML += '</a></td>';
		return tHTML;
	}
	
	function filter_html(pCategory, pFilterData)
	{
		var tHTML = '';
		tHTML += '<tbody><tr><td class="category"><b>'+pCategory+':</b></td></tr>';
		var tSortedFilters = sortedKeys(pFilterData);
		
		// Create a list of the filters we'll actually be displaying
		var tDisplayedFilters = [];
		$.each(tSortedFilters, function(index, value)
		{
			var tTagValue = pFilterData[value];
			if (!tState.filters.hasOwnProperty(pCategory) || 
				!tState.filters[pCategory].hasOwnProperty(value))
			{
				tTagValue["value"] = value;
				tDisplayedFilters.push(tTagValue);
			}
		});
		
		if (pCategory == 'associations')
		{
			// Display associations one per line
			for (i = 1; i <= tDisplayedFilters.length; i++)
			{
				tHTML += '<tr>'
				tHTML += filter_cell(pCategory, tDisplayedFilters[i-1], true);
				tHTML += '<td></td>';
				tHTML += '</tr>';
			}
		}
		else
		{
			// Display them in alphabetical order going down the table,
			// rather than across
			var tRowCount = Math.ceil(tDisplayedFilters.length / 2);
			var tOddNumber = tDisplayedFilters.length % 2 == 1;
			for (i = 1; i <= tRowCount; i++)
			{
				tHTML += '<tr>'
				tHTML += filter_cell(pCategory, tDisplayedFilters[i-1], false);
				if (i != tRowCount || !tOddNumber)
					tHTML += filter_cell(pCategory, tDisplayedFilters[i - 1 + tRowCount], false);
				tHTML += '</tr>';
			}
		}
		tHTML += '</tbody>';
		
		return tHTML;
	}
	
	function displayFilters(){
		// First display the applied filters
		var tHTML = "";
		$.each(tState.filters, function(filter_category, filter) 
		{
			tHTML += '<div style="margin-bottom:10px">';
			tHTML += '<b>'+filter_category+':</b> ';
			$.each(filter, function(value, name) 
			{
				tHTML += '<button type="button" ';
				tHTML += 'class="btn btn-default btn-sm remove_filter" ';
				tHTML += 'filter_category="'+filter_category+'" ';
				tHTML += 'filter_value="'+value+'" ';				
				tHTML += 'filter_name="'+name+'">';
				tHTML += name;
				tHTML += '</button>';
			});
			tHTML += '</div>';
		});
		$("#filters").html(tHTML);
		
		// Next display the filter options
		tHTML = "";
		var tFilterData = filterOptions("type,associations,tags,OS,platforms");
		
		tHTML += '<div style="margin-bottom:50px">';
		tHTML += '<table>';
		$.each(tFilterData, function(category, value) {
			if(jQuery.isEmptyObject(value) == false)
				tHTML += filter_html(category, value);
		});
		tHTML += '</table>';
		tHTML += '</div>';
		$("#filters_options").html(tHTML);
	}
	
	function sortFilteredData(pData)
	{
		if (tState . sort_type == "")
			return pData;
			
		pData . sort(function(pLeft, pRight) {
			var tLeftValue, tRightValue;
			tLeftValue = pLeft[tState . sort_type];
			tRightValue = pRight[tState . sort_type];
			
			if (typeof tLeftValue == 'object')
				tLeftValue = tLeftValue[0]
			
			tLeftValue = tLeftValue.toLowerCase();

			if (typeof tRightValue == 'object')
				tRightValue = tRightValue[0];
				
			tRightValue = tRightValue.toLowerCase();
			
			if (tLeftValue < tRightValue)
				return -1;
			
			if (tRightValue < tLeftValue)
				return 1;
			
			return 0;
		});
		
		return pData;
	}
	
	function data_table_html(pDataSet)
	{
		var tHTML = "";
		tHTML += '<tbody id="list">';
		
		$.each(pDataSet, function(index, value) 
		{
			var tClass = "";
			if (tState.selected == value.id) 
				tClass = " active";
				
			if (value.hasOwnProperty("deprecated") && value.deprecated != '')
				tClass = " deprecated";

			if (value.hasOwnProperty("edition") && value.edition != '' && value.edition.toLowerCase() != 'community')
				tClass = " "+value.edition.toLowerCase();

			tHTML += '<tr class="entry_list_item load_entry'+tClass+'" ';
			tHTML += 'entryid="'+value["id"]+'" id="entry_list_item_'+value["id"]+'">';
			tHTML += '<td>'+value["display name"]+'</td>';
			tHTML += '<td>'+value["type"]+'</td>';
			tHTML += '<td>'+value["display syntax"][0]+'</td>';
			tHTML += '</tr>';
		});
		
		tHTML += '</tbody>';
		
		return tHTML;
	}
	
	function displayEntryListGrep(pTerm){
		var tHeader;
		tHeader = '<thead><tr>';
		tHeader += '<td class="list_sort" sortBy="display name"><a href="#"><b>Name</b><span class="caret"></span></a></td>';
		tHeader += '<td class="list_sort" sortBy="type"><a href="#"><b>Type</b><span class="caret"></span></a></td>';
		tHeader += '<td class="list_sort" sortBy="display syntax"><a href="#"><b>Syntax</b><span class="caret"></span></a></td>';
		
		$("#table_list_header").html(tHeader);
		
		var tData;
		if (pTerm)
			tData = dataSearch(pTerm);
		else {
			tState . cached_search_data = {};
			tData = tState . filtered_data;
		}
		
		sortFilteredData(tData);
		
		var tHTML;
		tHTML = data_table_html(tData);

		$("#table_list").html(tHTML);

		$(window).scrollTop(0);
		$("#table_container").scrollTop(0);
	}
	
	function displayLibraryChooser(){
		var tHTML = ""
		$.each(dictionary_data.docs, function(index, libraryData){
			if(index == tState.selected_api_id) tHTML += '<li role="presentation"><a role="menuitem" tabindex="-1" href="#" library_id="'+index+'" class="active">'+libraryData["display name"]+'</a></li>';
			else tHTML += '<li role="presentation"><a role="menuitem" tabindex="-1" href="#" library_id="'+index+'">'+libraryData["display name"]+'</a></li>';
		});
	
		$("#lcdoc_library_chooser_list").html(tHTML);
	}
	
	function formatMarkdown(pEntryObject, pContent)
	{
		var tMarkdown = pContent;
		if(pEntryObject.parameters){
			$.each(pEntryObject.parameters, function(index, value) {
				tMarkdown = tMarkdown.replace('<'+value.name+'>', '*'+value.name+'*');	
			});
		}

		if(pEntryObject.synonyms){
			$.each(pEntryObject.synonyms, function(index, value) {
				tMarkdown = tMarkdown.replace('<'+value+'>', '*'+value+'*');	
			});
		}
	
		tMarkdown = replace_link_placeholders_with_links(tMarkdown,pEntryObject);
		
		var renderer = new marked.Renderer();
		renderer.table = function(header, body) 
		{
			var tTable;
			tTable = '<div class="table-responsive"><table class="table table-bordered">\n';
			tTable += '<thead>' + header + '</thead>\n';
			tTable += '<tbody>' + body + '</tbody>\n';
			tTable += '</table></div>';
			
			return tTable;
		}
		
		renderer.link = function(href, title, text)
		{
			var tLink;
			tLink = '<a class="external_link" href="' + href + '"';
			tLink += ' title="' + title + '"';
			tLink += ' target="_blank"';
			tLink += '>'+text+'</a>';
			return tLink;
		}
		
		renderer.code = function(contents)
		{
			return '<pre><code>' + undo_link_replacement(contents) + '</code></pre>';
		}
		
		return marked(tMarkdown, { renderer: renderer });
	}
	
	function markdown_section(pWhich, pEntryObject)
	{
		var tSection = '';
		if (pEntryObject[pWhich])
		{
			// Format the markdown of the section
			tSection += '<div class="col-md-2 lcdoc_section_title">';
			tSection += pWhich;
			tSection += '</div>';
			tSection += '<div class="col-md-10 lcdoc_description" style="margin-bottom:10px">';
			tSection += formatMarkdown(pEntryObject, pEntryObject[pWhich]);
			tSection += '</div>';
		}
		return tSection;
	}
	
	// Add a background highlight to search terms found in syntax and synonyms
	var kSpanStartMarker = String.fromCharCode(2);
	var kSpanEndMarker = String.fromCharCode(3);
	var kSpanStartRegex = new RegExp(kSpanStartMarker, "g");
	var kSpanEndRegex = new RegExp(kSpanEndMarker, "g");
	function highlightSearchTerms(pText)
	{
		var tText = removeHtmlEntityEscapes(pText);
		
		if($("#ui_filer").val() != "")
		{
			var tTerm = $("#ui_filer").val();
			var tokensOfTerm = tTerm.match(/\S+/g);
			$.each(tokensOfTerm, function(index, matchToken)
			{
				var match_regex = new RegExp('(' + RegExp.escape(matchToken) + ')', "gi")
				tText = tText.replace(match_regex, function($1){
					// Need to use placeholders since we need to remove HTML
					// entities once done with adding hilighting.
					return kSpanStartMarker + $1 + kSpanEndMarker;
				});
			});
		}
		tText = addHtmlEntityEscapes(tText);
		tText = tText.replace(kSpanStartRegex, "<span style='background-color: yellow;'>");
		tText = tText.replace(kSpanEndRegex, "</span>");
		return tText;
	}

	function displayEntry(pEntryID)
	{	
		var tIndex = entryIdToIndex(pEntryID);
	    displayEntryAtIndex(tIndex);
	}
	
	function syntax_to_string(pSyntax)
	{
	    var tHtml = '';
	    $.each(pSyntax, function(index, value) {
	        if (index > 0)
	            tHtml += '<br>';
	        tHtml += replace_link_placeholders_with_param(value).replace(/[\n\r]/g, '<br>');
	    });
	    return tHtml;
	}

	// Associations must be one of the following:	
	const s_association_types = ["object","library","glossary","module","widget"];
	function resolve_association_index(pName, pAPI)
	{
		var tIndex;
		$.each(s_association_types, function(tTypeIndex, tType) {
			tIndex = entryNameToIndex(pName, tType, pAPI)
			if (isDefined(tIndex))
				return false;
		});
		return tIndex;
	}
	
	function displayEntryAtIndex(pIndex)
	{
		var tEntryObject = tState.data[pIndex];

		history_add(tEntryObject);
		
		var tEntryId = tEntryObject.id;
		
		if (tState.selected_entry_index[tState.selected_api_id] == pIndex) return 1;
		tState.selected_entry_index[tState.selected_api_id] = pIndex;
		$.session.set("selected_entry_index", tState.selected_entry_index);

		breadcrumb_draw();
		
		$(".entry_list_item").removeClass("active");
		$("#entry_list_item_"+tEntryId).addClass("active");
		selectedEntryEnsureInView(tEntryId);
		
		var tHTML = "";
		var references = [];
		
		tHTML += '<h1 style="margin:0px 0px 30px 12px">'+tEntryObject["display name"];
		
		var tUpgrade = true;
		if (!tEntryObject.hasOwnProperty("edition"))
			tUpgrade = false;
		else if (tState.edition == "professional")
			tUpgrade = false;
		else if (tState.edition == "commercial" && tEntryObject["edition"].toLowerCase() != "business")
			tUpgrade = false;
		else if (tState.edition == "communityplus" && (tEntryObject["edition"].toLowerCase() != "business" || tEntryObject["edition"].toLowerCase() != "indy"))
			tUpgrade = false;
		else if (tEntryObject["edition"].toLowerCase() == "community")
			tUpgrade = false;
		
		if (tUpgrade)
		{
			tHTML += ' <a href="#" class="upgrade btn btn-default" edition="' + tEntryObject["edition"] 
					+ '" display_name="' + tEntryObject["display name"] 
					+ '">Upgrade to ' + tEntryObject["edition"] + '</a>';
		}
		
		tHTML += '</h1><div class="row">';
	
		$.each(tEntryObject, function(index, value) {
			switch(index){
				case "id":
				case "name":
				case "library":
				// These are for 'meta' information, not for display
					return;
				case "examples":
					tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';	
					if($.isArray(value)){
						$.each(value, function(index2, value2) {
							tHTML += '<pre><code>' + value2.script + '</code></pre>';
						});
					} else {
						tHTML += 'Malformed examples in JSON';	
					}
					tHTML += '</div>';	
					break;
				case "parameters":
				case "value":
					if($.isArray(value)){
						
						tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';
						tHTML += '<div class="table-responsive"><table class="table table-bordered">';
						tHTML += '<thead><tr><th>Name</th><th>Type</th><th>Description</th></tr></thead><tbody>';
						$.each(value, function(index2, value2) 
						{
							tHTML += '<tr><td class="lcdoc_entry_param">' + value2.name + '</td>';
							tHTML += '<td>' + value2.type + '</td>';
							tHTML += '<td>'+parameterFormatValue(tEntryObject, value2, false)+'</td></tr>';
						});
						tHTML += '</tbody></table></div>';
						tHTML += '</div>';
					} else {
						tHTML += 'Malformed parameters in JSON';	
					}
					
					break;
				case "references":
					tHTML += '<div class="col-md-2 lcdoc_section_title">Related</div><div class="col-md-10" style="margin-bottom:10px">';
					
					$.each(value, function(reference_type, reference_array) {
						tHTML += reference_type + ': ';
						var reference_html = "";
						$.each(reference_array, function(reference_index, reference_name) {
							var tReference, tIndex;
							tIndex = entryNameToIndex(reference_name, reference_type, tEntryObject.library);
							if (isDefined(tIndex))
								tReference = click_text_from_index(reference_name, tIndex);
							else
								tReference = reference_name;
							
							if (reference_html == "") 
								reference_html = tReference;
							else 
								reference_html += ', ' + tReference;
						});
						tHTML += reference_html;
						tHTML += '<br />';
					});
				
					tHTML += '</div>';
				
					break;
				case "syntax":
					tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';	
					if($.isArray(value)){
						$.each(value, function(index2, value2) {
							tHTML += '<pre><code>' + highlightSearchTerms(remove_link_placeholders(value2)) + '</code></pre>';
						});
					} else {
						tHTML += 'Malformed syntax in JSON';	
					}
					tHTML += '</div>';
					break;
				case "associations":
					if($.isArray(value)){
						tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';
						var association_html = "";
						$.each(value, function(index2, value2) {
							var tIndex = resolve_association_index(value2, tEntryObject.library);
							
							var tAssociation;
							if (isDefined(tIndex))
							{
								var tName = value2;
								if (tState.data[tIndex].hasOwnProperty("display name"))
									tName = tState.data[tIndex]["display name"];

								tAssociation = click_text_from_index(tName, tIndex);
							}
							else
								tAssociation = value2;
							
							if (association_html == "") 
								association_html = tAssociation;
							else 
								association_html += ',' + tAssociation;
						});
						tHTML += association_html+'</div>';
					}
					break;
				case "summary":
					tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';
					//tHTML += '<span class="social social-ios"></span>';
					tHTML += replace_link_placeholders_with_links(value,tEntryObject);
					tHTML += '</div>';
					break;	
				case "description":
				case "security":
				case "tags":
				case "display name":
				case "display syntax":
				case "changes":
					break;
				
				case "edition":
					tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10 '+value.toLowerCase()+'" style="margin-bottom:10px">';
					tHTML += value;
					tHTML += '</div>';
					break;
				
				default:
					
					tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';
					//tHTML += '<span class="social social-ios"></span>';
					if (typeof value == 'object')
					{
						var tOutput = '';
						$.each(value, function(index, content)
						{
							if (tOutput != '')
								tOutput += ', ';
							tOutput += content;
						});
						if(index=="synonyms")
							tHTML += highlightSearchTerms(tOutput);
						else
							tHTML += tOutput;
					}
					else
						tHTML += value;
					tHTML += '</div>';
					break;
			}
		});
		
		var tMarkdownSections = ["description","changes"];
		$.each(tMarkdownSections, function(index, value)
		{
			tHTML += markdown_section(value, tEntryObject);
		});

		// Now that the entry has been displayed we need to look at the 
		// type. If it is one of the association types, we generate a
		// list of API entries with this entry as an association
		if (s_association_types.indexOf(tEntryObject.type) >= 0)
		{
			var object_name = tEntryObject["name"].toLowerCase();
			var object_data = {};
			
			$.each(dataGet(),function(entry_index, entry_data)
			{
				// Ignore self
				if (entry_index == pIndex)
					return true;
					
				if (entry_data.hasOwnProperty("associations"))
				{
					$.each(entry_data["associations"], function(index, value)
					{
						if (value.toLowerCase() == object_name)
						{
							if (!object_data.hasOwnProperty(entry_data.type))
							{
								object_data[entry_data.type] = [];
							}
							object_data[entry_data.type].push(entry_data);
							return false;
						}
					});
				}
			});
			
			$.each(object_data, function(item_type, item_data)
			{
				tHTML += '<div class="col-md-2 lcdoc_section_title">'+item_type+'</div><div class="col-md-10" style="margin-bottom:10px">';
				tHTML += '<table class="lcdoc_glossary_table">';
				tHTML += '<thead><tr><td><b>Name</b></td><td><b>Summary</b></td><td><b>Syntax</b></td></tr></thead><tbody>';
				$.each(item_data, function(item_intex, entry_data)
				{
					tHTML += '<tr>';
					tHTML += '<td>' + click_text_from_entry_data('', entry_data) +'</a></td>';
					tHTML += '<td>'+replace_link_placeholders_with_param(entry_data.summary)+'</td>';
					tHTML += '<td>'+syntax_to_string(entry_data.syntax)+'</td>';
					tHTML += '</tr>';
				});
				tHTML += '</tbody></table>';
				tHTML += '</div>';
			});
			//console.log(object_data);
		}
		
		tHTML += '</div>';
		
		$("#api_entry").html(tHTML);
		$('pre code').each(function(i, block) {
    		hljs.highlightBlock(block);
 		});		
 		
 		// Force code not detected as LCB to be highlighted as LCS
 		$(".hljs:not(.livecodebuilder)").each(function(i, block) {
 			$(this).addClass("livecode");
    		hljs.highlightBlock(block);
 		});
		window.scrollTo(0, 0);
	}
	
	var link_placeholder_regex;
	link_placeholder_regex = /<([^`>]*)>/igm;
	
	function replace_link_placeholders_with_param(pText){
		if(pText){
			var pText = pText.replace(link_placeholder_regex, function(matched_whole, matched_text) {
				var resolved = resolve_link_placeholder(matched_text);
				return '<span class="lcdoc_entry_param">' + resolved[0] + '</span>';	
			});
			return pText;
		}
	}	
	
	function remove_link_placeholders(pText){
		if(pText){
			var pText = pText.replace(link_placeholder_regex, function(matched_whole, matched_text) {
				return matched_text;
			});
			return pText;
		}
	}	
	
	function replace_link_placeholders_with_links(pText, pEntryObject){
		if(pText && pEntryObject){
			var pText = pText.replace(link_placeholder_regex, function(matched_whole, matched_text) {
				var return_text = matched_whole;
				
				if(pEntryObject.hasOwnProperty("display name")) {
					if(pEntryObject["display name"] != "" && matched_text == pEntryObject["display name"]){
						return_text =  '<span class="lcdoc_entry_name">' + pEntryObject["display name"] + '</span>';
					}
				}
				
				if(pEntryObject.hasOwnProperty("synonyms")) {
					$.each(pEntryObject.synonyms, function( index, value) {
						if (value == matched_text)
						 	return_text =  '<span class="lcdoc_entry_name">' + matched_text + '</span>';
				 	});
				} 
				
				if(pEntryObject.hasOwnProperty("parameters")) {
					$.each(pEntryObject.parameters, function(index, parameter_object) {
						if(parameter_object.name == matched_text){
							return_text = '<span class="lcdoc_entry_param">' + parameter_object.name + '</span>';
						} 
					});
             	}
             	
             	if(return_text == matched_whole){
             		var resolved = resolve_link_placeholder(matched_text);
             		
             		var resolved_index = resolve_link(pEntryObject, resolved[1], resolved[2]);
             		
             		if (isDefined(resolved_index))
             	   		return_text = click_text_from_index(resolved[0], resolved_index)
             		else
             			return_text = resolved[0];
             	}
             	
				if(return_text == matched_text){
					return matched_whole;
                }
             	return return_text;
         	});
		}
		return pText;
	}
	
	function click_text_from_entry_data(pLink, pEntryData)
	{
		if (pLink == '')
			return click_text(pEntryData["display name"], pEntryData.id);
		else
			return click_text(pLink, pEntryData.id);
	}
	
	function click_text_from_index(pText, pIndex)
	{
		var text;
		text = '<a href="javascript:void(0)" class="load_entry"';
		text += ' entryindex="'+pIndex+'"'; 
		text += '>' + pText + '</a>';
		return text;
	}
		
	function click_text(pText, pID)
	{
		var tIndex = entryIdToIndex(pID);
		return click_text_from_index(pText, tIndex)
	}
	
	function undo_link_replacement(pText)
	{
		var tRegex;
		tRegex = new RegExp('<a href="javascript:void\\(0\\)" class="load_entry"[^>]*>(.+)<\\/a>', 'ig');
		return pText.replace(tRegex, function(matched_whole, matched_text) 
		{
			return '<' + matched_text + '>';
		});
	}
	
	// Returns an array with the label, the reference name and optional reference type.
	function resolve_link_placeholder(pText) {
		var return_array = new Array();
		var matched_text = pText.split("|");	
             		
        if (matched_text[1])
        	return_array[0] = matched_text[1]
                      		
        // Find the entry ID for the given string
        var regex = /([^\(]*)(?:\((.*)\))?/;

		var result = regex.exec(matched_text[0]);
		
		if (!matched_text[1])
			return_array[0] = result[1];
		
		return_array[1] = result[1];
        return_array[2] = result[2];
     	return return_array;   
	}
	
	
	// Return an entry ID from the target name and optional type
	function resolve_link(pEntryObject, pTargetName, pTargetType) {
        var tIndex;
        if(pTargetType){
	        // Know name and type so lookup id
             tIndex = entryNameToIndex(pTargetName,pTargetType,pEntryObject.library);
        } else {
        	// Work out the type from the reference
			if(pEntryObject.hasOwnProperty("references")) {
				$.each(pEntryObject.references,  function(reference_type, reference_array) {
					$.each(reference_array, function(reference_index, reference_name) {
						if (reference_name == pTargetName)
						{
							tIndex = entryNameToIndex(reference_name,reference_type,pEntryObject.library);
							return;
						}
					});
					// Just find the first one if no type was specified.
					if (isDefined(tIndex))
						return;
				});
			}
        }
	        
	    return tIndex;
	}
	
	function entryData(pEntryID){
		var tData = {};
	
		$.each(dataGet(), function(index, value) {
			if(value.id == pEntryID){
				tData = value;
				return false;
			}
			
		});
		
		return tData;
	}
	
	function entryNameToIndex(pName,pType,pPriorityLibrary){
		pName = pName.toLowerCase();
		pType = pType.toLowerCase();
		pPriorityLibrary = pPriorityLibrary.toLowerCase();
		
		var tIndex;
		$.each(dataGet(), function(index, value) {
			if (value.name.toLowerCase() != pName 
			    && value["display name"].toLowerCase() != pName)
			{
				// Continue loop
				return true;
			}
			
			if (pType != '')
			{
				if (value.type.toLowerCase() != pType)
				{
					// Continue loop
					return true;
				}
			}

			// Make sure we always 'fall back' to the lcs syntax
			if (value.library == 'livecode_script')
			{
				tIndex = index;
				// If no library was specified, assume lcs syntax
				if (pPriorityLibrary == '')
				{
					// We're done
					return false;
				}
				
				// Otherwise, this index is now a candidate in case
				// there is no entry found in the given library
			}
			
			if (pPriorityLibrary == '')
			{
				// If no library was specified, this index is a 
				// candidate.
				tIndex = index
				return true;
			}
			else if (value.library.toLowerCase() != pPriorityLibrary)
			{
				// Continue loop
				return true;
			}
			
			// We have a perfect match!
			tIndex = index;
			return false;
		});
		return tIndex;
	}
	
	function entryIdToIndex(pId){
		var tIndex = 0;
	
		$.each(dataGet(), function(index, value) {
			if(value.id == pId){
				tIndex = index;
				return false;
			}
			
		});
		return tIndex;
	}
	
	function breadcrumb_draw()
	{
		var tHistory = tState.history.list;
		
		if (tState.history.selected_index > 0) 
			$('#lcdoc_history_back').removeClass('disabled');
		else
			$('#lcdoc_history_back').addClass('disabled');
		
		if (tState.history.selected_index < tHistory.length - 1) 
			$('#lcdoc_history_forward').removeClass('disabled');
		else
			$('#lcdoc_history_forward').addClass('disabled');
		
		if (tHistory . length <= 1)
		{
			$('#lcdoc_history').addClass('disabled');
			return;
		}
		else
			$('#lcdoc_history').removeClass('disabled');
		
		var tHistoryList = '';	
		$.each(tHistory, function(index, value) 
		{
			if (index == tState.history.selected_index)
				tHistoryList += '<li class="active"><a href="#">';
			else
			{
				tHistoryList += '<li><a href="javascript:void(0)" ';
				tHistoryList += 'class="load_breadcrumb_entry" historyIndex ="'+index+'">';
			}
			tHistoryList += value.name + ' (' + value.type + ')</a></li>';
		});
	
		$("#lcdoc_history_list").html(tHistoryList);
	}
	
	function nonEmptyElement(pObject, pElementName)
	{
		if (!pObject.hasOwnProperty(pElementName))
			return false;
			
		return pObject[pElementName] != '';
	}
	
	function parameterFormatValue(pEntryObject, pData, pSubArray){
		var tHTML = "";
		if (nonEmptyElement(pData, "description"))
		{
			if (pSubArray)
				tHTML += pData.description;
			else
				tHTML += formatMarkdown(pEntryObject, pData.description);
		}
		
		switch(pData.type)
		{
			case "enum":
				if (pData.hasOwnProperty("enum"))
				{
				   tHTML += "<p>One of the following items:</p><ul>";
				   $.each(pData.enum, function(index, value) 
				   {
					   tHTML += '<li><span class="lcdoc_parameterValue">';
					   tHTML += value.value + '</span>';
					   if (nonEmptyElement(value, "description"))
						   tHTML += ' -' + value.description;
					   tHTML += '</li>';
				   });
				   tHTML += "</ul>";
				}
				break;
			case "array":
				if (pData.hasOwnProperty("array"))
				{
				   tHTML += "<p>The array has the following structure:</p><ul>";
				   $.each(pData.array, function(index, value) 
				   {
						tHTML += '<li><span class="lcdoc_parameterValue">';
						tHTML += value.key.name;
						if (nonEmptyElement(value.key, "type"))
					    	tHTML += ' (' + value.key.type + ')';
						tHTML += '</span>';
						if (nonEmptyElement(value.key, "description"))
							tHTML += ' - ' + value.key.description;
						tHTML += '<br>';
						tHTML += '<span class="lcdoc_entry_param">';
						tHTML += value.value.name;
						tHTML += '</span>';
					   	if (nonEmptyElement(value.value, "type"))
					    	tHTML += ' (' + value.value.type + ')';
						if (nonEmptyElement(value.key, "description"))
						{
							tHTML += ' - '
					   		tHTML += parameterFormatValue(pEntryObject, value.value, true);
					   	}
					   	tHTML += '</li>';
				   });
				   tHTML += "</ul>";
				}
				break;
		}

		return tHTML;
	}
	
	function history_selected_entry()
	{
		return tState.history.list[tState.history.selected_index];
	}
	
	function history_add(pEntryObject)
	{
		if (tState.history.selected_index != -1)
		{
			// If this is the currently selected item, don't do anything
			if (history_selected_entry().id == pEntryObject.id)
				return;
		}

		var tObject = {"id":pEntryObject.id,"name":pEntryObject["display name"],"type":pEntryObject.type}
		var tNewHistory = tState . history .list;
		
		// Remove item from history if it is present
		$.each(tNewHistory, function(index, value) 
		{
			if (value.id == tObject.id)
			{
				tNewHistory.splice(index, 1);
				// Exit the loop once we have found and removed the item
				return false;
			}
		});
		
		// Push item onto end of history list
		tNewHistory.push(tObject);
		
		tState.history.list = tNewHistory;
		tState.history.selected_index = tNewHistory . length - 1;
	}
	
	function history_back()
	{
		if(tState.history.selected_index > 0){
			go_history(tState.history.selected_index - 1);
		}
	}
	
	function history_forward()
	{
		if(tState.history.selected_index < tState.history.list.length - 1){
			go_history(tState.history.selected_index + 1);
		}
	}
	
	function go_history(pHistoryID)
	{
		tState.history.selected_index = pHistoryID
		displayEntry(history_selected_entry().id);
	}
	
	function entry_previous()
	{
		var tSelectedID = tState.history.list[tState.history.selected_index].id;
		var tPreviousID = tSelectedID;
		
		if(tState.cached_search_data.hasOwnProperty("term"))
		{
			$.each(tState.cached_search_data.data, function( index, value) {
				if(value.id == tSelectedID){
					if(index > 0){
						tPreviousID = tState.cached_search_data.data[index-1].id;
					}
				}
			});
		}
		else
		{
			$.each(tState.filtered_data, function( index, value) {
				if(value.id == tSelectedID){
					if(index > 0){
						tPreviousID = tState.filtered_data[index-1].id;
					}
				}
			});
		}
		
		displayEntry(tPreviousID);
	}
	
	function entry_next()
	{
		var tSelectedID = tState.history.list[tState.history.selected_index].id;
		var tNextID = tSelectedID;
		
		if(tState.cached_search_data.hasOwnProperty("term"))
		{
			$.each(tState.cached_search_data.data, function( index, value) {
				if(value.id == tSelectedID){
					if(tState.cached_search_data.data[index+1]){
						tNextID = tState.cached_search_data.data[index+1].id;
					}
				}
			});
		}
		else
		{
			$.each(tState.filtered_data, function( index, value) {
				if(value.id == tSelectedID){
					if(tState.filtered_data[index+1]){
						tNextID = tState.filtered_data[index+1].id;
					}
				}
			});
		}
		
		displayEntry(tNextID);
	}
	
	function library_set(pLibraryID){
		var tChooserLabel = library_id_to_name(pLibraryID);

		$("#lcdoc_library_chooser_text").html(tChooserLabel);
	
		if(dictionary_data.docs.hasOwnProperty(pLibraryID))
		{				
			if (tState.selected_api_id != pLibraryID)
			{
				tState.selected_api_id = pLibraryID;
				$.session.set("selected_api_id", pLibraryID);
				var tIndex = 0;
				if (tState.selected_entry_index.hasOwnProperty(pLibraryID))
				{
					tIndex = tState.selected_entry_index[pLibraryID];
				}
				
				tState.history = {list:[], selected_index:-1};
				tState.cached_search_data = {};
				tState.filters= {};
				tState.filtered_data = [];
				tState.data = "";
				tState.selected_entry_index[pLibraryID] = -1;
				
				dataFilter();
				displayEntryAtIndex(tIndex);
			}
		}
	}
	
	function library_id_to_name(pID){
		if(dictionary_data.docs.hasOwnProperty(pID)){
			return dictionary_data.docs[pID]["display name"];
		}
	}
	
	function library_name_to_id(pName){	
		var tID = 0;
		$.each(dictionary_data.docs, function(index, value) {
			if((value.name == pName || value["display name"] == pName)){
				tID = index;
				return false;
			}
			
		});
		return tID;
	}
	
	function selectedEntryEnsureInView(tEntryID)
	{
		var listTop = $("#list").offset().top;
		var listBottom = $("#list").offset().top + $("#list").height();
		
		if($("#entry_list_item_" + tEntryID).length){
			//var elementTop = $("#entry_list_item_" + tEntryID).offset().top;
			//var elementBottom = $("#entry_list_item_" + tEntryID).offset().top + $("#entry_list_item_" + tEntryID).height();
		
			//if(elementBottom > listBottom) $("#list").scrollTop($("#entry_list_item_" + tEntryID));
			//if(elementTop < listTop) $("#list").scrollTop($("#entry_list_item_" + tEntryID));
		}
	} 
	
	function isDefined(pVar)
	{
		return (typeof pVar !== typeof undefined);
	}
	
	function goEntryName(pLibraryName, pEntryName, pEntryType)
	{
		var tLibraryID = library_name_to_id(pLibraryName);
		library_set(tLibraryID);

		var tID;
		if (pEntryName == '')
			tID = 0;
		else
			tID = entryNameToIndex(pEntryName, pEntryType, pLibraryName);
			
		if (isDefined(tID))
		{
			displayEntryAtIndex(tID);
		} 
		else 
		{
			displayEntryListGrep(pEntryName);
		}
	}
	
	function isRunningInLiveCodeBrowser()
	{
		return (typeof liveCode !== 'undefined');
	}
	
	function setEdition(pEdition)
	{
		tState.edition = pEdition;
	}

	// Returns a function, that, as long as it continues to be invoked, will not
	// be triggered. The function will be called after it stops being called for
	// N milliseconds.  Used to make search more responsive.
	var debounce = function(func, wait) {
		var timeout;
		return function() {
			var context = this, args = arguments;
			var later = function() {
				timeout = null;
				func.apply(context, args);
			};
			clearTimeout(timeout);
			timeout = setTimeout(later, wait);
		};
	};
	
	function setActions()
	{	
		breadcrumb_draw();
		
		$("body").on("click", ".upgrade", function() {
			if (isRunningInLiveCodeBrowser())
			{
         	var tEdition = $(this).attr("edition");
				var tDisplayName = $(this).attr("display_name");
				liveCode.showUpgradeOptions(tEdition, tDisplayName);
			}
			else
			{
				window.location.href = 'https://livecode.com/products/livecode-platform/pricing/';
			}
 		});

		// Delay search until 250ms after last character typed
		$('#ui_filer').keyup( debounce( function() {
			displayEntryListGrep(this.value);
			if(tState.cached_search_data.hasOwnProperty("data") && 
			   tState.cached_search_data.data.hasOwnProperty(0))
				displayEntry(tState.cached_search_data.data[0].id);
		}, 250));
		
		$("body").on( "click", ".load_entry", function() {
			var tEntryIndex = $(this).attr("entryindex");
			if (typeof tEntryIndex !== typeof undefined && tEntryIndex !== false) {
				displayEntryAtIndex(tEntryIndex);
			}

			var tEntryId = $(this).attr("entryid");			
			if (typeof tEntryId !== typeof undefined && tEntryId !== false) {
				displayEntry(tEntryId);
			}
		});
		
		$("body").on("click", ".list_sort", function() {
			tState.sort_type = $(this).attr("sortBy");
			dataFilter();
		});
		
		$("body").on( "click", ".load_breadcrumb_entry", function() {
			var tHistoryIndex;
			tHistoryIndex = parseInt($(this).attr("historyIndex"));
			go_history(tHistoryIndex);
		});
		
		$("body").on( "click", ".apply_filter", function() {
			var filter_tag = $(this).attr("filter_category");
			var filter_value = $(this).attr("filter_value");
			var filter_name = $(this).attr("filter_name");
			filter_add(filter_tag,filter_value,filter_name);
		});
		
		$("body").on( "click", ".remove_filter", function() {
			var filter_tag = $(this).attr("filter_category");
			var filter_value = $(this).attr("filter_value");
			var filter_name = $(this).attr("filter_name");
			filter_remove(filter_tag,filter_value,filter_name);
		});
		
		$("body").on( "click", ".external_link", function(e) {
			if (isRunningInLiveCodeBrowser())
			{
				e.preventDefault();
				var tTarget = $(this).attr("href");
				liveCode.linkClicked(tTarget);
			}
		});

		$('#lcdoc_history_forward').on( "click", function() {
			if (!$(this).hasClass('disabled'))
				history_forward();
		});
		
		$('#lcdoc_history_back').on( "click", function() {
			if (!$(this).hasClass('disabled'))
				history_back();
		});
		
		$("body").on( "click", "#table_list", function() {
			$(this).addClass("table_focused");
		});
		
		$(window).on( "click", function(e) {
			if(e.pageX > $("#table_list").offset().left && e.pageX < ($("#table_list").offset().left + $("#table_list").width()) && e.pageY > $("#table_list").offset().top && e.pageY < ($("#table_list").offset().top + $("#table_list").height())) return false;
			$("#table_list").removeClass("table_focused");
		});
		
		$("#lcdoc_library_chooser_list").on( "click", "a", function() {
			var library_id = $(this).attr("library_id");
			var library_name = library_id_to_name(library_id);
			library_set(library_id);
		});

		var $resizer = $('#resizer');
		
		var tResizerMargin;
		tResizerMargin = parseInt($resizer.css('margin'));
		
		function doTableResize()
		{
			var $textarea = $('#header_panel_holder');
			var $window = $(window);
			
			var tWindowHeight;
			tWindowHeight = $window.height();
			
			var tWindowScroll;
			tWindowScroll = $window.scrollTop();
			
			var tHeaderMinHeight;
			tHeaderMinHeight = parseInt($textarea.css('min-height'));
			
			var tTableHeaderHeight;
			tTableHeaderHeight = parseInt($('#table_list_header').css('height'));
			
			$("body").addClass('noselect');
			
			$window.on('mousemove', function (evt) {
				evt.preventDefault();
			
				var tNewHeight;
				tNewHeight = Math.min(evt.pageY - tWindowScroll, tWindowHeight - 20);
				tNewHeight = Math.max(tHeaderMinHeight, tNewHeight);
				
				var tContainerHeight;
				tContainerHeight = tNewHeight - tHeaderMinHeight - tTableHeaderHeight - tResizerMargin + 5;
				$('#table_container').css('height', tContainerHeight);

				if (tContainerHeight < 5)
				{
					$textarea.css('height', tHeaderMinHeight);
					$('#table_header').css('display', 'none');
				}
				else
				{
					$textarea.css('height', tNewHeight);	
					$('#table_header').css('display', '');
				}
				
			});
			
			$window.on('mouseup', function () {
				$("body").removeClass('noselect');
				$window.off('mousemove');
				$window.off('mouseup');
			});
		}
		
		// Catch mousedown on the resizer div and resize header panel
		// holder on mousemove, respecting panel holder's min width
		$('#resizer').on('mousedown', function (event) {
			doTableResize();
		});

		// Prevent mouse scroll on table bubbling to window level
		function preventScrollBubble(pEventTarget, pScrollTarget)
		{	
			pEventTarget.bind('mousewheel', function(e, d)  {
				if (d > 0 && pScrollTarget.scrollTop() === 0) {
					e.preventDefault();
				}
				else {
					var tBottom;
					tBottom = pScrollTarget.get(0).scrollHeight - pScrollTarget.innerHeight();
					if (d < 0 && (pScrollTarget.scrollTop() == tBottom)) {
						e.preventDefault();
					}
				}
			});
		}
		preventScrollBubble($("#lcdoc_list"), $("#table_container"));
		preventScrollBubble($("#filters_panel"), $("#filters_options"));
		
		$(document).keydown(function(e) {
			switch(e.which) {
				case 37: // left
					if(!$("#ui_filer").is(":focus")){
						history_back();
						e.preventDefault();
					}
					break;

				case 38: // up
					if($("#table_list").hasClass("table_focused")){
						entry_previous();
						e.preventDefault();
					}
					break;

				case 39: // right
					if(!$("#ui_filer").is(":focus")){
						history_forward();
						e.preventDefault();
					}
					break;

				case 40: // down
					if($("#table_list").hasClass("table_focused")){
						entry_next();
						e.preventDefault();
					}
					break;

				default: return; // exit this handler for other keys
			}
		
		});
	}
