library(synapser)
library(tidyverse)
library(magrittr)
library(RJSONIO)

synLogin()

parameter_list <- list(
    "synapse_config" = list(
      "path" = ".synapseConfig",
      "class" = "File"),
    "destination_id"= "syn18638507"
)


fastq_df <- 
    synapser::synTableQuery("SELECT id, pair, Project, ICGC_Specimen_ID FROM syn18689500") %>% 
    as.data.frame() %>% 
    dplyr::as_tibble() %>% 
    dplyr::select(-c(ROW_ID, ROW_VERSION, ROW_ETAG)) %>% 
    tidyr::spread(key = pair, value = id) %>% 
    magrittr::set_colnames(c("Project", "sample_name_array", "p1_fastq_ids", "p2_fastq_ids"))

df_to_json <- function(dfs, output_file_names, json_file_names){
    dfs %>% 
        purrr::map(as.list) %>% 
        purrr::map(c, parameter_list) %>% 
        purrr::map2(output_file_names, ~c(.x, list("output_file_name" = .y))) %>% 
        purrr::map(RJSONIO::toJSON) %>% 
        purrr::walk2(json_file_names, writeLines)
}

#ESAD-UK

ESAD_df <- fastq_df %>% 
    dplyr::filter(Project == "ESAD-UK") %>% 
    dplyr::select(-c(Project, fastq2_ids)) %>% 
    dplyr::rename(fastq_ids = fastq1_ids)
                      
    
df_to_json(list(ESAD_df), "ESAD-UK.tsv" , "../JSON/Kallisto/ESAD-UK.json")

#CLLE-ES

CLLE_df <- fastq_df %>% 
    dplyr::filter(Project == "CLLE-ES") %>% 
    dplyr::select(-Project)
CLLE_dfs <-  purrr::map(list(1:8), ~dplyr::slice(CLLE_df, .x))
df_to_json(
    CLLE_dfs, 
    c("CLLE-ES1.tsv"), 
    c("../JSON/MiTCR/CLLE-ES1.json"))




