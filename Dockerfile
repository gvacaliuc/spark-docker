FROM jupyter/minimal-notebook:latest
MAINTAINER Gabriel Vacaliuc "gabe.vacaliuc@gmail.com"

#   Switch back to root to install java and spark
USER root

#   Install Java 8
RUN apt-get -y update && \
    apt-get install --no-install-recommends -y \
        openjdk-8-jre-headless \
        ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $ENV_UID

RUN conda install --yes \
    'numpy' \
    'pandas' \
    'scipy' \
    'scikit-learn' \
    'pyspark' \
    'matplotlib' \
    && conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions $HOME

EXPOSE 8888
WORKDIR $HOME

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]
