#!/usr/bin/env python
"""Arranca el servidor de desarrollo en el puerto 8009."""
import subprocess, sys, os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
subprocess.run([sys.executable, "manage.py", "runserver", "8009"])
