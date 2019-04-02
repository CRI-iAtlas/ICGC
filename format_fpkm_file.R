library(tidyverse)
library(synapser)
library(magrittr)

hugo_translation_id <- "syn11536071"
fpkm_synapse_id     <- "syn18134933"
pcawg_synapse_id    <- "syn18234582"
tcga_sample_id      <- "syn18234560"

# functions ------------------
create_df_from_synapse_id <- function(syn_id, location = NULL, unzip = F, ...){
    path <- download_from_synapse(syn_id, location)
    if(unzip) path <- stringr::str_c("zcat < ", path)
    path %>% 
        data.table::fread(...) %>% 
        dplyr::as_tibble() 
}

download_from_synapse <- function(syn_id, location = NULL){
    path = synapser::synGet(syn_id, downloadLocation = location)$path
    return(path)
}

upload_file_to_synapse <- function(
    path, synapse_id, 
    annotation_list = NULL, 
    activity_obj = NULL, 
    ret = "entity"){
    
    entity <- synapser::File(
        path = path, 
        parent = synapse_id, 
        annotations = annotation_list)
    entity <- synapser::synStore(entity, activity = activity_obj)
    if(ret == "entity") return(entity)
    if(ret == "syn_id") return(entity$properties$id)
}

# ---------------

synLogin()

tcga_sample_ids <- tcga_sample_id %>% 
    create_df_from_synapse_id() %>% 
    use_series(icgc_sample_id)

pcawg_df <- pcawg_synapse_id %>% 
    create_df_from_synapse_id() %>% 
    filter(donor_wgs_exclusion_white_gray == "Whitelist") %>% 
    filter(library_strategy == "RNA-Seq") %>% 
    filter(!aliquot_id %in% tcga_sample_ids)

# %>% 
#     group_by(icgc_donor_id) %>% 
#     mutate(count = n()) %>% 
#     ungroup()

# pcawg_df2 <- pcawg_df %>% 
#     filter(count != 1) %>% 
#     select(count, icgc_donor_id, dcc_specimen_type) %>% 
#     arrange(desc(count), icgc_donor_id)
# 
# pcawg_df3 <- pcawg_df2 %>% 
#     filter(count == 2) %>% 
#     group_by(icgc_donor_id) %>% 
#     arrange(dcc_specimen_type) %>% 
#     summarise(tumors = str_c(dcc_specimen_type, collapse = ";")) %>% 
#     use_series(tumors) %>% 
#     table

# pcawg_df %>% 
#     filter(count > 1) %>% 
#     use_series(icgc_donor_id) %>% 
#     unique %>% 
#     length

allowed_ids <- pcawg_df %>% 
    use_series(aliquot_id)

hugo_translation_df <-  hugo_translation_id %>% 
    create_df_from_synapse_id() %>% 
    set_colnames(c("ensembl", "hugo")) %>% 
    filter(!hugo == "")

fpkm_df <- fpkm_synapse_id %>% 
    create_df_from_synapse_id(unzip = T) %>% 
    select(one_of(c("feature", allowed_ids))) %>% 
    dplyr::rename(ensembl = feature) %>% 
    dplyr::mutate(ensembl = str_split(ensembl, "\\.")) %>% 
    dplyr::mutate(ensembl = map_chr(ensembl, 1)) %>% 
    dplyr::inner_join(hugo_translation_df, by = "ensembl") %>% 
    dplyr::select(hugo, everything()) %>% 
    dplyr::select(-ensembl) %>% 
    dplyr::group_by(hugo) %>%
    dplyr::summarise_all(sum) %>% 
    dplyr::ungroup() %>% 
    tidyr::drop_na()
    

write_tsv(fpkm_df, "non_tcga_fpkm.tsv")
write_tsv(pcawg_df, "non_tcga_samples.tsv")

activity_obj <- synapser::Activity(
    name = "convert from ensmbl to hugo, and select only non-tcga samples",
    used = list(hugo_translation_id, fpkm_synapse_id, tcga_sample_id),
    executed = "https://github.com/CRI-iAtlas/ICGC/blob/master/format_fpkm_file.R"
)

upload_file_to_synapse("non_tcga_fpkm.tsv", "syn18268611", activity_obj = activity_obj)
upload_file_to_synapse("non_tcga_samples.tsv", "syn18233789", activity_obj = activity_obj)

