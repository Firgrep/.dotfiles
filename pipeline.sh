#!/bin/bash

SESSION="main"
WINDOW="pipeline"

PATH1="~/dev/work/data_pipeline"
PATH2="~/dev/work/data_pipeline"
PATH3=$PATH2
PATH4=$PATH2

export SESSION WINDOW PATH1 PATH2 PATH3 PATH4

source ~/.dotfiles/internal/four_split.sh

four_split