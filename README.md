# spark-docker

Spark 2.2.1 Docker Image. (Since AWS EMR uses 2.2.1).

## what this image gives you

* Spark 2.2.1 (includes `pyspark`)
* Miniconda Installation with Python 2.7 w/
    * `numpy`
    * `ipython`
    * `pandas`
* `ipython` set to be the default `pyspark` interpreter to provide convenient
  auto-completion

## running

To launch the container and run a `bash` shell interactively, simply run
```bash
$ docker run --rm -it gvacaliuc/spark
```

Once you're in, you can run `pyspark` from the terminal which will run
`ipython` and provide a `SparkContext` and `SparkSession`.  You can also launch
`pyspark` directly when you launch the container by running
```bash
$ docker run --rm -it gvacaliuc/spark pyspark
```

### installing packages

The image includes a Miniconda installation that is user-writable, so you 
can simply use `conda` or `pip` to install packages if need be:
```bash
$ conda install tqdm
#   if you prefer
$ pip install tqdm
```

Bear in mind that if you launch the container with `--rm` any packages
you install will need to be reinstalled when the container is restarted.

## building

To build the image, simply pull the image and run
```bash
$ docker build . -t gvacaliuc/spark
```
