library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")
    
bam_df <- "syn18684516" %>% 
    synapse_file_to_tbl() %>%  
    dplyr::select(
        `File Name`,
        `ICGC Donor`,
        `Specimen ID`,
        `Sample ID`,
        Project
    ) %>% 
    magrittr::set_colnames(c(
        "BAM", 
        "ICGC_Donor_ID", 
        "ICGC_Specimen_ID", 
        "ICGC_Sample_ID", 
        "Project"
    ))

result_df <- "SELECT * from syn18689500" %>% 
    query_synapse_table() 

annotations_df <- result_df %>% 
    dplyr::filter(is.na(Project)) %>% 
    dplyr::select(id, name) %>% 
    magrittr::set_colnames(c("entity", "FASTQ")) %>% 
    dplyr::mutate(pair = stringr::str_match(
        FASTQ, "_p([12]).fastq.gz")[,2]) %>% 
    dplyr::mutate(BAM = stringr::str_replace_all(
        FASTQ, "_p[12].fastq.gz", ".bam")) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::select(-c(FASTQ, BAM)) %>% 
    tidyr::nest(
        pair,
        ICGC_Donor_ID,
        ICGC_Specimen_ID,
        ICGC_Sample_ID,
        Project,
        .key = "annotations")

if(nrow(annotations_df) > 0){
    print("Annotating fastq")
    purrr::pmap(annotations_df, synapser::synSetAnnotations)
}



    
