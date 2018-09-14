# MSIsensor
This repository contains a Dockerfile for the FireCloud implementation of [MSIsensor](https://github.com/ding-lab/msisensor). MSIsensor is run on either tumor-normal pairs or tumor-only samples to determine the percentage of microsatellite sites with a somatic insertion or deletion, which is then used to infer microsatellite stability status. 

The original text uses a threshold of 3.5% for paired cases and their Github recommends 11% for cases without a corresponding normal. Bielski et al. 2018 uses a threshold of 10%, which had a validation rate of 99.4% compared with conventional immunohistochemistry in a cohort of 180 tumors. The latter threshold of 10% is the default value used in the FireCloud method.

Precomputed msi scans for [hg19 and hg38 were precomputed and made publicly available on Google Cloud](https://console.cloud.google.com/storage/browser/msi_sensor). 

DOI: [10.1093/bioinformatics/btt755](https://www.ncbi.nlm.nih.gov/pubmed/24371154)  
Citation: [MSIsensor: microsatellite instability detection using paired tumor-normal sequence data](https://www.ncbi.nlm.nih.gov/pubmed/24371154)  

Docker image: [https://hub.docker.com/r/vanallenlab/msisensor/](https://hub.docker.com/r/vanallenlab/msisensor/)  
FireCloud method: [breardon/msisensor](https://portal.firecloud.org/#methods/breardon/msisensor/)
