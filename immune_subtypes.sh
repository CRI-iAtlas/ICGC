git clone https://github.com/CRI-iAtlas/iatlas-workflows
docker build -t immune_subtype_clustering iatlas-workflows/Immune_Subtype_Clustering/workflow/docker/Clustering/
synapse login
synapse get syn18268621 
cwltool iatlas-workflows/Immune_Subtype_Clustering/workflow/steps/Immune_Subtype_Clustering/Immune_Subtype_Clustering.cwl \
--input_file non_tcga_fpkm.tsv --output_name immune_subtypes.tsv --num_cores 23 --combat_normalize --log_expression \
&> immune_subtypes_log.txt &
synapse store immune_subtypes.tsv --parentId syn18143761
synapse store immune_subtypes_log.txt --parentId syn18143761