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
			fileInfo,
			//heade definitions
		parent_record,
		upload_folder;
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
			//reader.readAsDataURL(file);
			reader.readAsArrayBuffer(file);
			//reader.readAsBinaryString(file);
			
		}
		
		// Uploading - for Firefox, Google Chrome and Safari
		xhr = new XMLHttpRequest();
		
		// Update progress bar
		xhr.upload.addEventListener("progress", function (evt) {
			if (evt.lengthComputable) {
				progressBar.style.width = (evt.loaded / evt.total) * 100 + "%";
			}
			else {
				
			}
		}, false);
		
		// File uploaded
				
		xhr.addEventListener("load", function () {
			progressBarContainer.className += " uploaded";
			progressBar.innerHTML = "Uploaded!";
		}, false);
		
		xhr.open("post", "simple_upload.xql", true);
		//heade definitions
	    parent_record= $('#upload-resource-id').html();
	    upload_folder = $('#upload-resource-folder').html();
		
		
		// Set headers
		xhr.setRequestHeader("Content-Type", "multipart/form-data");
		//xhr.setRequestHeader("Content-Type", "form-data");
		xhr.setRequestHeader("X-File-Name", file.name);
		xhr.setRequestHeader("X-File-Size", file.size);
		xhr.setRequestHeader("X-File-Type", file.type);
		xhr.setRequestHeader("X-File-Parent", parent_record);
		xhr.setRequestHeader("X-File-Folder", upload_folder);
		
		xhr.responseType = "arraybuffer";
		//xhr.responseType = file.type;
		//xhr.setRequestHeader("Content-Disposition","form-data");
		//xhr.setRequestHeader("Content-Type", file.type);
		//xhr.setRequestHeader('Content-Type', 'application/octet-stream');
		//xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');

		// Send the file (doh)
		//xhr.responseType = 'blob';
		/*
		var data = new ArrayBuffer(text.length);
        var ui8a = new Uint8Array(data, 0);
        for (var i = 0; i < text.length; i++) ui8a[i] = (text.charCodeAt(i) & 0xff);
 
        var bb = new BlobBuilder(); // doesn't exist in Firefox 4
        bb.append(file);
        var blob = bb.getBlob();
        */
        //this.send(blob);
        //var file = new Blob([xhr.response], {type: file.type});
	    //xhr.sendAsBinary(file);	
		 var fd = new FormData();
         fd.append("uploadedFile", file);
        
		xhr.send(fd);
		
		
		
		// Present file info and append it to the list of files
		fileInfo = "<LI id='namewidth'>" + file.name + "</LI>";
		fileInfo += "<LI id='sizewidth'> " + parseInt(file.size / 1024, 10) + " kb</LI>";
		fileInfo += "<LI id='typewidth'> " + file.type + "</LI>";
		div.innerHTML = fileInfo;
		
		fileList.appendChild(li);
	}
	
	// ******************************************************************
	
	
	

    	
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
