library(tidyverse)
library(synapser)
library(magrittr)

pcawg_synapse_id    <- "syn18234582"
tcga_sample_id      <- "syn18234560"

synapser::synLogin()

tcga_sample_ids <- tcga_sample_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    readr::read_tsv() %>% 
    dplyr::pull(icgc_sample_id)

pcawg_tbl <- pcawg_synapse_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    readr::read_tsv() %>% 
    filter(donor_wgs_exclusion_white_gray == "Whitelist") %>% 
    filter(library_strategy == "RNA-Seq") %>% 
    filter(!aliquot_id %in% tcga_sample_ids) %>% 
    dplyr::filter(!stringr::str_detect(dcc_specimen_type, "Normal")) %>%
    dplyr::filter(!stringr::str_detect(dcc_specimen_type, "Metastatic")) %>%
    dplyr::mutate(dcc_specimen_type = factor(
        dcc_specimen_type,
        levels = c(
            "Primary tumour - solid tissue",
            "Primary tumour",
            "Primary tumour - blood derived (bone marrow)",
            "Primary tumour - blood derived (peripheral blood)",
            "Primary tumour - lymph node",
            "Primary tumour - other",
            "Recurrent tumour - solid tissue",
            "Recurrent tumour - other"
        )
    )) %>%
    dplyr::group_by(icgc_donor_id) %>%
    dplyr::arrange(dcc_specimen_type) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>% 
    readr::write_tsv("iatlas_sample_sheet.csv")

"iatlas_sample_sheet.csv" %>% 
    synapser::File(parent = "syn18233789") %>% 
    synapser::synStore()



