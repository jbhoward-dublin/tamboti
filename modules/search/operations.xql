xquery version "1.0";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace group = "http://commons/sharing/group";
declare namespace op="http://exist-db.org/xquery/biblio/operations";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com"; 

declare variable $HTTP-FORBIDDEN := 403;

declare function functx:substring-after-last($arg as xs:string?, $delim as xs:string)as xs:string {       
   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;

declare function functx:escape-for-regex($arg as xs:string?) as xs:string {       
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
 



(:~
: Creates a collection inside a parent collection
:
: The new collection inherits the owner, group and permissions of the parent
:
: @param $parent the parent collection container
: @param $name the name for the new collection
:)
declare function op:create-collection($parent as xs:string, $name as xs:string) as element(status) {
    
        let $collection := xmldb:create-collection($parent, uu:escape-collection-path($name)),
        
        (: just the owner has full access - to start with :)
        $null := sm:chmod(xs:anyURI($collection), "rwx--x---"),
        
        (:
        if this collection was created
        inside a different users collection,
        allow the owner of the parent collection access 
        :)
        $null := security:grant-parent-owner-access-if-foreign-collection($collection) return
        
            <status id="created">{uu:unescape-collection-path($collection)}</status>
};

declare function op:move-collection($collection as xs:string, $to-collection as xs:string) as element(status) {
    let $to-collection := uu:escape-collection-path($to-collection) return
        let $null := xmldb:move($collection, $to-collection) return
        
            (:
            if this collection was created
            inside a different users collection,
            allow the owner of the parent collection access 
            :)
            let $null := security:grant-parent-owner-access-if-foreign-collection($to-collection) return
        
                <status id="moved" from="{uu:unescape-collection-path($collection)}">{$to-collection}</status>
};

declare function op:rename-collection($path as xs:string, $name as xs:string) as element(status) {
    let $null := xmldb:rename($path, $name) return
        <status id="renamed" from="{uu:unescape-collection-path($path)}">{$name}</status>
};

declare function op:remove-collection($collection as xs:string) as element(status) {
    (:Only allow deletion of a collection if none of the records in it are referred to in xlinks outside the collection itself.:)
    (:Get the ids of the records in the collection that the user wants to delete.:)
    let $collection-ids := collection($collection)//@ID
    (:Get the ids of the records that are linked to the records in the collection that the user wants to delete.:)
    let $xlinked-rec-ids :=
        string-join(
        for $collection-id in $collection-ids
            let $xlink := concat('#', $collection-id)
            let $xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href eq $xlink]/ancestor::mods:mods/@ID
            return
                (:It is OK to delete a record using an ID as an xlink if the record is inside the folder to be deleted.:)
                if (not($xlink-recs = $collection-ids))
                then $xlink-recs
                else ''
                (:This should return '' for each iteration for deletion to proceed.:)
                ,'')
    let $null := 
         (:If $xlinked-rec-ids is not empty, do not delete.:)
         if ($xlinked-rec-ids)
         then ()
         else xmldb:remove($collection) 
             return
            <status id="removed">{uu:unescape-collection-path($collection)}</status>
};

(:~
:
: @ resource-id is the @ID of the MODS record
:)
declare function op:remove-resource($resource-id as xs:string) as element(status) {
    let $doc := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id]
    let $xlink := concat('#', $resource-id)
    let $xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href eq $xlink]
    return (
        (:do not remove records which erroneously have the same ID:)
        (:NB: inform user that this is the case:)
        if (count($doc) eq 1)
        then
            (:do not remove records which are linked to from other records:)
            (:NB: inform user that this is the case:)
            if (count($xlink-recs/..) eq 0) 
            then
                    xmldb:remove(util:collection-name($doc), util:document-name($doc))
            else ()
        else()
        ,
        <status id="removed">{$resource-id}</status>
    )
};

(:~
:
: @ resource-id is the @ID of the MODS record
:)
declare function op:move-resource($resource-id as xs:string, $destination-collection as xs:string) as element(status) {
    let $doc := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id]
    let $path := base-uri($doc)
    let $destination-collection := uu:escape-collection-path($destination-collection)
        return
            (:do not move records which erroneously have the same ID:)
            if (count($doc) eq 1)
            then
                let $moved := xmldb:move(util:collection-name($doc), $destination-collection, util:document-name($doc))
                return
                    let $null := security:apply-parent-collection-permissions(document-uri(root($doc))) 
                        return
                            <status id="moved" from="{$resource-id}">{$destination-collection}</status>
            else ()
};

