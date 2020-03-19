library(tidyverse)
library(synapser)
library(magrittr)

pcawg_synapse_id    <- "syn18234582"
tcga_sample_id      <- "syn18234560"
output_file_name    <- "iatlas_sample_sheet.tsv"

synapser::synLogin()

tcga_sample_ids <- tcga_sample_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    readr::read_tsv(.) %>% 
    dplyr::pull(.data$icgc_sample_id)

pcawg_tbl <- pcawg_synapse_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    readr::read_tsv(.) %>% 
    filter(.data$donor_wgs_exclusion_white_gray == "Whitelist") %>% 
    filter(.data$library_strategy == "RNA-Seq") %>% 
    filter(!.data$aliquot_id %in% tcga_sample_ids) %>% 
    dplyr::filter(
        !stringr::str_detect(.data$dcc_specimen_type, "Normal")
    ) %>%
    dplyr::filter(
        !stringr::str_detect(.data$dcc_specimen_type, "Metastatic")
    ) %>%
    dplyr::mutate(dcc_specimen_type = factor(
        .data$dcc_specimen_type,
        levels = c(
            "Primary tumour - solid tissue",
            "Primary tumour",
            "Primary tumour - blo od derived (bone marrow)",
            "Primary tumour - blood derived (peripheral blood)",
            "Primary tumour - lymph node",
            "Primary tumour - other",
            "Recurrent tumour - solid tissue",
            "Recurrent tumour - other"
        )
    )) %>%
    dplyr::group_by(.data$icgc_donor_id) %>%
    dplyr::arrange(.data$dcc_specimen_type) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>% 
    readr::write_tsv(., output_file_name)

activity_obj <- synapser::Activity(
    name = "select only sampels going into iatlas",
    used = list(pcawg_synapse_id, tcga_sample_id),
    executed = paste0(
        "https://github.com/CRI-iAtlas/ICGC/blob/",
        "7d4532d0510d36dc2720120c8a96d215c8dd510e/",
        "R/create_iatlas_sample_file.R"
    )
)

output_file_name %>% 
    synapser::File(parent = "syn18233789") %>% 
    synapser::synStore(activity = activity_obj)

file.remove(output_file_name)


