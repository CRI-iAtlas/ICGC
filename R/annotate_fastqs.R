library(synapser)
library(tidyverse)
library(magrittr)

synLogin()

bam_df <- "syn18684516" %>% 
    synapser::synGet() %>% 
    magrittr::use_series(path) %>% 
    readr::read_tsv() %>% 
    dplyr::select(`File Name`, `ICGC Donor`, `Specimen ID`, `Sample ID`, Project) %>% 
    magrittr::set_colnames(c("BAM", "ICGC_Donor_ID", "ICGC_Specimen_ID", "ICGC_Sample_ID", "Project"))

annotations_df <- "syn18485876" %>% 
    synapser::synGetChildren(includeTypes=list("folder")) %>% 
    synapser::as.list() %>% 
    purrr::map(synapser::synGetChildren, includeTypes=list("file")) %>% 
    purrr::map(synapser::as.list) %>% 
    purrr::flatten() %>% 
    purrr::map(dplyr::as_tibble) %>% 
    dplyr::bind_rows() %>% 
    dplyr::select(id, name) %>% 
    magrittr::set_colnames(c("entity", "FASTQ")) %>% 
    dplyr::mutate(pair = stringr::str_match(FASTQ, "_p([12]).fastq.gz")[,2]) %>% 
    dplyr::mutate(BAM = stringr::str_replace_all(FASTQ, "_p[12].fastq.gz", ".bam")) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::select(-c(FASTQ, BAM)) %>% 
    tidyr::nest(pair, ICGC_Donor_ID, ICGC_Specimen_ID, ICGC_Sample_ID, Project, .key = "annotations")

purrr::pmap(annotations_df, synapser::synSetAnnotations)


    
