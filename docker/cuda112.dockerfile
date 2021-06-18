FROM nvcr.io/nvidia/pytorch:21.03-py3

##############################################################################
# Temporary Installation Directory
##############################################################################
ENV STAGE_DIR=/tmp
RUN mkdir -p ${STAGE_DIR}

##############################################################################
# Installation/Basic Utilities
##############################################################################
RUN  sed -i s@/archive.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list
RUN  sed -i s@/security.ubuntu.com/@/mirrors.tuna.tsinghua.edu.cn/@g /etc/apt/sources.list
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        software-properties-common build-essential autotools-dev \
        nfs-common pdsh \
        cmake g++ gcc \
        curl wget vim tmux emacs less unzip \
        htop iftop iotop ca-certificates openssh-client openssh-server \
        rsync iputils-ping net-tools sudo \
        llvm-9-dev libsndfile-dev \
        libcupti-dev \
        libjpeg-dev \
        libpng-dev \
        screen jq psmisc dnsutils lsof musl-dev systemd

##############################################################################
# Installation Latest Git
##############################################################################
#RUN add-apt-repository ppa:git-core/ppa -y && \
#    apt-get update && \
#    apt-get install -y git && \
#    git --version

##############################################################################
# Mellanox OFED
##############################################################################
ENV MLNX_OFED_VERSION=5.1-2.5.8.0
RUN apt-get install -y libnuma-dev libcap2
RUN cd ${STAGE_DIR} && \
    wget -q -O - http://www.mellanox.com/downloads/ofed/MLNX_OFED-${MLNX_OFED_VERSION}/MLNX_OFED_LINUX-${MLNX_OFED_VERSION}-ubuntu20.04-x86_64.tgz | tar xzf - && \
    cd MLNX_OFED_LINUX-${MLNX_OFED_VERSION}-ubuntu20.04-x86_64 && \
    PATH=/usr/bin:$PATH ./mlnxofedinstall --user-space-only --without-fw-update --umad-dev-rw --all -q && \
    cd ${STAGE_DIR} && \
    rm -rf ${STAGE_DIR}/MLNX_OFED_LINUX-${MLNX_OFED_VERSION}-ubuntu20.04-x86_64*

##############################################################################
# nv_peer_mem
##############################################################################
#ENV NV_PEER_MEM_VERSION=1.1
#ENV NV_PEER_MEM_TAG=1.1-0
#RUN mkdir -p ${STAGE_DIR} && \
#    git clone https://github.com/Mellanox/nv_peer_memory.git --branch ${NV_PEER_MEM_TAG} ${STAGE_DIR}/nv_peer_memory && \
#    cd ${STAGE_DIR}/nv_peer_memory && \
#    ./build_module.sh && \
#    cd ${STAGE_DIR} && \
#    tar xzf ${STAGE_DIR}/nvidia-peer-memory_${NV_PEER_MEM_VERSION}.orig.tar.gz && \
#    cd ${STAGE_DIR}/nvidia-peer-memory-${NV_PEER_MEM_VERSION} && \
#    apt-get update && \
#    apt-get install -y dkms && \
#    dpkg-buildpackage -us -uc && \
#    dpkg -i ${STAGE_DIR}/nvidia-peer-memory_${NV_PEER_MEM_TAG}_all.deb

##############################################################################
# OPENMPI
##############################################################################
#ENV OPENMPI_BASEVERSION=4.0
#ENV OPENMPI_VERSION=${OPENMPI_BASEVERSION}.5
#RUN cd ${STAGE_DIR} && \
#    wget -q -O - https://download.open-mpi.org/release/open-mpi/v${OPENMPI_BASEVERSION}/openmpi-${OPENMPI_VERSION}.tar.gz | tar --no-same-owner -xzf - && \
#    cd openmpi-${OPENMPI_VERSION} && \
#    ./configure --prefix=/usr/local/openmpi-${OPENMPI_VERSION} && \
#    make -j"$(nproc)" install && \
#    ln -s /usr/local/openmpi-${OPENMPI_VERSION} /usr/local/mpi && \
#    # Sanity check:
#    test -f /usr/local/mpi/bin/mpic++ && \
#    cd ${STAGE_DIR} && \
#    rm -r ${STAGE_DIR}/openmpi-${OPENMPI_VERSION}
#ENV PATH=/usr/local/mpi/bin:${PATH} \
#    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/mpi/lib:/usr/local/mpi/lib64:${LD_LIBRARY_PATH}
## Create a wrapper for OpenMPI to allow running as root by default
#RUN mv /usr/local/mpi/bin/mpirun /usr/local/mpi/bin/mpirun.real && \
#    echo '#!/bin/bash' > /usr/local/mpi/bin/mpirun && \
#    echo 'mpirun.real --allow-run-as-root --prefix /usr/local/mpi "$@"' >> /usr/local/mpi/bin/mpirun && \
#    chmod a+x /usr/local/mpi/bin/mpirun

