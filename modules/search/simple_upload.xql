xquery version "3.0";
declare namespace upload = "http://exist-db.org/eXide/upload";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";
(:
let $name := xmldb:encode-uri(request:get-uploaded-file-name('file'))
:)
let $name := xmldb:encode(request:get-header('X-File-Name'))  
let $data := request:get-data()
(:
let $collection := uu:escape-collection-path(xmldb:encode-uri(request:get-parameter("collection", ())))
:)
let $collection:='/db/resources/users/editor/upload/'

let $upload :=   system:as-user('admin', '', (xmldb:store($collection, $name, $data)))



return <xml>{$upload}</xml>
