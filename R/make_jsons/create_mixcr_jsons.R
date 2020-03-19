library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

parameter_list <- list(
    "synapse_config" = list(
        "path" = ".synapseConfig",
        "class" = "File"),
    "destination_id" = "syn20692730"
)

get_synapse_entity_size <- function(id){
    file <- synapser::synGet(id, downloadFile = F)
    file$get('fileSize')
}

uploaded_samples <- 
    "select name from syn20697851" %>%
    query_synapse_table() %>% 
    dplyr::pull(name) %>% 
    stringr::str_split("\\.") %>% 
    purrr::map_chr(1) %>% 
    unique

bam_df <- "syn18684516" %>%
    synapse_file_to_tbl() %>%  
    dplyr::select(
        "bam_size" = `Size (bytes)`,
        "sample_names" = `Specimen ID`
    ) 

fastq_df <- "SELECT id, pair, Project, ICGC_Specimen_ID, createdOn FROM syn18689500" %>% 
    query_synapse_table() %>%  
    tidyr::drop_na() %>%
    dplyr::group_by(Project, ICGC_Specimen_ID) %>% 
    dplyr::mutate(createdOn = max(createdOn)) %>% 
    dplyr::ungroup() %>% 
    tidyr::spread(key = pair, value = id) %>% 
    magrittr::set_colnames(c("Project", "sample_names", "time", "p1_fastq_ids", "p2_fastq_ids")) %>% 
    dplyr::filter(!sample_names %in% uploaded_samples) %>% 
    dplyr::left_join(bam_df) %>% 
    dplyr::arrange(bam_size) 


paired_df <- fastq_df %>% 
    dplyr::filter(!is.na(p2_fastq_ids)) %>% 
    dplyr::mutate(
        size1 = purrr::map_dbl(p1_fastq_ids, get_synapse_entity_size),
        size2 = purrr::map_dbl(p2_fastq_ids, get_synapse_entity_size)
    )

paired_df %>% 
    dplyr::group_by(Project) %>% 
    dplyr::summarise(
        count = dplyr::n(),
        size = sum(size1) + sum(size2)
    ) %>%
    dplyr::arrange(desc(size))

# unpaired
unpaired_df <- fastq_df %>% 
    dplyr::filter(is.na(p2_fastq_ids)) %>% 
    dplyr::select(-c(p2_fastq_ids, time, bam_size)) %>% 
    dplyr::rename(fastq_ids = p1_fastq_ids) %>% 
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("unpaired.json")


# paired
paired_df %>%
    dplyr::mutate(cum_size = cumsum(size1) + cumsum(size2)) %>%
    dplyr::filter(cum_size < 2.0e11) %>%
    dplyr::select(p1_fastq_ids, p2_fastq_ids, sample_names) %>%
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("mixcr.json")












