## loading restart variables
PYTHON=3.9
PACKAGES+=make vim gosu
PIP+=pandas confuse ipysheet pyomo h5py restart_datasets airflow
		   # pyyaml xlrd
PIP_ONLY+=tables
# These are for development time
# neovim: neovim and rope for renaming python objects
PIP_DEV+=nptyping pydocstyle pdoc3 flake8 mypy bandit \
  		 black tox pytest pytest-cov pytest-xdist tox yamllint \
		 pre-commit isort seed-isort-config \
		 setuptools wheel twine  \
		 neovim rope
