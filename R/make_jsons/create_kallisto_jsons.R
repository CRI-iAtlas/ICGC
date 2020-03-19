library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

parameter_list <- list(
    "kallisto_index_file" = list(
        "path" = "gencode_v24.idx",
        "class" = "File"),
    "synapse_config" = list(
        "path" = ".synapseConfig",
        "class" = "File"),
    "destination_id"= "syn19955258"
)

uploaded_samples <- "select name, id from syn19955373" %>% 
    query_synapse_table() %>%  
    dplyr::mutate(sample_name = stringr::str_remove_all(name, ".tsv")) %>% 
    magrittr::use_series(sample_name)

bam_df <- "syn18684516" %>%
    synapse_file_to_tbl() %>% 
    dplyr::select(
        "bam_size" = `Size (bytes)`,
        "sample_names" = `Specimen ID`
    ) 

fastq_df <- 
    "SELECT id, pair, Project, ICGC_Specimen_ID, createdOn FROM syn18689500" %>%
    query_synapse_table() %>%  
    tidyr::drop_na() %>% 
    dplyr::group_by(Project, ICGC_Specimen_ID) %>% 
    dplyr::mutate(createdOn = max(createdOn)) %>% 
    dplyr::ungroup() %>% 
    tidyr::spread(key = pair, value = id) %>% 
    magrittr::set_colnames(c("Project", "sample_names", "created", "fastq1_ids", "fastq2_ids")) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::filter(!sample_names %in% uploaded_samples) 

df_to_json <- function(dfs, output_file_names, json_file_names){
    dfs %>% 
        purrr::map(as.list) %>% 
        purrr::map(c, parameter_list) %>% 
        purrr::map2(output_file_names, ~c(.x, list("output_file_name" = .y))) %>% 
        purrr::map(RJSONIO::toJSON) %>% 
        purrr::walk2(json_file_names, writeLines)
}

# ESAD-UK

fastq_df %>%
    dplyr::filter(Project == "ESAD-UK") %>%
    dplyr::mutate(cum_size = cumsum(bam_size)) %>%
    dplyr::filter(cum_size < 2.0e11) %>%
    dplyr::rename(fastq_ids = fastq1_ids) %>% 
    dplyr::select(-c(fastq2_ids, Project, bam_size, cum_size, created)) %>%
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("ESAD.json")


# not ESAD-UK

fastq_df %>%
    dplyr::filter(Project != "ESAD-UK") %>%
    dplyr::mutate(cum_size = cumsum(bam_size)) %>%
    dplyr::filter(cum_size < 1.5e11) %>%
    dplyr::select(-c(Project, bam_size, cum_size, created)) %>%
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("kallisto.json")




