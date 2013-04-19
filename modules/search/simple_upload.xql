xquery version "3.0";
(: author dulip withanage :)
declare namespace upload = "http://exist-db.org/eXide/upload";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";
declare namespace functx = "http://www.functx.com";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare variable $rootcollection:='/db/resources/binaries';
declare variable $usercol := xs:string(xmldb:get-current-user());
declare variable $newcol := concat(xs:string($rootcollection),'/' , $usercol,'/');
declare variable $user := 'admin';
declare variable $userpass := '';
declare variable $myuuid := concat('i_',util:uuid());




declare function functx:substring-before-last 
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
       
   if (matches($arg, functx:escape-for-regex($delim)))
   then replace($arg,
            concat('^(.*)', functx:escape-for-regex($delim),'.*'),
            '$1')
   else ''
 } ;
 

declare function upload:list-data(){
(:let $directory-list :=    system:as-user('admin', '', xmldb:get-child-collections()($newcol)):)
let $directory-list :=    system:as-user($user, $userpass,file:directory-list($newcol,'*.*'))
return  $directory-list
};

 declare function functx:escape-for-regex 
  ( $arg as xs:string? )  as xs:string {
       
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;
 

 declare function functx:substring-after-last 
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
       
   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;
 
 
declare function upload:generate-object($size,  $mimetype,$uuid, $title, $file-uuid,$doc-type,$workrecord)
{
let $vra-content := <vra xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
                 <image id="{$uuid}" source="Tamboti" refid="#" href="{$file-uuid}">
                     <titleSet><display/><title type="generalView">
                     {$title}</title></titleSet>  
                     <relationset>
             <relation type="imageOf" relids="{$workrecord}" refid="" source="Tamboti">attachment</relation>
                </relationset>
             </image> </vra>    


let $digital-object :=
<digitalObject xmlns="info:fedora/fedora-system:def/foxml#"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="info:fedora/fedora-system:def/foxml# file:/home/withanage/tamboti/tamboti-git/tamboti/resources/schemas/foxml1-1.xsd" VERSION="1.1" PID="0:0" FEDORA_URI="http://tamboti.uni-hd.de">
    <objectProperties>
        <property NAME="info:fedora/fedora-system:def/model#state" VALUE="VALUE1"/>
        <extproperty NAME="{$uuid}" VALUE="xxxx"/>
    </objectProperties>
    <datastream ID="{$doc-type}" CONTROL_GROUP="E" FEDORA_URI="http://tamboti.uni-hd.de"
         STATE="A" VERSIONABLE="true">
        <datastreamVersion ID="{$uuid}" LABEL="" CREATED="{fn:current-dateTime()}" MIMETYPE="{$mimetype}"
              FORMAT_URI="" SIZE="{$size}">
            <contentDigest TYPE="MD5" DIGEST="DIGEST1"/>
            <xmlContent>
              
                 </xmlContent>
        </datastreamVersion>
      </datastream>
   </digitalObject>
   
 let $out-put:= if ($doc-type eq 'vra') then
        $vra-content 
    else(
   
    )
  
  return $out-put
 };  


declare function upload:upload( $filetype , $filesize, $rootcollection, $filename, $data, $doc-type, $workrecord) {
    
    
    let $upload := 
        system:as-user($user, $userpass, 
            (
                let $mkdir := if (xmldb:collection-available($newcol)) then()
                (:
                dbutil:scan-resources($collection as xs:anyURI, $func as function) as item()*
                :)
                
                else
                (
                xmldb:create-collection($rootcollection, $usercol)
                )
                (: update the xml object  :)
                
                let $file-uuid := concat($myuuid, '.',functx:substring-after-last($filename,'.'))
                let $xml-object := upload:generate-object($filesize, $filetype,$myuuid, $filename, $file-uuid,$doc-type,$workrecord)
                (:save the xml file:)
                 let $upload := xmldb:store($newcol, concat($myuuid,'.xml'), $xml-object)
                let $upload := xmldb:store($newcol, $file-uuid, $data)
                return $upload
            )
        )
        return $upload
 };
 
 declare function upload:add-tag-to-parent-doc($parentdoc_path){
 
 let $vra_insert := <vra:relation type="imageIs" relids="{$myuuid}" source="Tamboti" refid="" >general view</vra:relation>
 let $parentdoc := doc($parentdoc_path)
 let $relationTag := $parentdoc/vra:vra/vra:work/vra:relationset
 return
let $insert_or_updata := 
if (not($relationTag))
    then( 
         update insert  <vra:relationset></vra:relationset> into $parentdoc/vra:vra/vra:work
        )
    else()
        
  let $vra-update := update insert  $vra_insert into $parentdoc/vra:vra/vra:work/vra:relationset
 return  $vra-update
 };
 

let $filename := xmldb:encode(request:get-header('X-File-Name'))  
let $filesize := xmldb:encode(request:get-header('X-File-Size'))
let $filetype := xmldb:encode(request:get-header('X-File-Type'))
let $workrecord := xmldb:encode(request:get-header('X-File-Parent'))
let $filefolder := xmldb:encode(request:get-header('X-File-Folder'))
let $data := request:get-data()


let $parentdoc_path := concat($filefolder,'/',$workrecord,'.xml')
let $tag-changed := upload:add-tag-to-parent-doc($parentdoc_path)


let $mydata := upload:list-data()

(: type control:)
let $doc-type := if (contains($filetype,'png') or contains($filetype, 'jpg') or contains($filetype,'gif') or contains ($filetype,'tif')
or contains($filetype,'PNG') or contains($filetype, 'JPG') or contains($filetype,'GIF') or contains ($filetype,'TIF') or   
 contains ($filetype,'jpeg'))
 then ( 'vra')
else()

let $file-uploaded:= upload:upload($filetype, $filesize, xmldb:encode-uri($rootcollection), xmldb:encode-uri($filename), $data, $doc-type,$workrecord)


return
<xml>{$tag-changed}</xml>

 
