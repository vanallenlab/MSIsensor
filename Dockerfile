FROM vanallenlab/miniconda:3.6

WORKDIR /

RUN conda config --add channels conda-forge \
    && conda config --add channels bioconda \
    && conda install msisensor
