FROM krallin/ubuntu-tini:xenial
MAINTAINER Gabriel Vacaliuc "gabe.vacaliuc@gmail.com"

USER root

# Install OS dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade && \
    apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    ENV_USER=spark \
    ENV_UID=1000 \
    ENV_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$ENV_USER

RUN echo "${LANG} UTF-8" > /etc/locale.gen && \
    locale-gen

ADD fix-permissions /usr/local/bin/fix-permissions

# Create spark user with UID=1000 and in the 'users' group and make sure these
# dirs are writable by the `users` group.
RUN useradd -m -s /bin/bash -N -u $ENV_UID $ENV_USER && \
    mkdir -p $CONDA_DIR && \
    chown $ENV_USER:$ENV_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    fix-permissions $HOME && \
    fix-permissions $CONDA_DIR

USER $ENV_UID

# Setup work directory for backward-compatibility
RUN mkdir /home/$ENV_USER/work && \
    fix-permissions $HOME

# Install conda as ENV_USER and check the md5 sum provided on the download site
ENV MINICONDA_VERSION 4.4.10
#   Bug in 4.4.10 with some Docker Containers, see:
#       https://github.com/conda/conda/issues/6811
#   We simply update conda to version 4.4.11 to get around this.  Unfortunately
#   there is no Miniconda release for 4.4.11.
ENV MINICONDA_PKG_VERSION 4.4.11
ENV CONDA_PYTHON_VERSION 2
ENV CONDA_CHECKSUM dd54b344661560b861f86cc5ccff044b 
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda${CONDA_PYTHON_VERSION}-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "${CONDA_CHECKSUM} Miniconda${CONDA_PYTHON_VERSION}-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda${CONDA_PYTHON_VERSION}-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda${CONDA_PYTHON_VERSION}-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    $CONDA_DIR/bin/conda install -n base conda=${MINICONDA_PKG_VERSION} && \
    conda clean -tipsy && \
    rm -rf /home/$ENV_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$ENV_USER

#   Switch back to root to install java and spark
USER root

#   Install Java 8
RUN apt-get -y update && \
    apt-get install --no-install-recommends -y \
        openjdk-8-jre-headless \
        ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Install pyarrow
#RUN conda install --quiet -y 'pyarrow' && \
    #fix-permissions $CONDA_DIR && \
    #fix-permissions /home/$NB_USER

#   Spark Installation
ENV APACHE_SPARK_VERSION 2.2.1
ENV HADOOP_VERSION 2.7
ENV GPG_PUBLIC_KEY 85040118

RUN cd /tmp && \
        wget -q http://apache.claz.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
        wget -q https://archive.apache.org/dist/spark/spark-2.2.1/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz.asc && \
        gpg --keyserver pgpkeys.mit.edu --recv-key ${GPG_PUBLIC_KEY} && \
        gpg --verify \
            spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz.asc \
            spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
        tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local && \
        rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark
RUN fix-permissions $HOME

USER $ENV_UID

RUN conda install --quiet --yes \
    'ipython' \
    'numpy' \
    'pandas' \
    && conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions $HOME

# Spark and Mesos config
ENV SPARK_HOME=/usr/local/spark \
    PYSPARK_PYTHON=$CONDA_DIR/bin/python \
    PYSPARK_DRIVER_PYTHON=$CONDA_DIR/bin/ipython \
    SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info"
ENV PATH=$SPARK_HOME/bin:$PATH

WORKDIR $HOME/work