##############################################################################
# Python
##############################################################################
#ARG PYTHON_VERSION=3.8
#RUN curl -o ~/miniconda.sh https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
#     chmod +x ~/miniconda.sh && \
#     ~/miniconda.sh -b -p /opt/conda && \
#     rm ~/miniconda.sh && \
#     /opt/conda/bin/conda install -y python=$PYTHON_VERSION numpy pyyaml scipy ipython mkl mkl-include ninja cython typing && \
#     /opt/conda/bin/conda install -y -c pytorch magma-cuda110 && \
#     /opt/conda/bin/conda clean -ya

ENV PATH /opt/conda/bin:$PATH
RUN echo "export PATH=/opt/conda/bin:\$PATH" >> /root/.bashrc
RUN pip install --upgrade pip setuptools
RUN wget https://tuna.moe/oh-my-tuna/oh-my-tuna.py && python oh-my-tuna.py

##############################################################################
# Some Packages
##############################################################################
RUN pip install psutil \
                yappi \
                cffi \
                ipdb \
                h5py \
                pandas \
                matplotlib \
                py3nvml \
                pyarrow \
                graphviz \
                astor \
                boto3 \
                tqdm \
                sentencepiece \
                msgpack \
                requests \
                pandas \
                sphinx \
                sphinx_rtd_theme \
                sklearn \
                scikit-learn \
                nvidia-ml-py3 \
                mpi4py \
                nltk \
                rouge \
                filelock

##############################################################################
# PyTorch
##############################################################################
#RUN git clone --recursive https://github.com/pytorch/pytorch /opt/pytorch
#ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0+PTX 8.0"
#COPY pytorch /opt/pytorch
#RUN cd /opt/pytorch && git checkout 33cf7fd && \
#    git submodule sync && git submodule update --init --recursive
#ENV NCCL_LIBRARY=/usr/lib/x86_64-linux-gnu
#ENV NCCL_INCLUDE_DIR=/usr/include
#RUN cd /opt/pytorch && TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
#    CMAKE_PREFIX_PATH="$(dirname $(which conda))/../" USE_SYSTEM_NCCL=1 \
#    pip install -v . && rm -rf /opt/pytorch
#COPY vision /opt/vision
#RUN cd /opt/vision && git checkout v0.8.0 && pip install -v .
#RUN conda install pytorch torchvision torchaudio cudatoolkit=11.0 -c pytorch

ENV TENSORBOARDX_VERSION=1.8
RUN pip install tensorboardX==${TENSORBOARDX_VERSION}

##############################################################################
# apex
##############################################################################
#RUN git clone https://github.com/NVIDIA/apex ${STAGE_DIR}/apex
#RUN cd ${STAGE_DIR}/apex && pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./ \
#    && rm -rf ${STAGE_DIR}/apex

##############################################################################
# PyYAML build issue
# https://stackoverflow.com/a/53926898
##############################################################################
RUN rm -rf /usr/lib/python3/dist-packages/yaml && \
    rm -rf /usr/lib/python3/dist-packages/PyYAML-*

##############################################################################
# DeepSpeed
##############################################################################
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0+PTX 8.0"
#RUN git clone https://github.com/microsoft/DeepSpeed.git ${STAGE_DIR}/DeepSpeed
COPY DeepSpeed ${STAGE_DIR}/DeepSpeed
RUN cd ${STAGE_DIR}/DeepSpeed && \
    git checkout . && \
    DS_BUILD_OPS=1 ./install.sh -r
RUN rm -rf ${STAGE_DIR}/DeepSpeed
RUN python -c "import deepspeed; print(deepspeed.__version__)"

## Install Jupyter Notebook
RUN pip install jupyter notebook && python -m ipykernel install --user --name base --display-name "Python3.6"
COPY prepare.sh /root/.jupyter/prepare.sh
RUN chmod +x /root/.jupyter/prepare.sh && mkdir /dataset /logs /model
EXPOSE 8888

##############################################################################
## Add deepspeed user
###############################################################################
# Add a deepspeed user with user id 1001
RUN echo 'root:baai2020keg' | chpasswd
#RUN useradd --create-home --uid 1001 --shell /bin/bash deepspeed
#RUN echo 'deepspeed:baai2020keg' | chpasswd
#RUN usermod -aG sudo deepspeed
#RUN echo "deepspeed ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
## # Change to non-root privilege
#USER deepspeed

##############################################################################
# Client Liveness & Uncomment Port 22 for SSH Daemon
##############################################################################
# Keep SSH client alive froGm server side
RUN echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd && cp /etc/ssh/sshd_config ${STAGE_DIR}/sshd_config && \
    sed "0,/^#Port 22/s//Port 22/" ${STAGE_DIR}/sshd_config > /etc/ssh/sshd_config
##############################################################################
## SSH daemon port inside container cannot conflict with host OS port
###############################################################################
ARG SSH_PORT=22
RUN cat /etc/ssh/sshd_config > ${STAGE_DIR}/sshd_config && \
    sed "0,/^Port 22/s//Port ${SSH_PORT}/" ${STAGE_DIR}/sshd_config > /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
EXPOSE ${SSH_PORT}

# Set SSH KEY
RUN printf "StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
 ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
   chmod og-wx ~/.ssh/authorized_keys
# Set SSH config
COPY ssh-env-config.sh /usr/local/bin/ssh-env-config.sh
RUN chmod +x /usr/local/bin/ssh-env-config.sh
CMD /etc/init.d/ssh start && ssh-env-config.sh /bin/bash