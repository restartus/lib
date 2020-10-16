## loading restart variables note that 3.9 is incompatible to h5py and tables and pandas
PYTHON=3.8
PACKAGES+=make vim gosu
PIP+=pandas confuse ipysheet pyomo h5py airflow
		   # pyyaml xlrd
PIP_ONLY+=tables restart_datasets 
# These are for development time
# neovim: neovim and rope for renaming python objects
PIP_DEV+=nptyping pydocstyle pdoc3 flake8 mypy bandit \
  		 black tox pytest pytest-cov pytest-xdist tox yamllint \
		 pre-commit isort seed-isort-config \
		 setuptools wheel twine  \
		 neovim rope
