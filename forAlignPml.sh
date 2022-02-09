#!/bin/bash
echo "fetch 3cm5" >segmentAlign.pml
echo "remove resn HOH and 3cm5" >>segmentAlign.pml
echo "remove name ZN" >>segmentAlign.pml
echo "remove name MN">>segmentAlign.pml


for i in $(seq 1 3)
do
echo "load clNmas$i.pdb">>segmentAlign.pml
done





for i in $(seq 1 3)
do
for var in A B
do
echo "pair_fit 3cm5///5-298/CA and chain $var, clnmas$num///5-298/CA and chain $var">>segmentAlign.pml
done
echo "save tf$i.pdb,3cm5">>segmentAlign.pml
done

#generate movie of align result
for num in 1 2 3
do
 
echo "load tf$num.pdb">>segmentAlign.pml
done

#generate movie of align result
echo "delete movie">AlignAnimation.pml
for num in 1 2 3
do 
echo "load tf$num.pdb,movie">>AlignAnimation.pml
done
