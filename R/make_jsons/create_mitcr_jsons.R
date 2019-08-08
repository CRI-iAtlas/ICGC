library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

parameter_list <- list(
    "synapse_config" = list(
        "path" = ".synapseConfig",
        "class" = "File"),
    "destination_id" = "syn18638507"
)

uploaded_samples <- "select name from syn19956391" %>% 
    query_synapse_table() %>%  
    tidyr::separate(name, sep = "_", into = c("sample", "chain"), extra = "drop") %>% 
    dplyr::mutate(exists = "yes") %>% 
    tidyr::spread(key = "chain", value = "exists") %>% 
    tidyr::drop_na() %>% 
    magrittr::use_series(sample)

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
    dplyr::left_join(bam_df) 


paired_df <- fastq_df %>% 
    dplyr::filter(!is.na(p2_fastq_ids))

unpaired_df <- fastq_df %>% 
    dplyr::filter(is.na(p2_fastq_ids)) %>% 
    dplyr::select(-p2_fastq_ids) %>% 
    dplyr::rename(fastq_ids = p1_fastq_ids)

# LIRI-JP

paired_df %>%
    dplyr::filter(Project == "LIRI-JP") %>%
    dplyr::arrange(desc(time)) %>% 
    dplyr::mutate(cum_size = cumsum(bam_size)) %>%
    dplyr::filter(cum_size < 1.0e11) %>%
    dplyr::select(-c(Project, bam_size, cum_size, time)) %>%
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("LIRI.json")

# OV-AU

paired_df %>%
    dplyr::filter(Project == "OV-AU") %>%
    dplyr::arrange(desc(time)) %>% 
    dplyr::mutate(cum_size = cumsum(bam_size)) %>%
    dplyr::filter(cum_size < 1.0e11) %>%
    dplyr::select(-c(Project, bam_size, cum_size, time)) %>%
    as.list() %>%
    c(parameter_list) %>%
    RJSONIO::toJSON() %>%
    writeLines("OV.json")




