#!/bin/bash 
#author:k-eeer
#######################################################################################
#description:                                                                          
#This scripts prepares protein and drug molecules(="ligands" in this scripts)' structures,
#Then fitting one pretein and one drug molecules,caculating the affinity to get some drug molecules
#in some states which fit protein molecule best. Those drug molecules can be material to design new
#drug or therapy.                                                                      
#Whole process can be divided into four parts: 1)prepare molecules,2)docking(=fitting),#3)rescoring
#to get more reliable result, and 4)view the result.                                   
#######################################################################################
#Prerequisites:

#1)tools:
#R-package 'Bio3d'
#Gromacs
#Pymol
#MGLTools
#Open Babel
#Smina

#2)files:
#nma.r
#correctMode.sh
#forAlignPml.sh
#bindingSite.r
#fda.mol2

#_____________________________________________________________________
#1)prepare molecules

file="tf*pdbqt"
if [[ ! -f "$file" ]]; then
    
echo "1)prepare molecules:protein (PDB ID:3CM5)"

#file:nma.r;sofrware:R package 'Bio3d'
Rscript nma.r>nma.log 2>&1

#correct the residue name (all is ALA now).;file:correctMode.sh
sh correctMode.sh

#get c-alpha 3CM5 for the following cluster
#(frame1 of correctnma.pdb as reference.)
grep -A 589  "MODEL        1" correctNma.pdb>frame1.pdb
#cluster threshold 0.26nm to get 3 receptor;use Gromacs"
gmx cluster -f correctNma.pdb  -s frame1.pdb  -method gromos -cl clNma.pdb  -cutoff 0.26 -pbc<<EOF
0
0
EOF

#split PDBs to single PDB.
csplit clNma.pdb /TITLE/ -n1 {*} -f clNmas -b %1d.pdb
rm -r clNmas0.pdb

#superposition.;file:forAlignPml.sh;tool:Pymol
sh forAlignPml.sh
pymol -c segmentAlign.pml 1>/dev/null
#gnome-terminal -e "bash -c \"pymol AlignAnimation.pml; exec bash\" "

for i in 1 2 3
do
/mgltools_x86_64Linux2_1.5.6/bin/pythonsh /mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_receptor4.py -r tf$i.pdb  -o tf$i.pdbqt -A hydrogens
done


fi

mkdir -p fda
cp tf*pdbqt fda.mol2 ./fda
cd fda


#setting docking coordinate;file bindingsite.r

Rscript ../bindingSite.r>binding.log
resid=$(sed -n '/\[/ p' binding.log |awk '{print $3}')
resname=$(grep  "\[" binding.log|cut -c 6-9)
grep "CA.*${resname}.*A.*${resid}" tf2.pdbqt >coor.pdb
cx=$(awk '{print $7}' coor.pdb)
cy=$(awk '{print $8}' coor.pdb)
cz=$(awk '{print $9}' coor.pdb)

echo "1)prepare molecules:fda approved drug molecules."
#download from ZINC15.use firefox.http://zinc15.docking.org/substances/subsets/fda.mol2?count=all
#check number of molecules of download mol2 file. 
#file:fda.mol2;tool:open babel, mgltools

countLig=lig*pdbqt
if [[ ! -f $countLig ]]; then

echo -n "total molecules you download is "
grep '^ZINC' fda.mol2|wc -l

babel -imol2 fda.mol2 -opdb lig.pdb -m
fi

count=$(ls out*pdbqt|wc -l)
if (($count<30)); then


#get 10 random ligand for docking.
randLig=$(ls lig*pdb |shuf -n 10)
for l in $randLig
do
/mgltools_x86_64Linux2_1.5.6/bin/pythonsh /mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/prepare_ligand4.py -l ${l}  -o `basename ${l} .pdb`.pdbqt 1>/dev/null
rm -f $l
done

#---------------------------------------------------------------------
#2)docking

echo "2)docking by smina"
rm -f dockingAffinity.txt 
rm -f out*

for r in tf*.pdbqt
do
for l in lig*pdbqt
do
echo "docking ${r} - ${l}"
smina --receptor $r --ligand $l --center_x $cx --center_y $cy --center_z $cz --size_x 20 --size_y 20 --size_z 20 --num_modes 1 --out out`basename ${r} .pdbqt`${l}  1>/dev/null
echo -n out`basename ${r} .pdbqt`${l} "">> dockingAffinity.txt
grep minimizedAffinity out`basename ${r} .pdbqt`${l}|awk '{print $3}'>> dockingAffinity.txt
done
done

#-----------------------------------------------------------------------
#3)recoring to get more reliable result

echo "3)rescoring to get more reliable result"
rm -f sortDocking.txt
sort -o sortDocking.txt -gk2 dockingAffinity.txt
rm -f rescoring.txt
top=$(less sortDocking.txt|tail -n 3|awk '{print $1}')
for r in tf*.pdbqt
do
for s in $top
do
r1=`basename ${r} .pdbqt`
s1=$(echo ${s:3})
s2=${r1}${s1}
sed -i  '/MODEL/d' ${s}
sed -i '/ENDMDL/d' ${s}

echo "rescoring $r ${s} "
smina --receptor $r --ligand ${s} --center_x $cx --center_y $cy --center_z $cz --size_x 20 --size_y 20 --size_z 20 --num_modes 1 --scoring vinardo --score_only --out res${s2}   1>/dev/null

echo -n  res${s2} "">> rescoring.txt
grep  minimizedAffinity res${s2}|sed -n '1p'|awk '{print $3}'>>rescoring.txt

done
done

fi

#----------------------------------------------------------------

#4)view the best 3 results with Pymol

echo "4)view the best 3 results with Pymol"

rm -f sortRescore.txt
sort -o sortRescore.txt -gk2 rescoring.txt

restop=$(cat sortRescore.txt|tail -n3|awk '{print $1}')

rm -f viewResult.pml

cp ../tf*pdb .
for r in 1 2 3
do
echo "load tf$r.pdb">>viewResult.pml
done

for s in $restop
do
sr=$(ls $s|cut -c 4-6)
save=$(echo ${s%\.*})

/mgltools_x86_64Linux2_1.5.6/bin/pythonsh /mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24/pdbqt_to_pdb.py -f $s  -o $save.pdb

echo "load $save.pdb ">>viewResult.pml
done

#label some residues 
echo "label resi 290 and chain A and name CA,\"(%s, %s, %s)\" % (resn, resi, chain)">>viewResult.pml
echo "label resi 80 and chain B and name CA,\"(%s, %s, %s)\" % (resn, resi, chain)">>viewResult.pml
echo "label resi 63 and chain B and name CA,\"(%s, %s, %s)\" % (resn, resi, chain)">>viewResult.pml
gnome-terminal -e "bash -c \"pymol viewResult.pml; exec bash\" "


exit 0
