hadoopify
=========

An XQuery library to assist with Map-Reduce tasks in MarkLogic.

Utilizes the MarkLogic task sever to process tasks concurrently.
Given a sequence of input data, a map function, and reduce function (optional), 
Hadoopify will slice the input into batches and execute the mapping function on 
each batch of input data.  Each batch is executed in its own process, and the mapping
function is called individually for each item in that batch.  Once all processes
have returned, an optional reduce function will be called on the result sequence.


**Mapping function:**
```xquery
function($item) {
  (: called on each item of the input sequence, returns a result or processing this item :)
  (: don't forget to commit! :)
  xdmp:commit()
}
```

**Reduce function:**
```xquery
function($result, $output) {
  (: called on the results of the mapping function :)
  (: $output contains the results of the previous reduce iterations :)
}
```

**Example:**
A function that calculates the factorial of each input value and sums the results.
```xquery
xquery version "1.0-ml";
import module namespace h = "http://marklogic.com/hadoopify" at "/hadoopify.xqy";

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
```
