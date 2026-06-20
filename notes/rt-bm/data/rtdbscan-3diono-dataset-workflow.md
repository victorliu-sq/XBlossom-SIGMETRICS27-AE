# RT-DBSCAN 3DIono Dataset Workflow

## What 3DIono Means

The RT-DBSCAN paper describes `3DIono` as a 3D ionosphere dataset built from:

- latitude
- longitude
- total electron count / total electron content (`TEC`)

The public source is not a ready-made file named `3DIono`. The closest reproducible source is CEDAR Madrigal / OpenMadrigal GNSS TEC data.

## Where To Get The Data

Use the CEDAR OpenMadrigal site:

```text
https://cedar.openmadrigal.org/
```

Navigation:

```text
Access data -> Select single experiment
```

In the instrument category selector, choose:

```text
Distributed Ground Based Satellite Receivers
```

Then select the global GNSS/GPS TEC experiment. The target experiment name looks like:

```text
World-wide TEC from GPS/GLONASS
```

For the file selector, choose the binned TEC HDF5 file:

```text
gps*.hdf5: TEC binned 1 degree by 1 degree by 5 min - final
```

Do not use these for the basic RT-DBSCAN `3DIono` dataset:

```text
los_*.h5     # line-of-sight TEC; larger and rawer
site_*.h5    # site metadata only
roti_*.h5    # ROTI product, not the basic TEC grid
```

The file used locally was:

```text
data/RTDBSCAN/raw/gps260116g.002.hdf5
```

## Required Python Packages

Install HDF5 support in the benchmark conda environment:

```bash
conda install -n rtbm-env -c conda-forge h5py numpy
```

## Preprocess Into RT-DBSCAN Format

Converter:

```text
data/_scripts/RTDBSCAN/preprocess_dataset_3diono.py
```

Run only the 3DIono converter:

```bash
conda run --no-capture-output -n rtbm-env python \
  data/_scripts/RTDBSCAN/preprocess_dataset_3diono.py \
  --input data/RTDBSCAN/raw/gps260116g.002.hdf5 \
  --output data/RTDBSCAN/processed/3DIono.csv
```

The local generated file was:

```text
data/RTDBSCAN/processed/3DIono.csv
```

Observed output:

```text
points: 4,732,018
size:   76 MB
```

`preprocess_datasets.sh` also supports this conversion if the raw HDF5 file exists:

```bash
data/_scripts/RTDBSCAN/preprocess_datasets.sh
```

## Run RT-DBSCAN On 3DIono

The paper uses `3DIono` with:

```text
epsilon / radius = 0.5
minPts = 10
```

Build RT-DBSCAN if needed:

```bash
./expr/benchmark/RT-DBSCAN/build_app.sh
```

Run only `3DIono`:

```bash
mkdir -p tmp/RT-DBSCAN/local-3DIono/logs tmp/RT-DBSCAN/local-3DIono/times

points="$(wc -l < data/RTDBSCAN/processed/3DIono.csv)"

build/rtdbscan/apps/RT-DBSCAN/samples/cmdline/s02-rtdbscan/sample02-rtdbscan \
  data/RTDBSCAN/processed/3DIono.csv \
  "${points}" \
  0.5 \
  10 \
  tmp/RT-DBSCAN/local-3DIono/times/3DIono_times.txt \
  2>&1 | tee tmp/RT-DBSCAN/local-3DIono/logs/3DIono.log
```

Record the result in CSV format:

```bash
expr/benchmark/RT-DBSCAN/write_result_csv.py \
  --result-csv expr/results/local/RT-DBSCAN/3diono_result.csv \
  --log-file tmp/RT-DBSCAN/local-3DIono/logs/3DIono.log \
  --time-file tmp/RT-DBSCAN/local-3DIono/times/3DIono_times.txt \
  --dataset 3DIono \
  --dataset-path data/RTDBSCAN/processed/3DIono.csv \
  --radius 0.5 \
  --min-pts 10 \
  --point-count "${points}" \
  --status ok
```
``
Observed local result:

```text
Build time:       0.031142 s
Core points time: 0.019264 s
Execution time:   0.029137 s
Total time:       0.079543 s
```

Result CSV:

```text
expr/results/local/RT-DBSCAN/3diono_result.csv
```

## Benchmark Role

For the RT-DBSCAN evaluation:

- `3DRoad`: small 2D dataset behavior
- `NGSIM`: dense 2D dataset behavior
- `3DIono`: large/scalability 3D dataset behavior
- `Porto`: also scalability, but very time-consuming

Since Porto can run for more than an hour even before completing, `3DIono` is the practical default scalability dataset for routine runs.
