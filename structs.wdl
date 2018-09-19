version 1.0

import "tasks/bwa.wdl" as bwa
import "tasks/common.wdl" as common

struct Readgroup {
    String id
    FastqPair reads
}

struct Library {
    String id
    Array[Readgroup]+ readgroups
}

struct Sample {
    String id
    Array[Library]+ libraries
}

struct Root {
    Array[Sample] samples
}

struct GamsInputs {
    Boolean? combineReads
    String centrifugeIndexPrefix
    Int? assignments
}