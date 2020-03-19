library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")


parameter_list <- list(
    "synapse_config" = list(
        "path" = ".synapseConfig",
        "class" = "File"),
    "synapse_directory_id"= "syn18485876"
)

bam_df <- "syn18684516" %>%
    synapse_file_to_tbl()

uploaded_bam_files <- "select name, id from syn20810012" %>% 
    query_synapse_table() 

uploaded_fastq_files <- "select * from syn18689500" %>% 
    query_synapse_table() 

df_to_json <- function(dfs, output_file_names, json_file_names){
    dfs %>% 
        purrr::map(as.list) %>% 
        purrr::map(c, parameter_list) %>% 
        purrr::map2(output_file_names, ~c(.x, list("output_file_name" = .y))) %>% 
        purrr::map(RJSONIO::toJSON) %>% 
        purrr::walk2(json_file_names, writeLines)
}

df <- uploaded_bam_files %>% 
    dplyr::left_join(bam_df, by = c("name" = "File Name")) %>% 
    dplyr::filter(!`Specimen ID` %in% uploaded_fastq_files$ICGC_Specimen_ID) %>% 
    dplyr::rename(size = `Size (bytes)`) %>% 
    dplyr::arrange(size) %>%
    dplyr::mutate(cum_size = cumsum(size)) %>%
    dplyr::filter(cum_size < 1.5e11) %>%
    dplyr::select(id, name) %>% 
    dplyr::rename(sam_file_id_array = id) %>% 
    dplyr::mutate(
        fastq_name = stringr::str_remove_all(name, ".bam"),
        fastq_r1_name_array = stringr::str_c(fastq_name, "_p1.fastq.gz"),
        fastq_r2_name_array = stringr::str_c(fastq_name, "_p2.fastq.gz")
    ) %>% 
    dplyr::select(sam_file_id_array, fastq_r1_name_array, fastq_r2_name_array) %>% 
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("sam_to_fastq.json")

    


