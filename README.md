hadoopify
=========

An XQuery library to assist with Map-Reduce tasks in MarkLogic.

Utilizes the MarkLogic task sever to process tasks concurrently.
Given a sequence of input data, a map function, and reduce function (optional), 
Hadoopify will slice the input into batches and execute the mapping function on 
each batch of input data.  Each batch is executed in its own process, and the mapping
function is called individually for each item in that batch.  Once all processes
have returned, an optional reduce function will be called on the result sequence.


Mapping function:
```
function($item) {
  (: called on each item of the input sequence, returns a result or processing this item :)
  (: don't forget to commit! :)
  xdmp:commit()
}
```

Reduce function:
```
function($result, $output) {
  (: called on the results of the mapping function, $output contains the results of the previous reduce iterations :)
}
```
