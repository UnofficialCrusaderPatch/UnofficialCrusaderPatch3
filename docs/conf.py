# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'modding-framework-docs'
copyright = '2024, gynt'
author = 'gynt'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

templates_path = ['_templates']
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']


extensions = [
    'sphinxcontrib.luadomain',
    'sphinx_lua',
    'sphinx.ext.autodoc'
    ]

# Available options and default values
lua_source_path = ["./"]
lua_source_encoding = 'utf8'
lua_source_comment_prefix = '---'
lua_source_use_emmy_lua_syntax = True
lua_source_private_prefix = '_'