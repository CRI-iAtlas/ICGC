library(synapser)
library(tidyverse)
library(magrittr)
library(RJSONIO)

synLogin()

paired_parameter_list <- list(
    "synapse_config" = list(
      "path" = ".synapseConfig",
      "class" = "File"),
    "destination_id"= "syn18638507",
    "unpaired_sample_name_array" = list(),
    "unpaired_fastq_id_array" = list()
)

unpaired_parameter_list <- list(
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

paired_df <- fastq_df %>% 
    dplyr::filter(!is.na(p2_fastq_ids)) %>% 
    magrittr::set_colnames(c("Project", "paired_sample_name_array", "p1_fastq_id_array", "p2_fastq_id_array"))

unpaired_df <- fastq_df %>% 
    dplyr::filter(is.na(p2_fastq_ids)) %>% 
    dplyr::select(-p2_fastq_ids) %>% 
    magrittr::set_colnames(c("Project", "unpaired_sample_name_array", "unpaired_fastq_id_array"))


#CLLE-ES

CLLE_df <- paired_df %>% 
    dplyr::filter(Project == "CLLE-ES") %>% 
    dplyr::select(-Project) %>% 
    dplyr::slice(1:15) %>% 
    as.list() %>% 
    c(paired_parameter_list) %>% 
    RJSONIO::toJSON() %>% 
    writeLines("../JSON/MiTCR/CLLE-ES1.json")





