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

import "tasks/biopet.wdl" as biopet
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

    if (defined(readgroup.R1_md5)) {
        call common.CheckFileMD5 as md5CheckR1 {
            input:
                file = readgroup.R1,
                MD5sum = select_first([readgroup.R1_md5])
        }
    }

    if (defined(readgroup.R2_md5) && defined(readgroup.R2)) {
        call common.CheckFileMD5 as md5CheckR2 {
            input:
                file = select_first([readgroup.R2]),
                MD5sum = select_first([readgroup.R2_md5])
        }
    }

    call qcWorkflow.QC as qc {
        input:
            outputDir = readgroupDir,
            read1 = readgroup.R1,
            read2 = readgroup.R2,
            sample = sampleId,
            library = libraryId,
            readgroup = readgroupId
    }

    if (select_first([gamsInputs.combineReads, false])) {
        call flash.Flash as flash {
            input:
                inputR1 = qc.read1afterQC,
                inputR2 = select_first([qc.read2afterQC]),
                outdirPath = readgroupDir + "/flash"
            }
    }

    output {
        File? extendedFrags = flash.extendedFrags
        File? notCombinedR1 = flash.notCombined1
        File? notCombinedR2 = flash.notCombined2
        File cleanR1 = qc.read1afterQC
        File? cleanR2 = qc.read2afterQC
    }
}

