library(synapser)
library(tidyverse)
library(magrittr)

synLogin()

# all donors

bam_df <- "syn18684516" %>%
    synapser::synGet() %>%
    magrittr::use_series(path) %>%
    readr::read_tsv() 

# CLLE-ES 

bam_df %>%
    dplyr::filter(Project == "CLLE-ES") %>% 
    magrittr::use_series(`ICGC Donor`)

# PACA-AU 

uploaded_PACA <- "syn18813591" %>%
    synGetChildren(includeTypes=list("file")) %>%
    synapser::as.list() %>%
    map_chr("name") %>%
    str_remove_all("_p[12].fastq.gz") %>%
    unique %>%
    str_c(., ".bam")

bam_df %>%
    dplyr::filter(Project == "PACA-AU") %>% 
    dplyr::filter(!`File Name` %in% uploaded_PACA) %>% 
    dplyr::slice(1:21) %>% 
    magrittr::use_series(`ICGC Donor`) %>% 
    stringr::str_c(collapse = ", ") 





# df <- "syn18485897" %>% 
#     synGet() %>% 
#     use_series(path) %>% 
#     read_tsv()
# 
# sample_df <- "syn18234560"  %>% 
#     synGet() %>% 
#     use_series(path) %>% 
#     read_tsv()
# 
# tissue_df <- "syn18234574" %>% 
#     synGet() %>% 
#     use_series(path) %>% 
#     read_tsv()
# 
# patient_df <- "syn18234566" %>% 
#     synGet() %>% 
#     use_series(path) %>% 
#     read_tsv()

# files <- "syn18660411" %>% 
#     synGetChildren(includeTypes=list("file")) %>% 
#     synapser::as.list() %>% 
#     map_chr("name") %>% 
#     str_remove_all("_p[12].fastq.gz") %>% 
#     unique %>% 
#     str_c(., ".bam")
# 
# 
# bam_df <- "syn18684516" %>% 
#     synGet() %>% 
#     use_series(path) %>% 
#     read_tsv() %>% 
#     filter(Project == "CLLE-ES") %>% 
#     filter(!`File Name` %in% files) %>% 
#     use_series(`ICGC Donor`)
# 
# x$`File Name` %in% files

