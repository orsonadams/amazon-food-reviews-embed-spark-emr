#!/usr/bin/env bash
# Mostly taken from here: https://gist.github.com/nicor88/5260654eb26f6118772551861880dd67

set -x -e
# home backup
if [ ! -d /mnt/home_backup ]; then
  sudo mkdir /mnt/home_backup
  sudo cp -a /home/* /mnt/home_backup
fi

# mount home to /mnt
if [ ! -d /mnt/home ]; then
  sudo mv /home/ /mnt/
  sudo ln -s /mnt/home /home
fi

# Install conda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/hadoop/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p $HOME/conda

echo -e '\nexport PATH=$HOME/conda/bin:$PATH' >> $HOME/.bashrc && source $HOME/.bashrc

conda config --set always_yes yes --set changeps1 no
conda install conda=4.7.12

# conda activate

conda config -f --add channels conda-forge
conda config -f --add channels defaults

conda install pip=20.0.2
pip install Cython # you'll need this for pyarrow

conda install -c conda-forge pyarrow
pip install pandas==1.0.1 pyspark==2.4.4 tensorflow==2.2.0 tensorflow-hub==0.8.0

# cleanup
rm ~/miniconda.sh

echo bootstrap_conda.sh completed. PATH now: $PATH
export PYSPARK_PYTHON="/home/hadoop/conda/bin/python3"
