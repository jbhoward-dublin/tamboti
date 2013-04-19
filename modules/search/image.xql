xquery version "3.0";

let $image_col := collection('/db/resources/')
let $results := for $id in $image_col//image[@id="i_e71b5fbf-d7ea-41a8-995a-f06d32c1bfc9"]
    return $id
let $result_set := if (not($results)) then <xml>image uuid not found</xml> else ($results)
return $result_set
