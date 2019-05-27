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

annotations_df <- "SELECT * from syn18689500" %>% 
    synapser::synTableQuery(includeRowIdAndRowVersion = F) %>% 
    as.data.frame() %>% 
    dplyr::as_tibble() 

unnanoted_df <- annotations_df %>% 
    dplyr::filter(is.na(Project)) %>% 
    dplyr::select(id, name) %>% 
    magrittr::set_colnames(c("entity", "FASTQ")) %>% 
    dplyr::mutate(pair = stringr::str_match(FASTQ, "_p([12]).fastq.gz")[,2]) %>% 
    dplyr::mutate(BAM = stringr::str_replace_all(FASTQ, "_p[12].fastq.gz", ".bam")) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::select(-c(FASTQ, BAM)) %>% 
    tidyr::nest(pair, ICGC_Donor_ID, ICGC_Specimen_ID, ICGC_Sample_ID, Project, .key = "annotations")

purrr::pmap(unnanoted_df, synapser::synSetAnnotations)


    
