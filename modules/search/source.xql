xquery version "1.0";

(:~ Retrieve the XML source of a MODS record :)

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace clean="http://exist-db.org/xquery/mods/cleanup" at "cleanup.xql";

declare option exist:serialize "method=xml media-type=application/xml indent=yes";

let $id := request:get-parameter("id", ())
let $clean := request:get-parameter("clean", "no")
(: if (by error) several records should have the same id, take the first record. :)
let $data := collection($config:mods-root)//(mods:mods[@ID eq $id][1] | vra:vra/vra:work[@id eq $id][1])
return
    if (empty($data)) 
        then <error>No record found for id: {$id}.</error>
    else
    	if ($clean eq "yes") 
    	then clean:cleanup-for-code-view($data)
    	else
    	   if ($clean eq "soft") 
    	   (:Leaves empty @transliteration.:)
    	   then clean:cleanup($data)
    	   else $data