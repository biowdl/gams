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

import "tasks/biopet/biopet.wdl" as biopet
import "QC/QC.wdl" as qcWorkflow
import "tasks/fastqc.wdl" as fastqc
import "tasks/flash.wdl" as flash
import "tasks/common.wdl" as common
import "structs.wdl" as structs

workflow Readgroup {
    input {
        Readgroup readgroup
        Library library
        Sample sample
        String readgroupDir
        GamsInputs gamsInputs
    }

    # FIXME: workaround for namepace issue in cromwell
    String sampleId = sample.id
    String libraryId = library.id
    String readgroupId = readgroup.id

    call qcWorkflow.QC as qc {
        input:
            outputDir = readgroupDir,
            reads = readgroup.reads,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId
    }

    if (select_first([gamsInputs.combineReads, false])) {
        call flash.Flash as flash {
            input:
                inputFastq = qc.readsAfterQC,
                outdirPath = readgroupDir + "/flash"
            }
    }

    output {
        File? extendedFrags = flash.extendedFrags
        FastqPair? notCombined = flash.notCombined
        FastqPair cleanReads = qc.readsAfterQC
    }
}

