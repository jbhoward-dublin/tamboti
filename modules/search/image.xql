xquery version "3.0";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
import module namespace config="http://exist-db.org/mods/config" at "../../modules/config.xqm";


declare variable $col := $config:mods-root;
declare variable $user := 'admin';
declare variable $userpass := '';
(:let $x := system:as-user($user, $userpass,xmldb:reindex($col)):)

let $results :=   collection($col)//vra:work[@id="w_186f5b16-e799-5bb5-b0c6-831575278973"]/vra:relationset/vra:relation
let $images := for $entry in $results
                    return <img src="{$entry/@relids}"/>
     
     
let $result_set := if (not($results)) then <xml>image uuid not found</xml> else ($results)
return <xml>{$results}</xml>

