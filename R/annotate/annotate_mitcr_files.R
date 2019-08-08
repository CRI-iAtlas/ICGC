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

result_df <- "SELECT * from syn19956391" %>% 
    query_synapse_table() 

annotations_df <- result_df %>% 
    dplyr::filter(is.na(Project)) %>%
    dplyr::select(entity = id, mitcr_file = name) %>% 
    tidyr::separate(
        mitcr_file, 
        sep = "_",
        into = c("ICGC_Specimen_ID", "TCR_chain"), 
        extra = "drop"
    ) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::select(-BAM) %>% 
    tidyr::nest(
        -entity,
        .key = "annotations")

if(nrow(annotations_df) > 0){
    print("Annotating mitcr")
    purrr::pmap(annotations_df, synapser::synSetAnnotations)
}


    
