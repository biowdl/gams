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
import "QC/QualityReport.wdl" as QualityReport
import "QC/AdapterClipping.wdl" as AdapterClipping
import "tasks/fastqc.wdl" as fastqc
import "tasks/flash.wdl" as flash

workflow readgroup {
    Array[File] sampleConfigs
    String readgroupId
    String libraryId
    String sampleId
    String outputDir
    Boolean? combineReads

    call biopet.SampleConfig as config {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId,
            tsvOutputPath = outputDir + "/" + readgroupId + ".config.tsv",
            keyFilePath = outputDir + "/" + readgroupId + ".config.keys"
    }

    Object configValues = if (defined(config.tsvOutput) && size(config.tsvOutput) > 0)
        then read_map(config.tsvOutput)
        else { "":"" }

    call QualityReport.QualityReport as QreportR1 {
        input:
            read = configValues.R1,
            outputDir = outputDir + "/QC"
    }

    call QualityReport.QualityReport as QreportR2 {
        input:
            read = configValues.R2,
            outputDir = outputDir + "/QC"
    }

    call AdapterClipping.AdapterClipping as clipping {
        input:
            outputDir = outputDir + "/QC",
            read1 = configValues.R1,
            read2 = configValues.R2,
            adapterListRead1 = QreportR1.adapters,
            adapterListRead2 = QreportR2.adapters
    }

    call QualityReport.QualityReport as PostQreportR1 {
        input:
            read = clipping.read1afterClipping,
            outputDir = outputDir + "/QC"
    }

    call QualityReport.QualityReport as PostQreportR2 {
        input:
            read = select_first([clipping.read2afterClipping]),
            outputDir = outputDir + "/post_QC"
    }

    if (select_first([combineReads, false]) == true) {
        call flash.flash as flash {
            input:
                inputR1 = clipping.read1afterClipping,
                inputR2 = select_first([clipping.read2afterClipping]),
                outdirPath = outputDir + "/flash"
            }
    }

    output {
        File? extendedFrags = flash.extendedFrags
        File? notCombinedR1 = flash.notCombined1
        File? notCombinedR2 = flash.notCombined2
        File cleanR1 = clipping.read1afterClipping
        File? cleanR2 = clipping.read2afterClipping
    }
}
