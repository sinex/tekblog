---
title: Add environment to jupyter notebook
tags: [development, ipython]
---

From within a python environment that you want to add:

```sh
pip install ipykernel
python -m ipykernel install --user --name 'my-env' --display-name 'Python 3.x (My Env)'
```
