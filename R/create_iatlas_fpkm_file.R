library(tidyverse)
library(synapser)
library(magrittr)

hugo_translation_id <- "syn11536071"
fpkm_synapse_id     <- "syn18134933"
iatlas_sample_id    <- "syn21785582"
output_file_name    <- "iatlas_fpkm.tsv"

synapser::synLogin()

hugo_translation_tbl <-  hugo_translation_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    data.table::fread() %>% 
    dplyr::as_tibble() %>% 
    dplyr::select(feature = .data$ensembl_gene_id, gene = .data$hgnc_symbol) %>% 
    tidyr::drop_na() %>% 
    dplyr::filter(.data$feature != "", .data$gene != "")

sample_translation_list <- iatlas_sample_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    data.table::fread() %>% 
    dplyr::as_tibble() %>% 
    dplyr::select(.data$aliquot_id, .data$icgc_donor_id) %>% 
    deframe %>% 
    c(., "feature" = "feature")
    
fpkm_synapse_id %>% 
    synapser::synGet() %>% 
    purrr::pluck("path") %>% 
    data.table::fread() %>% 
    dplyr::as_tibble() %>% 
    dplyr::select(dplyr::one_of(c("feature", names(sample_translation_list)))) %>% 
    magrittr::set_colnames(
        ., 
        purrr::map_chr(colnames(.,), ~sample_translation_list[[.x]])
    ) %>% 
    dplyr::mutate(
        feature = stringr::str_remove_all(.data$feature, "\\.[0-9]+$")
    ) %>% 
    dplyr::inner_join(hugo_translation_tbl, by = "feature") %>% 
    dplyr::select(-.data$feature) %>% 
    dplyr::group_by(.data$gene) %>% 
    dplyr::summarise_all(sum) %>% 
    dplyr::ungroup() %>% 
    readr::write_tsv(., output_file_name)

activity_obj <- synapser::Activity(
    name = "Select only samples going into iatlas, and translate to hugo genes",
    used = list(hugo_translation_id, fpkm_synapse_id, iatlas_sample_id),
    executed = paste0(
        "https://github.com/CRI-iAtlas/ICGC/blob/",
        "bf8f628cab977a668f84ea73d22149e5c797a5b2/",
        "R/create_iatlas_fpkm_file.R"
    )
)

output_file_name %>% 
    synapser::File(parent = "syn18268611") %>% 
    synapser::synStore(activity = activity_obj)

file.remove(output_file_name)    
