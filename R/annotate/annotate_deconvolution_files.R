library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

deconvolution_df <- tibble::tribble(
    ~method, ~parent_folder,
    "mcpcounter", "syn20574581",
    "cibersort", "syn20583426",
    "epic", "syn20583464"
)
    
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

result_df <- "SELECT id, name, parentId from syn20583414 where Project is null" %>% 
    query_synapse_table() 

annotations_df <- result_df %>% 
    dplyr::select(entity = id, file = name, parent_folder = parentId) %>% 
    tidyr::separate(
        file, 
        sep = "\\.",
        into = c("ICGC_Specimen_ID"), 
        extra = "drop"
    ) %>% 
    dplyr::left_join(deconvolution_df) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::select(-c(BAM, parent_folder)) %>% 
    tidyr::nest(
        -entity,
        .key = "annotations")

if(nrow(annotations_df) > 0){
    print("Annotating deconvolution")
    purrr::pmap(annotations_df, synapser::synSetAnnotations)
}


    
