library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")



fastq_result_tbl <- "select * from syn18689500" %>% 
    query_synapse_table()

uploaded_bam_names <- fastq_result_tbl %>% 
    dplyr::mutate(bam_name = stringr::str_remove_all(name, "_p[12].fastq.gz")) %>%
    dplyr::mutate(bam_name = stringr::str_c(bam_name, ".bam")) %>% 
    dplyr::pull(bam_name) %>% 
    unique

uploaded_bam_names2 <- "select name from syn20810012" %>% 
    query_synapse_table() %>% 
    dplyr::pull(name) %>% 
    unique



bam_df <- "syn18684516" %>%
    synapse_file_to_tbl() %>% 
    #dplyr::select(`File ID`, Project, `ICGC Donor`, `File Name`, "size" = `Size (bytes)`) %>% 
    dplyr::group_by(`ICGC Donor`) %>%
    dplyr::mutate(donor_count = dplyr::n()) %>% 
    dplyr::ungroup() %>% 
    dplyr::arrange(Project, desc(donor_count), `ICGC Donor`) %>%
    dplyr::filter(!`File Name` %in% uploaded_bam_names) %>% 
    dplyr::filter(!`File Name` %in% uploaded_bam_names2) %>% 
    dplyr::arrange(`File Name`)

EGA_MALY_df <- "syn20935231" %>% 
    synapse_file_to_tbl(col_names = F) %>% 
    dplyr::filter(X1 %in% bam_df$`Sample ID`) %>% 
    dplyr::filter(stringr::str_detect(X3, "STAR.v1.bam.cip$"))

bam_df %>%
    dplyr::arrange(size) %>% 
    magrittr::use_series(`File ID`) %>% 
    unique() %>% 
    stringr::str_c(collapse = ", ")
    


