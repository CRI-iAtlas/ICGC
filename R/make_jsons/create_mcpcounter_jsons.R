library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

parameter_list <- list(
    "synapse_config" = list(
        "path" = "/home/aelamb/.synapseConfig",
        "class" = "File"),
    "destination_id" = "syn20574581"
)

kallisto_files_tbl <- "select  id, name, ICGC_Sample_ID from syn19955373" %>% 
    query_synapse_table()

mcpcounter_file_samples <- 
    "SELECT ICGC_Sample_ID from syn20583414 where method = 'mcpcounter'" %>% 
    query_synapse_table() %>% 
    dplyr::pull(ICGC_Sample_ID)


kallisto_files_tbl %>% 
    dplyr::filter(!ICGC_Sample_ID %in% mcpcounter_file_samples) %>% 
    tidyr::drop_na() %>% 
    dplyr::select(
        sample_names = ICGC_Sample_ID,
        input_ids = id,
        output_files = name
    ) %>% 
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("mcpcounter.json")




