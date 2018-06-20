# GAMS
**G**enomic **A**nnotation of **M**etagenomic **S**equences


## Introduction

- Pre-process input reads with cutadapt and report with fastqc
- (Optionally) Merge overlapping reads with flash
- Analyse pre-processed reads with centrifuge

## Setting up

1. For running the pipeline you first need to have a working [conda](https://conda.io/docs/index.html) installation.
Most of the calls require the activation of the relevant conda environment, so 
you will have to create them **beforehand**. The `requirements.yml` files 
can be found in the `envs` directory.

2. Some [biopet tools](https://github.com/biopet/tools). Latest versions recommended:
    1. [SampleConfig](https://github.com/biopet/sampleconfig/releases)
    2. [ExtractAdaptersFastqc](https://github.com/biopet/extractadaptersfastqc/releases)
  
3. Since this is wdl you will also need cromwell for the execution of the (sub)-workflows, 
which you can find [here](https://github.com/broadinstitute/cromwell/releases).


## Running the pipeline

Locally:
```
$ java -jar /path/to/cromwell.<version>.jar run pipeline.wdl -i inputs.json 
```

On a cluster:
```
$ java -Dconfig.file=/path/to/cluster.config \
  -jar /path/to/cromwell.<version>.jar \
  run pipeline.wdl -i inputs.json 
```

For shark users:
```
$ module load cromwell/31
$ java -Dconfig.file=$CROMWELL_SHARK_CONFIG -jar $CROMWELL_JAR run pipeline.wdl -i INPUTS.json
```
