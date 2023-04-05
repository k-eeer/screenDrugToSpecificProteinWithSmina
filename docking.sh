#1-a)準備蛋白質分子:
file="protein*pdbqt"
if [[ ! -f "protein$file" ]]; then
	echo "1-a)準備蛋白質分子： (PDB ID:3CM5)"
	Rscript normalModeAnalysis.r>normalModeAnalysis.log 2>&1
	bash correctMode.sh

	#get c-alpha 3CM5 for the following cluster
	#frame1 of correctNma.pdb as reference.
	grep -A 589  "MODEL        1" correctNma.pdb>frame1.pdb
	#cluster threshold 0.26nm to get 3 receptor;use Gromacs"
	#先用完整分子(3cm5)以chimera:match maker對齊clNmas*.pdb後其3cm5 model寫成pdb
echo $'0\n0\n'|gmx cluster -f correctNma.pdb  -s frame1.pdb  -method gromos -cl clNma.pdb  -cutoff 0.26 -pbc

	#split PDBs to single PDB.
	csplit clNma.pdb /TITLE/ -n1 {*} -f clNmas -b %1d.pdb
	rm -r clNmas0.pdb
	#superposition.;file:forAlignPml.sh;tool:Pymol
	#bash forAlignPml.sh
	#pymol -c segmentAlign.pml 1>/dev/null
	#cluster之後
	#cluster後chainID遺失，目前
	#先用完整分子以chimera:match maker對齊clNmas*.pdb後寫成protein*.pdb
	
	for i in {1..3};do
		#mv cluster$i.pdb protein$i.pdb
		prepare_receptor4.py -r protein$i.pdb  -o protein$i.pdbqt -A hydrogens
	done
fi

mkdir -p workingSpace
cp protein*pdbqt fda.mol2 ./workingSpace
cd workingSpace

#setting docking coordinate;file bindingsite.r
Rscript ../bindingSite.r>binding.log
resid=$(sed -n '/\[/ p' binding.log |awk '{print $3}')
resname=$(grep  "\[" binding.log|cut -c 6-9)
grep "CA.*${resname}.*A.*${resid}" protein2.pdbqt >coor.pdb
cx=$(awk '{print $7}' coor.pdb)
cy=$(awk '{print $8}' coor.pdb)
cz=$(awk '{print $9}' coor.pdb)

#1-b)準備藥物分子：
echo "1-b)準備藥物分子(fda approved drug molecules.)"
#download from ZINC15.use firefox.http://zinc15.docking.org/substances/subsets/fda.mol2?count=all
#check number of molecules of download mol2 file. 
countDrug=drug*pdbqt
if [[ ! -f $countDrug ]]; then
	drugMol2=$(grep '^ZINC' fda.mol2|wc -l)
	echo -n total molecules you download is  $drugMol2
	obabel -imol2 fda.mol2 -opdb -Odrug.pdb -m
fi



#get  random prepared drug for docking.
read -p 請輸入想要準備的藥物分子數量(1-$drugMol2) drugPrepareNum
randDrug=$(ls drug*pdb |shuf -n $drugPrepareNum)
for l in $randDrug;do
	prepare_ligand4.py -l ${l}  -o `basename ${l} .pdb`.pdbqt 1>/dev/null
	rm -f $l
done
#---------------------------------------------------------------------
#2)蛋白質分子藥物分子對接
echo "2)蛋白質分子藥物分子對接"
rm -f dockingAffinity.txt 
rm -f out*
for r in protein*.pdbqt;do
	preparedDrugNow=$(ls drug*pdbqt|wc -l)
	echo -p 這次希望每個蛋白結構分別嘗試對接幾個藥物分子？(1-$preparedDrugNow) dockingDrugNumThisTime
	for l in $(shuf -e -n1 $dockingDrugNumThisTime);do
		echo "${r} - ${l}對接"
		smina --receptor $r --ligand $l --center_x $cx --center_y $cy --center_z $cz --size_x 20 --size_y 20 --size_z 20 --num_modes 1 --out out`basename ${r} .pdbqt`${l}  1>/dev/null
		echo -n out`basename ${r} .pdbqt`${l} "">> dockingAffinity.txt
		grep minimizedAffinity out`basename ${r} .pdbqt`${l}|awk '{print $3}'>> dockingAffinity.txt
	done
done

#-----------------------------------------------------------------------
#3)重新評估結果

echo "3)重新評估以得更可靠結果："
rm -f sortDocking.txt
sort -o sortDocking.txt -gk2 dockingAffinity.txt
rm -f rescoring.txt
top=$(less sortDocking.txt|tail -n 3|awk '{print $1}')
for r in protein*.pdbqt;do
	for s in $top;do
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

#----------------------------------------------------------------
#4)視覺化檢視3個最佳結果
echo "4)視覺化檢視3個最佳結果："
rm -f sortRescore.txt
sort -o sortRescore.txt -gk2 rescoring.txt
restop=$(cat sortRescore.txt|tail -n3|awk '{print $1}')
rm -f viewResult.pml
#cp ../protein*pdb .
for r in {1..3};do
	echo "load protein$r.pdbqt">>viewResult.pml
done
for s in $restop;do
	echo "load $s" >>viewResult.pml
done

#label some residues 
echo "label resi 290 and chain A and name CA,\"(%s, %s, %s)\" % (resn, resi, chain)">>viewResult.pml
echo "label resi 80 and chain B and name CA,\"(%s, %s, %s)\" % (resn, resi, chain)">>viewResult.pml
echo "label resi 63 and chain B and name CA,\"(%s, %s, %s)\" % (resn, resi, chain)">>viewResult.pml
gnome-terminal -- bash -c "pymol viewResult.pml; exec bash" 


exit 0
