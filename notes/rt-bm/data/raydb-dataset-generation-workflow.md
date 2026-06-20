# RayDB Dataset Generation Workflow

Use the repository script to generate RayDB SSB data:

```bash
make raydb-datasets
```

To download a packaged RayDB dataset instead of regenerating it:

```bash
make download-raydb-datasets
```

By default, the generated data is written to:

```text
data/RayDB
```

The script creates or reuses:

```text
data/RayDB/ssb-dbgen
data/RayDB/ssb_data
data/RayDB/monetdb-farm
```

## Requirements

The script expects these commands to be available:

```bash
git
make
gcc
monetdbd
monetdb
mclient
```

## Custom Output Directory

To generate the dataset somewhere else, set `RAYDB_DATA_DIR`:

```bash
RAYDB_DATA_DIR=/path/to/RayDB make raydb-datasets
```

The RayDB-ready data will be placed under:

```text
/path/to/RayDB/ssb_data
```

## Useful Options

Generate with a different SSB scale factor:

```bash
RAYDB_SCALE_FACTOR=20 make raydb-datasets
```

Use an existing MonetDB database without letting the script manage the farm:

```bash
RAYDB_MANAGE_MONETDB=0 make raydb-datasets
```

Skip RayDB preprocessing after CSV export:

```bash
RAYDB_SKIP_PREPROCESS=1 make raydb-datasets
```

## Expected Output

After a complete run, `data/RayDB/ssb_data` should contain per-query folders with RayDB inputs such as:

```text
data.txt
outputfile_rtscan_*.txt
predicate.txt
```

The raw SSB `.tbl` files remain in `data/RayDB/ssb-dbgen`, and MonetDB internal storage remains in `data/RayDB/monetdb-farm`.
