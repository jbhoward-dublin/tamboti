xquery version "3.0";
declare namespace upload = "http://exist-db.org/eXide/upload";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";

let $name := request:get-uploaded-file-name('file')
let $data := request:get-uploaded-file-data('file')
(:
let $data := request:get-parameter('file','none')
:)

let $collection := uu:escape-collection-path(request:get-parameter("collection", ()))

let $upload :=   system:as-user('admin', '', (xmldb:store($collection, $name, $data)))


return <xml>{$upload}</xml>
