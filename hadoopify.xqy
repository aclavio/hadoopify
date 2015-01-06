xquery version "1.0-ml";

module namespace h = "http://marklogic.com/hadoopify";

declare option xdmp:mapping "false";

(:
  Helper library to utilize the MarkLogic task sever to process tasks concurrently.
  Given a sequence of input data, a map function, and reduce function (optional), 
  Hadoopify will slice the input into batches and execute the mapping function on 
  each batch of input data.  Each batch is executed in its own process, and the mapping
  function is called individually for each item in that batch.  Once all processes
  have returned, an optional reduce function will be called on the result sequence.


  Mapping function:
  function($item) {
    (: called on each item of the input sequence, returns a result or processing this item :)
  }

  Reduce function:
  function($result, $output) {
    (: called on the results of the mapping function, $output contains the results of the previous reduce iterations :)
  }

:)

declare function h:hadoopify($data as item()*, 
    $map-function as function(item()*) as item()*,
    $batch-size as xs:integer,
    $is-update as xs:boolean) {
    h:hadoopify($data, $map-function, 
    function($result, $output) {
      ($output, $result)
    }, 
    $batch-size, $is-update)
};

declare function h:hadoopify($data as item()*, 
    $map-function as function(item()*) as item()*,
    $reduce-function as function(item()*, item()*) as item()*,
    $batch-size as xs:integer,
    $is-update as xs:boolean) {
  (: determine the # of groups to make :)
  let $data-size := fn:count($data)
  let $batch-count := fn:ceiling($data-size div $batch-size)
  (: fork :)
  let $results := 
    for $group-num in (1 to $batch-count)
      (: slice the data :)
      let $group-data := fn:subsequence($data, (($group-num - 1) * $batch-size) + 1, $batch-size)
      return
        xdmp:spawn-function(function(){
          (: xdmp:sleep(20000), text { "group #" || $group-num }, :)
          (: do the work on each individual item :)
          let $result :=
            for $d in $group-data
              return $map-function($d)

          let $commit := if ($is-update) then xdmp:commit() else ()

          return $result
        }, 
        <options xmlns="xdmp:eval">
          <result>{fn:true()}</result>
          <transaction-mode>{if ($is-update) then "update" else "query"}</transaction-mode>
        </options>
        )
  (: join :)
  return 
    let $output := ()
      let $reduce :=
        for $result in $results
          return xdmp:set($output, $reduce-function($result, $output))
      return $output
};


(:
Example of a function that calculates the factorial of each input value and sums the results:

h:hadoopify(
  (: our input values :)
  (1, 2, 3, 4, 5, 6),
  (: factorial mapping function :)
  function($num) {
    let $total := 1
    let $_ :=
      for $i in (1 to $num)
        return xdmp:set($total, $total * $i)
    return $total
  },
  (: summing reduce function :)
  function($result, $output) {    
    (if ($output) then xs:integer($output) else 0) + xs:integer($result)
  },
  (: calculate each number individually :)
  1,
  (: this isn't an update function :)
  fn:false()
)
:)