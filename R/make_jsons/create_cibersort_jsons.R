library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

parameter_list <- list(
    "synapse_config" = list(
        "path" = "/home/aelamb/.synapseConfig",
        "class" = "File"),
    "destination_id" = "syn20583426"
)

kallisto_files_tbl <- "select  id, name, ICGC_Specimen_ID from syn19955373" %>% 
    query_synapse_table()

cibersort_file_samples <- 
    "SELECT ICGC_Specimen_ID from syn20583414 where method = 'cibersort'" %>% 
    query_synapse_table() %>% 
    dplyr::pull(ICGC_Specimen_ID)


kallisto_files_tbl %>% 
    dplyr::filter(!ICGC_Specimen_ID %in% cibersort_file_samples) %>% 
    tidyr::drop_na() %>% 
    dplyr::select(
        sample_names = ICGC_Specimen_ID,
        input_ids = id,
        output_files = name
    ) %>% 
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("cibersort.json")




