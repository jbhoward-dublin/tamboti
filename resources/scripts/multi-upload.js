(function () {
	var 
		dropArea = document.getElementById("drop-area"),
		fileList = document.getElementById("file-list");
		//filesUpload = document.getElementById("files-upload"),
		
	function uploadFile (file) {
		var li = document.createElement("ul"),
		    div = document.createElement("div"),
		      img,
			progressBarContainer = document.createElement("div"),
			progressBar = document.createElement("div"),
			reader,
			xhr,
			fileInfo;
			
		
		div.position='absolute';
		li.appendChild(div);
		
		progressBarContainer.className = "progress-bar-container";
		progressBar.className = "progress-bar";
		progressBarContainer.appendChild(progressBar);
		li.appendChild(progressBarContainer);
		
		/*
			If the file is an image and the web browser supports FileReader,
			present a preview in the file list
		*/
		if (typeof FileReader !== "undefined" && (/image/i).test(file.type)) {
			img = document.createElement("img");
			img.width='30';
			img.maxWidth='40';
		    img.align='right';
		    imgli = document.createElement("div");
		    //imgli.className = "progress-bar-container uploaded";
		    
		    imgli.appendChild(img);
			li.appendChild(imgli);
			reader = new FileReader();
			reader.onload = (function (theImg) {
				return function (evt) {
					theImg.src = evt.target.result;
				};
			}(img));
			reader.readAsDataURL(file);
		}
		
		// Uploading - for Firefox, Google Chrome and Safari
		xhr = new XMLHttpRequest();
		
		// Update progress bar
		xhr.upload.addEventListener("progress", function (evt) {
			if (evt.lengthComputable) {
				progressBar.style.width = (evt.loaded / evt.total) * 100 + "%";
			}
			else {
				// No data to calculate on
			}
		}, false);
		
		// File uploaded
		
		xhr.addEventListener("load", function () {
			progressBarContainer.className += " uploaded";
			progressBar.innerHTML = "Uploaded!";
		}, false);
		
		xhr.open("post", "simple_upload.xql", true);
		
		// Set appropriate headers
		xhr.setRequestHeader("Content-Type", "multipart/form-data");
		xhr.setRequestHeader("X-File-Name", file.name);
		xhr.setRequestHeader("X-File-Size", file.size);
		xhr.setRequestHeader("X-File-Type", file.type);

		// Send the file (doh)
		xhr.send(file);
		
		// Present file info and append it to the list of files
		fileInfo = "<LI id='namewidth'>" + file.name + "</LI>";
		fileInfo += "<LI id='sizewidth'> " + parseInt(file.size / 1024, 10) + " kb</LI>";
		fileInfo += "<LI id='typewidth'> " + file.type + "</LI>";
		div.innerHTML = fileInfo;
		
		fileList.appendChild(li);
	}
	
	// ******************************************************************
	
		
    function prepareattachedFilesDetails() {
    
        //add reloadAjax function
        $.fn.dataTableExt.oApi.fnReloadAjax = dataTableReloadAjax;
    
        //initialise with initial data
        $('#attachedFilesDetails').dataTable({
            "bProcessing": true,
            "sPaginationType": "full_numbers",
            "fnRowCallback": attachedFilesDetailsRowCallback,
            "sAjaxSource": "sharing.xql"
        });
    };
    
    //called each time the collection/folder sharing dialog is opened
    function updateSharingDialog() {
       $('#attachedFilesDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(getCurrentCollection()));
    }
    
    //custom fnReloadAjax for sharing dataTable
    function dataTableReloadAjax(oSettings, sNewSource, fnCallback, bStandingRedraw) {
        if(typeof sNewSource != 'undefined' && sNewSource != null) {
            oSettings.sAjaxSource = sNewSource;
        }
    
        this.oApi._fnProcessingDisplay(oSettings, true);
    
        var that = this;
        var iStart = oSettings._iDisplayStart;
    
        oSettings.fnServerData(oSettings.sAjaxSource, [], function(json) {
    
            /* Clear the old information from the table */
            that.oApi._fnClearTable(oSettings);
            
            /* Got the data - add it to the table */
            for(var i = 0 ; i < json.aaData.length; i++) {
                that.oApi._fnAddData(oSettings, json.aaData[i]);
            }
    
            oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
            that.fnDraw();
            
            if(typeof bStandingRedraw != 'undefined' && bStandingRedraw === true) {
    			oSettings._iDisplayStart = iStart;
    			that.fnDraw(false);
    		}
            
            that.oApi._fnProcessingDisplay(oSettings, false);
    
            /* Callback user function - for event handlers etc */
            if(typeof fnCallback == 'function' && fnCallback != null){
                fnCallback(oSettings);
            }
        }, oSettings);
    }
    
    //custom rendered for each row of the sharing dataTable
    function attachedFilesDetailsRowCallback(nRow, aData, iDisplayIndex) {
        //determine user or group icon for first column
        if(aData[0] == "USER") {
            $('td:eq(0)', nRow).html('<img alt="User Icon" src="theme/images/user.png"/>');
        } else if(aData[0] == "GROUP") {
            $('td:eq(0)', nRow).html('<img alt="Group Icon" src="theme/images/group.png"/>');
        }
            
        //determine writeable for fourth column
        var isWriteable = aData[3].indexOf("w") > -1;
        //add the checkbox, with action to perform an update on the server
        var inpWriteableId = 'inpWriteable_' + iDisplayIndex;
        $('td:eq(3)', nRow).html('<input id="' + inpWriteableId + '" type="checkbox" value="true"' + (isWriteable ? ' checked="checked"' : '') + ' onclick="javascript: setAceWriteable(this,\'' + getCurrentCollection() + '\',' + iDisplayIndex + ', this.checked);"/>');
        
        //add a delete button, with action to perform an update on the server
        var imgDeleteId = 'imgDelete_' + iDisplayIndex;
        $('td:eq(4)', nRow).html('<img id="' + imgDeleteId + '" alt="Delete Icon" src="theme/images/cross.png" onclick="javascript: removeAce(\'' + getCurrentCollection() + '\',' + iDisplayIndex + ');"/>');
        //add jQuery cick action to image to perform an update on the server
        
        return nRow;
    }
    
    //sets an ACE on a share to writeable or not
    function setAceWriteable(checkbox, collection, aceId, isWriteable) {
        $.ajax({
            type: 'GET',
            url: "operations.xql",
            data: "action=set-ace-writeable&collection=" + escape(collection) + "&id=" + aceId + "&is-writeable=" + isWriteable,
            success: function(data, status, xhr) {
                //do nothing
            },
            error: function(xhr, status, error) {
                alert("Could not modify entry");
                checkbox.checked = !isWriteable;
            }
        });
    };
    
    //removes an ACE from a share
    function removeAce(collection, aceId) {
        if(confirm("Are you sure you wish to remove this entry?")){
            $.ajax({
                type: 'GET',
                url: "operations.xql",
                data: "action=remove-ace&collection=" + escape(collection) + "&id=" + aceId,
                success: function(data, status, xhr) {
                    //remove from dataTable
                    $('#attachedFilesDetails').dataTable().fnDeleteRow(aceId);
                },
                error: function(xhr, status, error) {
                    alert("Could not remove entry");
                    checkbox.checked = !isWriteable;
                }
            });
        }
    };
    
    //adds a user to a share
    function addUserToShare() {
        //1) check this is a valid user otherwise show error
        $.ajax({
                type: 'GET',
                url: "operations.xql",
                data: "action=is-valid-user-for-share&username=" + escape($('#user-auto-list').val()),
                success: function(data, status, xhr) {
                
                    //2) create the ace on the server
                    $.ajax({
                        type: 'GET',
                        url: "operations.xql",
                        data: "action=add-user-ace&collection=" + escape(getCurrentCollection()) + "&username=" + escape($('#user-auto-list').val()),
                        success: function(data, status, xhr) {
                            
                            //3) add the row to the dataTable
                            $('#attachedFilesDetails').dataTable().fnAddData( [
                                "USER",
                                $('#user-auto-list').val(),
                                "ALLOWED",
                                "r--",
                                "removeMe"
                            ]);
                
                            //4) close the dialog
                            $('#add-user-to-share-dialog').dialog('close');
                        },
                        error: function(xhr, status, error) {
                            alert("Could not create entry");
                        }
                    });
                },
                error: function(xhr, status, error) {
                    alert("The user '" + $('#user-auto-list').val() + "' does not exist!");
                }
            });
    };
    
    //adds a group to a share
    function addProjectToShare() {
        //1) check this is a valid group otherwise show error
        $.ajax({
                type: 'GET',
                url: "operations.xql",
                data: "action=is-valid-group-for-share&groupname=" + escape($('#project-auto-list').val()),
                success: function(data, status, xhr) {
                
                    //2) create the ace on the server
                    $.ajax({
                        type: 'GET',
                        url: "operations.xql",
                        data: "action=add-group-ace&collection=" + escape(getCurrentCollection()) + "&groupname=" + escape($('#project-auto-list').val()),
                        success: function(data, status, xhr) {
                            
                            //3) add the row to the dataTable
                            $('#attachedFilesDetails').dataTable().fnAddData( [
                                "GROUP",
                                $('#project-auto-list').val(),
                                "ALLOWED",
                                "r--",
                                "removeMe"
                            ]);
                
                            //4) close the dialog
                            $('#add-project-to-share-dialog').dialog('close');
                        },
                        error: function(xhr, status, error) {
                            alert("Could not create entry");
                        }
                    });
                },
                error: function(xhr, status, error) {
                    alert("The project '" + $('#project-auto-list').val() + "' does not exist!");
                }
            });
    };
    
    	
    	
	//*********************************************************************
	
	function traverseFiles (files) {
		if (typeof files !== "undefined") {
			for (var i=0, l=files.length; i<l; i++) {
				uploadFile(files[i]);
			}
		}
		else {
			fileList.innerHTML = "No support for the File API in this web browser";
		}	
	}
	/**
	filesUpload.addEventListener("change", function () {
		traverseFiles(this.files);
	}, false);
	*/
	
	dropArea.addEventListener("dragleave", function (evt) {
		var target = evt.target;
		
		if (target && target === dropArea) {
			this.className = "";
		}
		evt.preventDefault();
		evt.stopPropagation();
	}, false);
	
	dropArea.addEventListener("dragenter", function (evt) {
		this.className = "over";
		evt.preventDefault();
		evt.stopPropagation();
	}, false);
	
	dropArea.addEventListener("dragover", function (evt) {
		evt.preventDefault();
		evt.stopPropagation();
	}, false);
	
	dropArea.addEventListener("drop", function (evt) {
		traverseFiles(evt.dataTransfer.files);
		this.className = "";
		evt.preventDefault();
		evt.stopPropagation();
	}, false);										
})();
