git clone https://github.com/CRI-iAtlas/iatlas-tool-cibersort
docker build -t cibersort iatlas-tool-cibersort/

git clone https://github.com/CRI-iAtlas/iatlas-workflows
docker build -t aggregate_cibersort_celltypes iatlas-workflows/Cibersort/workflow/docker/aggregate_cibersort_celltypes/

synapse login
synapse get syn18268621 

cwltool iatlas-workflows/Cibersort/workflow/cibersort_workflow.cwl --expression_file non_tcga_fpkm.tsv &> cibersort_log.txt &
mv output.tsv cibersort.tsv
synapse store immune_subtypes.tsv --parentId syn18343252
synapse store cibersort_log.txt --parentId syn18343252