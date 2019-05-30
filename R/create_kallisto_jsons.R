library(synapser)
library(tidyverse)
library(magrittr)
library(RJSONIO)

synLogin()

parameter_list <- list(
    "kallisto_index_file" = list(
      "path" = "gencode_v24.idx",
      "class" = "File"),
    "synapse_config" = list(
      "path" = ".synapseConfig",
      "class" = "File"),
    "destination_id"= "syn18636519"
)

fastq_df <- "SELECT id, pair, Project, ICGC_Specimen_ID FROM syn18689500" %>% 
    synapser::synTableQuery(includeRowIdAndRowVersion = F) %>% 
    as.data.frame() %>% 
    dplyr::as_tibble() %>% 
    tidyr::spread(key = pair, value = id) %>% 
    magrittr::set_colnames(c("Project", "sample_name_array", "fastq1_ids", "fastq2_ids"))

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
CLLE_dfs <-  purrr::map(list(1:20, 21:40, 41:68), ~dplyr::slice(CLLE_df, .x))
df_to_json(
    CLLE_dfs, 
    c("CLLE-ES1.tsv", "CLLE-ES2.tsv", "CLLE-ES3.tsv"), 
    c("../JSON/Kallisto/CLLE-ES1.json", "../JSON/Kallisto/CLLE-ES2.json", "../JSON/Kallisto/CLLE-ES3.json"))

#PACA-AU

PACA_df <- fastq_df %>% 
    dplyr::filter(Project == "PACA-AU") %>% 
    dplyr::select(-Project)

PACA_dfs <- purrr::map(list(1:25, 26:50, 51:75), ~dplyr::slice(PACA_df, .x))

df_to_json(
    PACA_dfs, 
    c("PACA-AU1.tsv", "PACA-AU2.tsv", "PACA-AU3.tsv"), 
    c("../JSON/Kallisto/PACA-AU1.json", "../JSON/Kallisto/PACA-AU2.json", "../JSON/Kallisto/PACA-AU3.json"))




