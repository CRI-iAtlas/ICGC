library(magrittr)

synapser::synLogin()
devtools::source_url("https://raw.githubusercontent.com/Sage-Bionetworks/synapse_tidy_utils/master/utils.R")

# figure out later
# issue with code not thinking they ahve been done
bad_donor_ids <- c("DO46372", "DO45299", "DO46366", "DO45303", "DO23517", "DO45297",
                   "DO45165", "DO45097", "DO45173", "DO45263", "DO45177")

# issue with EGA download process
bad_donor_ids2 <- c("DO27767", "DO27769", "DO27773", "DO27793", "DO27803", 
                    "DO27815", "DO27847", "DO52652", "DO52658", "DO52666", 
                    "DO52673", "DO52679", "DO52685")

# pga only project
pga_projects <- c("BLCA-US", "BRCA-US", "THCA-US")


fastq_result_tbl <- "select * from syn18689500" %>% 
    query_synapse_table()

uploaded_bam_names <- fastq_result_tbl %>% 
    dplyr::mutate(bam_name = stringr::str_remove_all(name, "_p[12].fastq.gz")) %>%
    dplyr::mutate(bam_name = stringr::str_c(bam_name, ".bam")) %>% 
    dplyr::pull(bam_name) %>% 
    unique


bam_df <- "syn18684516" %>%
    synapse_file_to_tbl() %>% 
    dplyr::select(`File ID`, Project, `ICGC Donor`, `File Name`, "size" = `Size (bytes)`) %>% 
    dplyr::group_by(`ICGC Donor`) %>%
    dplyr::mutate(donor_count = dplyr::n()) %>% 
    dplyr::ungroup() %>% 
    dplyr::arrange(Project, desc(donor_count), `ICGC Donor`) %>%
    dplyr::filter(!`File Name` %in% uploaded_bam_names) 
# %>% 
    #dplyr::filter(!Project %in% pga_projects) %>%  #### resolve!!!!!
    #dplyr::filter(!`ICGC Donor` %in% bad_donor_ids) %>% #### resolve!!!!!
    #dplyr::filter(!`ICGC Donor` %in% bad_donor_ids2)   #### resolve!!!!!!


bam_df %>%
    # dplyr::mutate(cum_size = cumsum(size)) %>%
    # dplyr::filter(cum_size < 2e11) %>%
    magrittr::use_series(`File ID`) %>% 
    unique() %>% 
    stringr::str_c(collapse = ", ") 


