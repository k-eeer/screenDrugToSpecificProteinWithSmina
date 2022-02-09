#!/bin/bash

#pubchempy should be install
# $sudo pip install pubchempy

#write script to create database and table
echo "create DATABASE  IF NOT EXISTS screening;
use screening;
DROP TABLE fittest;
create TABLE IF NOT EXISTS fittest (ligand INT,preferProteinInDocking VARCHAR(20), preferProteinInRescore VARCHAR(20),pubchemUrl VARCHAR(1000));">fittest.sql

for i in rest*pdb
do
echo $i
#get pubchem id from smiles format of fittest ligand
smiles=$(obabel -ipdb $i -osmi|awk '{print $1}')
cat >getId.py<<EOF
#!/bin/python
from pubchempy import *
id=get_compounds('$smiles','smiles')
print(id)

EOF

page=$(python getId.py|sed 's/[^0-9]*//g')
#if you want to check molecule page from pubchem
#firefox -new-tab "https://pubchem.ncbi.nlm.nih.gov/compound/$page"

p2=$(echo ${i:3:3})
p1=$(echo ${i:6:3})
lig=$(echo ${i:12:-4})
echo "INSERT INTO fittest(ligand,preferProteinInDocking,preferProteinInRescore,pubchemUrl)
VALUE("$lig",\"$p1\",\"$p2\",\"https://pubchem.ncbi.nlm.nih.gov/compound/$page\");">>fittest.sql


done
echo "exit">>fittest.sql
sudo mysql<fittest.sql
