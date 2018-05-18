# GAMS
**G**enomic **A**nnotation of **M**etagenomic **S**equences


## Introduction

- Pre-process input reads with cutadapt and fastqc
- (Optionally) Merge overlapping reads with flash
- Analyse pre-processed reads with centrifuge

##Setting up

For running the pipeline you first need to have a working [conda](https://conda.io/docs/index.html) installation.
Most of the steps require the activation of the relevant conda environment, so 
you will have to create them **beforehand**. The requirements files 
can be found in the `envs` directory.

Since this is wdl you will also need cromwell for the execution of the workflows, 
which you can find [here](https://github.com/broadinstitute/cromwell/releases).


## Running the pipeline

Locally:
```
$ java -jar /path/to/cromwell.<version>.jar run pipeline.wdl -i inputs.json 
```

On a cluster (e.g. LUMC's SHARK):
```
$ module load cromwell/31
$ java -Dconfig.file=$CROMWELL_SHARK_CONFIG -jar $CROMWELL_JAR run pipeline.wdl -i INPUTS.json
```
