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
import "tasks/biopet.wdl" as biopet
import "tasks/common.wdl" as common

workflow library {
    Array[File] sampleConfigs
    String sampleId
    String libraryId
    String outputDir
    Boolean combineReads

    # Get the readgroup configuration
    call biopet.SampleConfig as config {
        input:
            inputFiles = sampleConfigs,
            sample = sampleId,
            library = libraryId,
            tsvOutputPath = outputDir + "/" + libraryId + ".config.tsv",
            keyFilePath = outputDir + "/" + libraryId + ".config.keys"

        }


    # The jobs that are done per readgroup.
    # Modify readgroup.wdl to change what is happening per readgroup
    scatter (readgroupId in read_lines(config.keysFile)) {
        if (readgroupId != "") {
            call readgroupWorkflow.readgroup as readgroup {
                input:
                    outputDir = outputDir + "/rg_" + readgroupId,
                    sampleConfigs = sampleConfigs,
                    readgroupId = readgroupId,
                    libraryId = libraryId,
                    sampleId = sampleId
            }
        }
    }
    output {
        Array[File] extFrags = select_all(readgroup.extendedFrags)
        Array[File] notCombR1 = select_all(readgroup.notCombinedR1)
        Array[File] notCombR2 = select_all(readgroup.notCombinedR2)
    }
}
