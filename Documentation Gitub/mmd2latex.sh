#!/bin/bash
# script to help in making the document
# set some options
set -o nounset
set -o errexit
# get the current directory
WORK_DIR=`pwd`
MMD_UTILS_DIR=/Library/Application\ Support/MultiMarkdown/Utilities/

# clean up the output directory
rm -f "$WORK_DIR"/output/*
ln -s "$WORK_DIR"/images "$WORK_DIR"/output/images

# merge the source files together
"$MMD_UTILS_DIR"/mmd_merge.pl "$WORK_DIR"/index.txt > "$WORK_DIR"/output/latest.md

# convert to latex
/usr/local/bin/multimarkdown "$WORK_DIR"/output/latest.md -t latex -o "$WORK_DIR"/output/latest.tex

sed -ie 's/\\autoref/\\customref/g' "$WORK_DIR/output/latest.tex"
# Remove footnote with URI
sed -ie 's/\\footnote{\\href{.*}}//g' "$WORK_DIR/output/latest.tex"

# change to the output directory
cd "$WORK_DIR"/output

# run pdflatex
/usr/texbin/xelatex -halt-on-error latest.tex &> stage-01.log

# run pdflatex
/usr/texbin/xelatex -halt-on-error latest.tex &> stage-02.log

# make the bibliography
#/usr/texbin/bibtex latest.aux &> stage-03.log

# run pdflatex
#/usr/texbin/xelatex -halt-on-error latest.tex &> stage-04.log

# run pdflatex
#/usr/texbin/xelatex -halt-on-error latest.tex &> stage-05.log
