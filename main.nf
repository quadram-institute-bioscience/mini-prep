#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { MAIN_WORKFLOW } from './workflows/main_workflow'

workflow {
    MAIN_WORKFLOW()
}