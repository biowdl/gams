# Copyright (c) 2018 Sequencing Analysis Support Core - Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import "tasks/biopet.wdl" as biopet
import "QC/QC.wdl" as QC
import "tasks/fastqc.wdl" as fastqc
import "tasks/flash.wdl" as flash

workflow readgroup {
    Array[File] sampleConfigs
    String readgroupId
    String libraryId
    String sampleId
    String outputDir
    Boolean combineReads

    call biopet.SampleConfig as config {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId,
            tsvOutputPath = outputDir + "/" +readgroupId + ".config.tsv",
            keyFilePath = outputDir + "/" + readgroupId + ".config.keys"
    }

    Object configValues = if (defined(config.tsvOutput) && size(config.tsvOutput) > 0)
        then read_map(config.tsvOutput)
        else { "":"" }

    call QC.QC as qcRaw {
        input:
            outputDir = outputDir + "/QC",
            read1 = configValues.R1,
            read2 = configValues.R2

    }

    # Call fastqc on the processed reads
    call fastqc.fastqc as fastqcProcessedR1 {
        input:
            seqFile = qcRaw.read1afterQC,
            outdirPath = outputDir + "/QC_processed/R1"
    }

    call fastqc.fastqc as fastqcProcessedR2 {
        input:
            seqFile = select_first([qcRaw.read2afterQC]),
            outdirPath = outputDir + "/QC_processed/R2"
    }

    if (combineReads){
        call flash.flash as flash {
            input:
                inputR1 = qcRaw.read1afterQC,
                inputR2 = select_first([qcRaw.read2afterQC]),
                outdirPath = outputDir + "/flash"
            }

        output {
            File extendedFrags = outputDir + "/flash/flash.extendedFrags.fastq.gz"
            File notCombinedR1 = outputDir + "/flash/flash.notCombined_1.fastq.gz"
            File notCombinedR2 = outputDir + "/flash/flash.notCombined_2.fastq.gz"
        }
    }

    output {
        File cleanR1 = qcRaw.read1afterQC
        File cleanR2 = select_first([qcRaw.read2afterQC])
    }
}
