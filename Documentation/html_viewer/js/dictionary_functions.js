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
		tState.selected_api_id = 1;
	}

	if ($.session.get("selected_entry_index")) {
		var tIndexArray = $.session.get("selected_entry_index");
		tState.selected_entry_index[tState.selected_api_id] = tIndexArray[tState.selected_api_id];
	} else { 
		tState.selected_entry_index[tState.selected_api_id] = 1;
	}
	
	library_set(tState.selected_api_id);

	function dataGet() {		
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

	// Return all the syntax associated with an entry
	// as a (matchable) string
	function collectSyntax(pEntry)
	{
		var tSyntax = '';
		$.each(pEntry["display syntax"], function (index, value) 
		{
			if (tSyntax != '')
				tSyntax += ' ';
				
			tSyntax += value;
		});
		return tSyntax;
	}
	
	// Return a list of matched search terms
	function dataSearch(pTerm)
	{
		// Check the cached search data
		if (tState.cached_search_data.hasOwnProperty("term") && tState.cached_search_data.term == pTerm) 
			return tState.cached_search_data.data;
			
		tState.cached_search_data.term = pTerm;
		tState.cached_search_data.data = [];
		
		// Get a list of space-delimited search terms				
   		var tokensOfTerm = pTerm.match(/\S+/g);	
		
		// Generate two regexes - one that matches all syntax that 
		// contains each search term, and one that matches all syntax that
		// contains a word beginning with each search term. This way we 
		// can prioritise matches that start with the search terms.
    	var matchExp = '';
    	var priorityMatch = '';
    	$.each(tokensOfTerm, function(index, matchToken)
    	{
       		matchExp += '(?=.*' + matchToken + ')';
       		priorityMatch += '(?=.*\\b' + matchToken + ')';
   		});

		var regex = new RegExp(matchExp, "i");
		var priorityRegex = new RegExp(priorityMatch, "i");
		
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
			var tToMatch = collectSyntax(a);		
			if (priorityRegex.test(tToMatch))
				return -1;
			
			tToMatch = collectSyntax(b);
			if (priorityRegex.test(tToMatch))
				return 1;
				
			return 0;
		});
	
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
								if(entryData[category] == tag_value){
									tFound_data[category]++;
								 }
								break;
							case "platforms":
							case "OS":
							case "tags":
							case "associations":
								if(entryData.hasOwnProperty(category)){
									$.each(entryData[category], function(item_index, entry_item_value){
										if(tag_value == entry_item_value){
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


	function filterOptions(pCategories){
		var tFilterOptionWithCount = {}
		var tShowCatogories = pCategories.split(',');
		$.each(tShowCatogories, function(index, category_name) {
			tFilterOptionWithCount[category_name] = {}
		});
		
		$.each(tState.filtered_data, function(entry_index, entry_data) {
			$.each(tShowCatogories, function(category_index, category_name) {
				// If the category is already being filtered on then don't count
				if(!tState.filters.hasOwnProperty(category_name)){
					if(entry_data[category_name]){
						var tTagData = entry_data[category_name];
		
						if(Array.isArray(tTagData)){
							// Data is an array meaning there are multiple values. I.e. multiple tags / platforms to check.
							$.each(tTagData, function( tag, tag_value) {
								if(tFilterOptionWithCount[category_name].hasOwnProperty(tag_value)){
									tFilterOptionWithCount[category_name][tag_value]++;
								} else {
									tFilterOptionWithCount[category_name][tag_value] = 1;
								}
							});
						} else {
							if(tFilterOptionWithCount[category_name].hasOwnProperty(tTagData)){
								tFilterOptionWithCount[category_name][tTagData]++;
							} else {
								tFilterOptionWithCount[category_name][tTagData] = 1;
							}
						}
					}
				}
			});
		});
		return tFilterOptionWithCount;
	}
	
	function filter_remove(pTag,pData){
		if(tState.filters.hasOwnProperty(pTag)){
			$.each(tState.filters[pTag], function(index, data) {
				if(data==pData){
					tState.filters[pTag].splice(index, 1)
					if(tState.filters[pTag].length == 0){
						delete tState.filters[pTag];
					}
					return false;
				}
			});
		}
		dataFilter();
	}
	
	function filter_add(pTag,pData){
		if(!tState.filters.hasOwnProperty(pTag)) tState.filters[pTag] = [];
		
		if(tState.filters[pTag].indexOf(pData) == -1){
			tState.filters[pTag].push(pData);
			dataFilter();
		}
	}
	
	function sortedKeys(obj)
	{
		return Object.keys(obj).sort();
	}
	
	function filter_cell(pCategory, pValue)
	{
		var tHTML = '';
		tHTML += '<td><a href="#" class="apply_filter" ';
		tHTML += 'filter_category="'+pCategory+'" ';
		tHTML += 'filter_value="'+pValue+'">';
		tHTML += pValue;
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
			if (!tState.filters.hasOwnProperty(index) || 
				tState.filters[pCategory].indexOf(value) == 0)
				tDisplayedFilters.push(value);
		});
		
		// Display them in alphabetical order going down the table,
		// rather than across
		var tRowCount = Math.ceil(tDisplayedFilters.length / 2);
		var tOddNumber = tDisplayedFilters.length % 2 == 1;
		for (i = 1; i <= tRowCount; i++)
		{
			tHTML += '<tr>'
			tHTML += filter_cell(pCategory, tDisplayedFilters[i-1]);
			if (i != tRowCount || !tOddNumber)
				tHTML += filter_cell(pCategory, tDisplayedFilters[i - 1 + tRowCount]);
			tHTML += '</tr>';
		}
		tHTML += '</tbody>';
		
		return tHTML;
	}
	
	function displayFilters(){
		// First display the applied filters
		var tHTML = "";
		$.each(tState.filters, function(filter_tag, filter_data) 
		{
			tHTML += '<div style="margin-bottom:10px">';
			tHTML += '<b>'+filter_tag+':</b> ';
			$.each(filter_data, function(index, filter_name) 
			{
				tHTML += '<button type="button" ';
				tHTML += 'class="btn btn-default btn-sm remove_filter" ';
				tHTML += 'filter_tag="'+filter_tag+'" ';
				tHTML += 'filter_data="'+filter_name+'">';
				tHTML += filter_name;
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
		else
			tData = tState . filtered_data;
		
		sortFilteredData(tData);
		
		var tHTML;
		tHTML = data_table_html(tData);

		$("#table_list").html(tHTML);
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
							tIndex = entryNameToIndex(reference_name, reference_type);
							if (tIndex == 0)
								tReference = reference_name;
							else
								tReference = click_text_from_index(reference_name, tIndex);
							
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
					var tSyntaxHTML = "";
					tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';	
					if($.isArray(value)){
						$.each(value, function(index2, value2) {
							tHTML += '<pre><code>' + remove_link_placeholders(value2) + '</code></pre>';
						});
					} else {
						tSyntaxHTML += 'Malformed syntax in JSON';	
					}
					tHTML += tSyntaxHTML;
					tHTML += '</div>';
					break;
				case "associations":
					if($.isArray(value)){
						tHTML += '<div class="col-md-2 lcdoc_section_title">'+index+'</div><div class="col-md-10" style="margin-bottom:10px">';
						var association_html = "";
						$.each(value, function(index2, value2) {
							var tTypes, tType;
							tTypes = ["object","library","glossary"];
							
							var tIndex;
							$.each(tTypes, function(tTypeIndex, tType) {
								tIndex = entryNameToIndex(value2, tType)
								if (tIndex != 0)
									return;
							});
							
							var tAssociation;
							if (tIndex == 0)
								tAssociation = value2;
							else
								tAssociation = click_text_from_index(value2, tIndex);
							
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

		// Now that the entry has been displayed we need to look at the type
		// If it is object, we need to generate a list of actions / events and properties
		// That can be set on the object. The entry if you like should be a pointer to 
		// Everything associated with the object. A cross between a overview and userguide
		
		if(tEntryObject.type == "object" || tEntryObject.type == "widget" || tEntryObject.type == "library"){
			var object_name = tEntryObject["display name"].toLowerCase();
			var object_data = {};
			
			$.each(dataGet(),function(entry_index, entry_data){
				if(entry_data.hasOwnProperty("associations")){
					if(entry_data["associations"].indexOf(object_name) >= 0){
						if(!object_data.hasOwnProperty(entry_data.type)){
							object_data[entry_data.type] = [];
						}
						object_data[entry_data.type].push(entry_data);
					}
				}
			});
			
			$.each(object_data,function(item_type, item_data){
				tHTML += '<div class="col-md-2 lcdoc_section_title">'+item_type+'</div><div class="col-md-10" style="margin-bottom:10px">';
				tHTML += '<table class="lcdoc_glossary_table">';
				tHTML += '<thead><tr><td><b>Name</b></td><td><b>Summary</b></td><td><b>Syntax</b></td></tr></thead><tbody>';
				$.each(item_data,function(item_intex, entry_data){
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
             		
             		var resolved_id = resolve_link(pEntryObject, resolved[1], resolved[2]);
             		
             		if (resolved_id != 0)
             	   		return_text = click_text(resolved[0], resolved_id)
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
        var entry_id;
        if(pTargetType){
	        // Know name and type so lookup id
             entry_id = entryNameToIndex(pTargetName,pTargetType);
        } else {
        	// Work out the type from the reference
			if(pEntryObject.hasOwnProperty("references")) {
				$.each(pEntryObject.references,  function(reference_type, reference_array) {
					$.each(reference_array, function(reference_index, reference_name) {
						if (reference_name == pTargetName)
						{
							entry_id = entryNameToIndex(reference_name,reference_type);
							return;
						}
					});
					// Just find the first one if no type was specified.
					if (entry_id)
						return;
				});
			}
        }
	        
	    return entry_id;
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
	
	function entryNameToIndex(pName,pType){
		var tIndex = 0;
	
		$.each(dataGet(), function(index, value) {
			if((value.name == pName || value["display name"] == pName) && value.type == pType){
				tIndex = index;
				return false;
			}
			
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
		go_history(tState.history.selected_index - 1);
	}
	
	function history_forward()
	{
		go_history(tState.history.selected_index + 1);
	}
	
	function go_history(pHistoryID)
	{
		tState.history.selected_index = pHistoryID
		displayEntry(history_selected_entry().id);
	}
	
	function entry_next(){
		var tSelectedID = tState.selected;
		var tNextID = tSelectedID;
		
		$.each(tState.filtered_data, function( index, value) {
			if(value.id == tSelectedID){
				if(tState.filtered_data[index+1]){
					tNextID = tState.filtered_data[index+1].id;
				}
			}
			
		});
		displayEntry(tNextID);
	}
	
	function library_set(pLibraryID){
		var tChooserLabel = 'Choose API: ';
		tChooserLabel += library_id_to_name(pLibraryID);

		$("#lcdoc_library_chooser_text").html(tChooserLabel);
	
		if(dictionary_data.docs.hasOwnProperty(pLibraryID))
		{				
			if (tState.selected_api_id != pLibraryID)
			{
				tState.selected_api_id = pLibraryID;
				$.session.set("selected_api_id", pLibraryID);
				var tIndex = 1;
				if (tState.selected_entry_index.hasOwnProperty(pLibraryID))
				{
					tIndex = tState.selected_entry_index[pLibraryID];
				}
				
				tState.history = {list:[], selected_index:-1};
				tState.cached_search_data = {};
				tState.filters= {};
				tState.filtered_data = [];
				tState.data = "";
				tState.selected_entry_index[pLibraryID] = "";
				
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
	
	function entry_previous(){
		var tSelectedID = tState.selected;
		var tPreviousID = tSelectedID;
		
		$.each(tState.filtered_data, function( index, value) {
			if(value.id == tSelectedID){
				if(index > 0){
					tPreviousID = tState.filtered_data[index-1].id;
				}
			}
			
		});
		displayEntry(tPreviousID);
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
	
	function goEntryName(pLibraryName, pEntryName, pEntryType)
	{
		var tLibraryID = library_name_to_id(pLibraryName);
		library_set(tLibraryID);
		
		var tID = entryNameToIndex(pEntryName, pEntryType);
		if (tID == 0)
			tID = 1;
		displayEntryAtIndex(tID);
	}
	
	function isRunningInLiveCodeBrowser()
	{
		return (typeof liveCode !== 'undefined');
	}
	
	function setEdition(pEdition)
	{
		tState.edition = pEdition;
	}
	
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

		$('#ui_filer').keyup(function() {
		  displayEntryListGrep(this.value);
		  if(tState.cached_search_data.data.hasOwnProperty(0))
		  	   displayEntry(tState.cached_search_data.data[0]["id"]);
		})

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
			var filter_data = $(this).attr("filter_value");
			filter_add(filter_tag,filter_data);
		});
		
		$("body").on( "click", ".remove_filter", function() {
			var filter_tag = $(this).attr("filter_tag");
			var filter_data = $(this).attr("filter_data");
			filter_remove(filter_tag,filter_data);
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
		
		function update_lcdoc_margin()
		{			
			var tHeaderHeight;
			tHeaderHeight = parseInt($('#header_panel_holder').css('height'));
			
			$('#lcdoc_body').css('margin-top', tHeaderHeight + 20);
		}
		
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
				tContainerHeight = tNewHeight - tHeaderMinHeight - tTableHeaderHeight - tResizerMargin;
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
				
				update_lcdoc_margin();
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
		
		update_lcdoc_margin();
		
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
