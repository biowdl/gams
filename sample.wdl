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

import "library.wdl" as libraryWorkflow
import "tasks/biopet.wdl" as biopet
import "tasks/common.wdl" as common
import "tasks/centrifuge.wdl" as centrifuge

workflow sample {
    Array[File] sampleConfigs
    String sampleId
    String outputDir
    Boolean combineReads
    String indexPrefix
    Int? assignments = 5

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

    # This handles the absence of extended fragments when flash is not run
    # The QC'ed pairs are then selected as input for centrifuge
    Array[File]? None # Replace this as soon as there is a literal None

    call centrifuge.Classify as centrifugeClassify {
            input:
                outputDir = outputDir + "/centrifuge",
                indexPrefix = indexPrefix,
                assignments = assignments,

                unpairedReads= if length(select_first(library.libExtendedFrags)) > 0
                                then flatten(select_all(library.libExtendedFrags))
                                else None,

                read1 = if (combineReads == true)
                        then flatten(select_all(library.libNotCombinedR1))
                        else flatten(select_all(library.libCleanR1)),

                read2 = if (combineReads == true)
                        then flatten(select_all(library.libNotCombinedR2))
                        else flatten(select_all(library.libCleanR2))

            }

    # Generate the k-report
    call centrifuge.Kreport as centrifugeKreport {
        input:
            centrifugeOut = centrifugeClassify.classifiedReads,
            outputDir = outputDir + "/centrifuge",
            indexPrefix = indexPrefix,
            inputIsCompressed = true

    }

    # Run the unique kreport generation when the no. of classifications is other than 1
    if (assignments != 1) {
        call centrifuge.Kreport as centrifugeKreportUnique {
            input:
                centrifugeOut = centrifugeClassify.classifiedReads,
                outputDir = outputDir + "/centrifuge",
                indexPrefix = indexPrefix,
                inputIsCompressed = true,
                prefix = "centrifuge_unique",
                onlyUnique = true
        }
    }
<<<<<<< HEAD

    output {
        File centrifugeClassifications = centrifugeClassify.classifiedReads
        File centrifugeReport = centrifugeClassify.reportFile
        File kreport = centrifugeKreport.kreport
        File? kreportUnique = centrifugeKreportUnique.kreport
    }


}
=======
}
>>>>>>> dbbda9c3ce78f19d98762aaefa8b3de9318b5833
