---
layout: default
title: Home
version: develop
latest: true
---

The GAMS (Genomic Annotation of Metagenomic Sequences) pipeline can be used to
process metagenomic data. It performs preprocessing and quality control using
cutadapt and fastqc, optionally merges overlapping reads using flash and
analyses the data using centrifuge.

## Usage
In order to run the complete multisample pipeline, you can
run `pipeline.wdl` using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```bash
java -jar cromwell-<version>.jar run -i inputs.json pipeline.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/). Note that
not some inputs should not be used! See [this page](inputs.md) for more
information.

The primary inputs are described below, additional inputs (such as precommands
and JAR paths) are available. Please use the above mentioned WOMtools command
to see all available inputs.

| field | type | |
|-|-|-|
| sampleConfigFiles | `Array[File]` | The sample configuration file. See more details below. |
| outputDir | `String` | The output directory. |
| sample.centrifugeIndexPrefix | `String` | Prefix of the Centrifuge index. |

>All inputs have to be preceded by `pipeline.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

### Sample configuration
The sample configuration should be a YML file which adheres to the following
structure:
```YML
samples:
  <sample>:
    libraries:
      <library>:
        readgroups:
          <readgroup>:
              R1: <Path to first-end FastQ file.>
              R1_md5: <MD5 checksum of first-end FastQ file.>
              R2: <Path to second-end FastQ file.>
              R2_md5: <MD5 checksum of second-end FastQ file.>
```
Replace the text between `< >` with appropriate values. MD5 values may be
omitted and R2 values may be omitted in the case of single-end data.
Multiple readgroups can be added per library and multiple libraries may be
given per sample.

## Tool versions
Included in the repository is an `environment.yml` file. This file includes
all the tool version on which the workflow was tested. You can use conda and
this file to create an environment with all the correct tools.

## Output
This pipeline will produce a number of directories and files:
- **samples**: Contains a directory per sample.
  - **&lt;sample>**: Contains a folder 'centrifuge', which contains the
  centrifuge output. Also contains a directory per library.
    - **<&lt;library>**: Contains a directory per readgroup.
      - **&lt;readgroup>**: Contains QC metrics and preprocessed FastQ files.

## Contact
<p>
  <!-- Obscure e-mail address for spammers -->
For any question related to this pipeline, please use the
<a href='https://github.com/biowdl/gams/issues'>github issue tracker</a>
or contact
 <a href='http://sasc.lumc.nl/'>the SASC team</a> directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
