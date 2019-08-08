library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

parameter_list <- list(
    "synapse_config" = list(
        "path" = ".synapseConfig",
        "class" = "File"),
    "destination_id" = "syn20571318"
)

mitcr_files_tbl <- "select ICGC_Sample_ID, id, TCR_chain from syn19956391" %>% 
    query_synapse_table()


mitcr_files_tbl %>%
    tidyr::spread(key = TCR_chain, value = id) %>% 
    dplyr::select(
        sample_names = ICGC_Sample_ID,
        alpha_chain_ids = alpha,
        beta_chain_ids = beta
    ) %>% 
    dplyr::mutate(output_files = stringr::str_c(sample_names, ".json")) %>% 
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("post_mitcr.json")




