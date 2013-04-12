xquery version "3.0";
declare namespace upload = "http://exist-db.org/eXide/upload";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";





declare function upload:upload($rootcollection, $path, $data) {
    let $usercol := xs:string(xmldb:get-current-user())
    let $newcol := concat(xs:string($rootcollection),'/' , $usercol,'/')
    let $upload := 
        system:as-user('admin', '', 
            (
                let $mkdir := if (xmldb:collection-available($newcol)) then()
                
                else
                (
                xmldb:create-collection($rootcollection, $usercol)
                )
                let $upload := xmldb:store($newcol, $path, $data)
                return ()
            )
        )
        return $upload
 };


(:
let $name := xmldb:encode-uri(request:get-uploaded-file-name('file'))
:)
let $name := xmldb:encode(request:get-header('X-File-Name'))  
let $data := request:get-data()

(:
let $collection := uu:escape-collection-path(xmldb:encode-uri(request:get-parameter("collection", ())))
:)

let $rootcollection:='/db/resources/binaries/'

let $upload :=   upload:upload(xmldb:encode-uri($rootcollection), xmldb:encode-uri($name), $data)

return <xml>{$upload}</xml>
