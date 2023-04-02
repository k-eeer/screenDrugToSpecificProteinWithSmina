fetch 3cm5
remove resn HOH and 3cm5
remove name ZN
remove name MN
load clNmas1.pdb
load clNmas2.pdb
load clNmas3.pdb
pair_fit 3cm5///5-298/CA and chain A, clNmas1///5-298/CA and chain A
pair_fit 3cm5///5-298/CA and chain B, clNmas1///5-298/CA and chain B
save protein1.pdb,3cm5
pair_fit 3cm5///5-298/CA and chain A, clNmas2///5-298/CA and chain A
pair_fit 3cm5///5-298/CA and chain B, clNmas2///5-298/CA and chain B
save protein2.pdb,3cm5
pair_fit 3cm5///5-298/CA and chain A, clNmas3///5-298/CA and chain A
pair_fit 3cm5///5-298/CA and chain B, clNmas3///5-298/CA and chain B
save protein3.pdb,3cm5
load protein1.pdb
load protein2.pdb
load protein3.pdb
