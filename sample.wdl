version 1.0

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
import "structs.wdl" as structs

workflow Sample {

    input {
        Sample sample
        String sampleDir
        GamsInputs gamsInputs
    }

    scatter (lb in sample.libraries) {
        call libraryWorkflow.Library as library {
            input:
                libraryDir = sampleDir + "/lib_" + lb.id,
                library = lb,
                sample = sample,
                gamsInputs = gamsInputs
        }
    }

    # This handles the absence of extended fragments when flash is not run
    # The QC'ed pairs are then selected as input for centrifuge
    #Array[File]? None # Replace this as soon as there is a literal None

    Boolean combine = select_first([gamsInputs.combineReads, false])

    call centrifuge.Classify as centrifugeClassify {
        input:
            outputDir = sampleDir + "/centrifuge",
            indexPrefix = gamsInputs.centrifugeIndexPrefix,
            assignments = gamsInputs.assignments,
            unpairedReads = if (combine == true) then flatten(library.libExtendedFrags) else [],
            read1 = if (combine == true) then flatten(library.libNotCombinedR1) else flatten(library.libCleanR1),
            read2 = if (combine == true) then flatten(library.libNotCombinedR2) else flatten(library.libCleanR2)
    }

    # Generate the k-report
    # FIXME: Disabled kreport because of bug in centrifuge
#    call centrifuge.Kreport as centrifugeKreport {
#        input:
#            centrifugeOut = centrifugeClassify.classifiedReads,
#            outputDir = sampleDir + "/centrifuge",
#            indexPrefix = gamsInputs.centrifugeIndexPrefix,
#            inputIsCompressed = true
#
#    }

    output {
        File centrifugeClassifications = centrifugeClassify.classifiedReads
        File centrifugeReport = centrifugeClassify.reportFile
#        File kreport = centrifugeKreport.kreport
    }

}


