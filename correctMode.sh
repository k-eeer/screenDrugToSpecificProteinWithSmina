#! /bin/bash
#correct pdb traj from bio3d,which all the residue is Ala.
#you might need to prepare a c-alpha only pdb to proceed this step.
#get right ca structure,ca_3cm5.pdb with bio3d
rm -f ca_3cm5.pdb
R --slave <<EOF
library(bio3d)
pdb <- read.pdb("3cm5")
ca.inds <- atom.select(pdb, "calpha")
capdb <- trim.pdb(pdb, ca.inds)
write.pdb(capdb, file="ca_3cm5.pdb")
EOF
#get m7 head
cut mode_7.pdb -c 1-17>m7head.dat
#get ca middle unit
rm -f ca.dat
echo"">>ca.dat
cut ca_3cm5.pdb  -c 18-31>>ca.dat
#sed -i "296d" ca.dat

total=`wc -l mode_7.pdb|awk '{print $1}'`
repeat=`wc -l ca.dat|awk '{print $1}'`
r_time=$(($total/$repeat))
rm -f camiddle.dat
for (( c=1; c<=$r_time; c++ ))
do 	
	cat ca.dat>>camiddle.dat	
done
rm -f correctMode.pdb m7tail.dat
cut mode_7.pdb -c 33-79>m7tail.dat
paste -d "" m7head.dat camiddle.dat m7tail.dat>correctNma.pdb
rm -f ca_3cm5.pdb
rm -f ca.dat
rm -f camiddle.dat
rm -f m7*
