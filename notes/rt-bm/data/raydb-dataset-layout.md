# RayDB Dataset Layout

RayDB dataset generation creates two main directories under `data/RayDB`.

## `data/RayDB/ssb-dbgen`

`ssb-dbgen` is the Star Schema Benchmark data generator workspace.

It contains C source code because `dbgen` is a C program. The script clones and builds that program, then uses it to generate the raw SSB relational tables:

```text
customer.tbl
lineorder.tbl
part.tbl
supplier.tbl
```

These `.tbl` files are generation inputs for MonetDB. RayDB does not directly run on this directory.

## `data/RayDB/ssb_data`

`ssb_data` is the RayDB-ready dataset area.

It stores one subdirectory per SSB query variant, for example:

```text
q1dot1/
q2dot1/
q3dot1/
q4dot3/
```

The generated runtime payloads are:

```text
data.txt
outputfile_rtscan_*.txt
```

The directory also carries small per-query support files copied from `apps/RayDB/ssb_data`, such as:

```text
predicate.txt
*datahandle.cpp
```

The CSV files, raw `.tbl` files, `ssb-dbgen`, and MonetDB farm are generation or preprocessing artifacts. The minimal post-generation RayDB runtime data is the per-query `data.txt`, `outputfile_rtscan_*.txt`, and `predicate.txt`.

## Flow

```text
ssb-dbgen C generator
  -> raw SSB .tbl tables
  -> MonetDB import and lineorder_flat construction
  -> query-specific CSV exports
  -> RayDB preprocessing
  -> ssb_data per-query RayDB inputs
```
