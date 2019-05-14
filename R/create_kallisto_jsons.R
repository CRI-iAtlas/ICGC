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

projects <- sort(c("CLLE-ES", "ESAD-UK"))
json_file_names <- stringr::str_c("../JSON/Kallisto/", projects, ".json")
output_file_names <- stringr::str_c(projects, ".tsv")

fastq_df <- 
    synapser::synTableQuery("SELECT id, pair, Project, ICGC_Specimen_ID FROM syn18689500") %>% 
    as.data.frame() %>% 
    dplyr::as_tibble() %>% 
    dplyr::select(-c(ROW_ID, ROW_VERSION, ROW_ETAG)) %>% 
    dplyr::arrange(ICGC_Specimen_ID, pair) %>% 
    dplyr::group_by(Project, ICGC_Specimen_ID) %>% 
    dplyr::rename(sample_name_array = ICGC_Specimen_ID) %>% 
    dplyr::summarise(nested_id_array = list(id)) %>% 
    dplyr::mutate(nested_id_array = map(nested_id_array, as.list)) %>% 
    dplyr::ungroup() 

fastq_df %>% 
    dplyr::group_split(Project) %>% 
    purrr::map(dplyr::select, -Project) %>% 
    purrr::map(as.list) %>% 
    purrr::map(c, parameter_list) %>% 
    purrr::map2(output_file_names, ~c(.x, list("output_file_name" = .y))) %>% 
    purrr::map(RJSONIO::toJSON) %>% 
    purrr::walk2(json_file_names, writeLines)