declare function op:set-ace-writeable($collection as xs:anyURI, $id as xs:int, $is-writeable as xs:boolean) as element(status) {
  
    if(sharing:set-collection-ace-writeable($collection, $id, $is-writeable))then  
        <status id="ace">updated</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
};

declare function op:remove-ace($collection as xs:anyURI, $id as xs:int) as element(status) {
    
    if(sharing:remove-collection-ace($collection, $id))then
        <status id="ace">removed</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
};

declare function op:add-user-ace($collection as xs:anyURI, $username as xs:string) as element(status) {

    if(sharing:add-collection-user-ace($collection, $username))then
        <status id="ace">added</status>
    else (
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
};

declare function op:add-group-ace($collection as xs:anyURI, $groupname as xs:string) as element(status) {
    
    if(sharing:add-collection-group-ace($collection, $groupname))then
        <status id="ace">added</status>
    else (
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
};

declare function op:is-valid-user-for-share($username as xs:string) as element(status) {
    if(sharing:is-valid-user-for-share($username))then
        <status id="user">valid</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="user">invalid</status>
    )
};

declare function op:get-move-folder-list($collection as xs:anyURI) as element(select) {
    <select>{
        for $collection-path in (security:get-home-collection-uri(security:get-user-credential-from-session()[1]), sharing:get-shared-collection-roots(true())) return
            if($collection-path ne $collection)then
            (
                <option value="{uu:unescape-collection-path($collection-path)}">{uu:unescape-collection-path($collection-path)}</option>
            )
            else()
    }</select>
};

declare function op:get-move-resource-list($collection as xs:anyURI) as element(select) {
    op:get-move-folder-list($collection)
};

declare function op:is-valid-group-for-share($groupname as xs:string) as element(status) {
    if(sharing:is-valid-group-for-share($groupname))then
        <status id="group">valid</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="group">invalid</status>
    )
};

declare function op:unknown-action($action as xs:string) {
        response:set-status-code($HTTP-FORBIDDEN),
        <p>Unknown action: {$action}.</p>
};


declare function op:upload($collection, $path, $data) {
    let $upload := 
        (: authenticate as the user account set in the app's repo.xml, since we need write permissions to
         : upload the file.  then set the uploaded file's permissions to allow guest/world to delete the file 
         : for the purposes of the demo :)
        system:as-user('admin', '', 
            (
            let $mkdir := if (xmldb:collection-available($collection)) then() else ()
            let $upload := xmldb:store($collection, $path, $data)
            let $chmod := sm:chmod(xs:anyURI($upload), 'o+rw')
            return ()
            )
        )
    return ()
 };
 
 
 
    
declare function op:upload-file($name, $data ,$collection) {
 op:upload(xmldb:encode-uri($collection), xmldb:encode-uri($name), $data)
  
};

let $action := request:get-parameter("action", ()),
$collection := uu:escape-collection-path(request:get-parameter("collection", ()))
return
    if($action eq "create-collection")then
        op:create-collection($collection, request:get-parameter("name",()))
    else if($action eq "move-collection")then
        op:move-collection($collection, request:get-parameter("path",()))
    else if($action eq "rename-collection")then
        op:rename-collection($collection, request:get-parameter("name",()))
    else if($action eq "remove-collection")then
        op:remove-collection($collection)
    else if($action eq "remove-resource")then
        op:remove-resource(request:get-parameter("resource",()))
    else if($action eq "move-resource")then
        op:move-resource(request:get-parameter("resource",()), request:get-parameter("path",()))
    else if($action eq "set-ace-writeable")then
        op:set-ace-writeable(xs:anyURI($collection), xs:int(request:get-parameter("id",())), xs:boolean(request:get-parameter("is-writeable", false())))
    else if($action eq "remove-ace")then
        op:remove-ace(xs:anyURI($collection), xs:int(request:get-parameter("id",())))
    else if($action eq "add-user-ace")then
        op:add-user-ace(xs:anyURI($collection), request:get-parameter("username",()))
    else if($action eq "is-valid-user-for-share")then
        op:is-valid-user-for-share(request:get-parameter("username",()))
    else if($action eq "add-group-ace")then
        op:add-group-ace(xs:anyURI($collection), request:get-parameter("groupname",()))
    else if($action eq "is-valid-group-for-share")then
        op:is-valid-group-for-share(request:get-parameter("groupname",()))
    else if($action eq "get-move-folder-list")then
        op:get-move-folder-list($collection)
     else if($action eq "get-move-resource-list")then
        op:get-move-resource-list($collection)
     else if($action eq "upload-file") then
        let $name := request:get-uploaded-file-name('files[]')
        let $data := request:get-uploaded-file-data('files[]')
        return
         op:upload-file($name,$data,$collection)
        
     else
        op:unknown-action($action)
