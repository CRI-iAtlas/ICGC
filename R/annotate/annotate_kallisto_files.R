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

result_df <- "SELECT id, name from syn19955373 where Project is null" %>% 
    query_synapse_table() 

annotations_df <- result_df %>% 
    dplyr::select(entity = id, kallisto_file = name) %>% 
    tidyr::separate(
        kallisto_file, 
        sep = "\\.",
        into = c("ICGC_Specimen_ID"), 
        extra = "drop"
    ) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::select(-BAM) %>% 
    tidyr::nest(
        -entity,
        .key = "annotations")

if(nrow(annotations_df) > 0){
    print("Annotating kallisto")
    purrr::pmap(annotations_df, synapser::synSetAnnotations)
}





    
