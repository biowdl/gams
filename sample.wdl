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

import "readgroup.wdl" as readgroupWorkflow
import "library.wdl" as libraryWorkflow
import "tasks/biopet.wdl" as biopet
import "tasks/centrifuge.wdl" as centrifuge
import "tasks/common.wdl" as common

workflow sample {
    Array[File] sampleConfigs
    String sampleId
    String outputDir
    String indexPrefix

    # Get the library configuration
    call biopet.SampleConfig as config {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            jsonOutputPath = outputDir + "/" + sampleId + ".config.json",
            tsvOutputPath = outputDir + "/" + sampleId + ".config.tsv",
            keyFilePath = outputDir + "/" + sampleId + ".config.keys"
    }

    # Do the work per library.
    # Modify library.wdl to change what is happening per library.
    scatter (libraryId in read_lines(config.keysFile)) {
        if (libraryId != "") {
            call libraryWorkflow.library as library {
                input:
                    outputDir = outputDir + "/lib_" + libraryId,
                    sampleConfigs = sampleConfigs,
                    libraryId = libraryId,
                    sampleId = sampleId
            }
        }
    }

    # Do the per sample work and the work over all the library
    # results below this line.

    output {
        Array[String] libraries = read_lines(config.keysFile)
        }

    call common.concatenateTextFiles as catFrags {
        input:
            fileList = select_first(library.extFrags),
            combinedFilePath = outputDir + "/extendedFrags.fastq.gz",
            unzip=true,
            zip=true
    }

    call common.concatenateTextFiles as catR1 {
        input:
            fileList = select_first(library.notCombR1),
            combinedFilePath = outputDir + "/notCombined_R1.fastq.gz",
            unzip=true,
            zip=true
    }

    call common.concatenateTextFiles as catR2 {
        input:
            fileList = select_first(library.notCombR2),
            combinedFilePath = outputDir + "/notCombined_R2.fastq.gz",
            unzip=true,
            zip=true
    }

    call centrifuge.classify as centrifugeClassify {
        input:
            read1 = catR1.combinedFile,
            read2 = catR2.combinedFile,
            unpairedReads = catFrags.combinedFile,
            outputDir = outputDir + "/centrifuge",
            indexPrefix = indexPrefix
    }

    call centrifuge.kreport as centrifugeKreport {
        input:
            centrifugeOut=centrifugeClassify.classifiedReads,
            inputIsCompressed=true,
            indexPrefix=indexPrefix
    }
}}